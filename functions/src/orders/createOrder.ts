/**
 * Callable Function：建立訂單（T-13）
 *
 * 觸發方式：Flutter/Web 客戶端透過 Firebase Callable SDK 呼叫
 *
 * 業務邏輯：
 *   1. 驗證使用者已登入
 *   2. 用 Zod 驗證輸入格式
 *   3. 在 Firestore Transaction 中原子執行：
 *      a. 讀取每個 products/{productId}/variants/{variantId} 確認庫存
 *      b. 庫存不足且非預購商品 → 拋出 invalid-argument
 *      c. 計算每項小計，合計 subtotal
 *      d. 扣減庫存（預購商品允許庫存為負數）
 *      e. 建立 orders/{orderId} 文件（status: 'pending'）
 *      f. 清空 carts/{userId} 的 items 陣列
 *   4. 回傳 { orderId: string }
 *
 * 安全設計：
 *   - userId 從已驗證的 request.auth.uid 取得，不信任客戶端傳入
 *   - 金額（price、subtotal、total）全部由後端從 Firestore 讀取，不接受客戶端傳入
 *   - Transaction 確保庫存扣減與訂單建立的原子性，防止超賣
 *   - items 儲存下單當下的快照（productName、variantName、price），避免商品改價影響歷史訂單
 *
 * 失敗模式：
 *   - 未登入 → unauthenticated
 *   - 輸入格式錯誤 → invalid-argument
 *   - 商品/變體不存在 → not-found
 *   - 庫存不足（非預購） → invalid-argument（含商品名稱與不足庫存量）
 *   - Transaction 衝突（並發下單） → Cloud Functions 自動重試，最終失敗回傳 internal
 *   - 系統錯誤 → internal
 *
 * 冪等性說明：
 *   - 此 function 不支援傳統冪等性鍵（每次呼叫都會建立新訂單）
 *   - 客戶端應在收到成功回應前避免重複呼叫（UI 層防重複點擊）
 *   - Transaction 本身確保資料一致性，重試不會造成資料錯誤（Transaction 失敗不會留下部分寫入）
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { z } from "zod";
import { FieldValue } from "firebase-admin/firestore";
import type { OrderItem } from "../types";

// ─── 運費常數（T-13 階段固定運費，T-16 金流整合後可能改為動態計算）────────
const SHIPPING_FEE = 0; // TWD，目前為免運費

// ─── Zod 輸入驗證 Schema ─────────────────────────────────────────────────────

const orderItemInputSchema = z.object({
  productId: z.string().min(1, "productId 不可為空"),
  variantId: z.string().min(1, "variantId 不可為空"),
  // quantity 必須為正整數，最多 999 件（防止異常大量下單）
  quantity: z
    .number()
    .int("quantity 必須為整數")
    .min(1, "quantity 最少為 1")
    .max(999, "quantity 最多為 999"),
});

const shippingAddressSchema = z.object({
  name: z.string().min(1, "收件人姓名不可為空").max(50, "收件人姓名過長"),
  phone: z
    .string()
    .min(1, "電話不可為空")
    .max(20, "電話號碼過長"),
  address: z.string().min(1, "地址不可為空").max(200, "地址過長"),
  city: z.string().min(1, "縣市不可為空").max(20, "縣市名稱過長"),
  postalCode: z
    .string()
    .min(3, "郵遞區號格式錯誤")
    .max(10, "郵遞區號過長"),
});

const createOrderInputSchema = z.object({
  items: z
    .array(orderItemInputSchema)
    .min(1, "訂單至少需要一項商品")
    .max(50, "訂單商品數量上限為 50 項"), // 對應 Order 型別的設計原則
  shippingAddress: shippingAddressSchema,
  note: z.string().max(500, "備註不可超過 500 字").optional(),
});

type CreateOrderInput = z.infer<typeof createOrderInputSchema>;

// ─── 回應型別 ────────────────────────────────────────────────────────────────

interface CreateOrderResponse {
  orderId: string;
}

// ─── Cloud Function ──────────────────────────────────────────────────────────

export const createOrder = onCall(
  {
    region: "asia-east1",
    // 訂單建立涉及多次 Firestore 讀寫與 Transaction，設定較寬裕的 timeout
    timeoutSeconds: 60,
  },
  async (request): Promise<CreateOrderResponse> => {
    // ── 1. 認證檢查：必須已登入 ─────────────────────────────────────────────
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "請先登入後再建立訂單");
    }

    const userId = request.auth.uid;

    // ── 2. 輸入格式驗證（Zod）──────────────────────────────────────────────
    const parseResult = createOrderInputSchema.safeParse(request.data);
    if (!parseResult.success) {
      const firstError = parseResult.error.issues[0];
      logger.warn("createOrder：輸入驗證失敗", {
        severity: "WARNING",
        userId,
        issues: parseResult.error.issues,
      });
      throw new HttpsError(
        "invalid-argument",
        `輸入格式錯誤：${firstError?.message ?? "請確認所有欄位格式正確"}`
      );
    }

    const input: CreateOrderInput = parseResult.data;

    // ── 3. Firestore Transaction ────────────────────────────────────────────
    const db = admin.firestore();
    let orderId: string;

    try {
      // 預先產生 orderId（在 Transaction 外產生，確保 Transaction 內外一致）
      orderId = db.collection("orders").doc().id;

      await db.runTransaction(async (transaction) => {
        // ── 3a. 讀取所有商品變體文件（Transaction 內所有讀取必須在寫入前完成）
        const variantRefs = input.items.map((item) =>
          db
            .collection("products")
            .doc(item.productId)
            .collection("variants")
            .doc(item.variantId)
        );

        const productRefs = input.items.map((item) =>
          db.collection("products").doc(item.productId)
        );

        // 批次讀取（一次 Transaction 讀取所有文件，減少往返次數）
        const [variantSnapshots, productSnapshots] = await Promise.all([
          Promise.all(variantRefs.map((ref) => transaction.get(ref))),
          Promise.all(productRefs.map((ref) => transaction.get(ref))),
        ]);

        // ── 3b. 驗證庫存並計算金額 ──────────────────────────────────────────
        const orderItems: OrderItem[] = [];
        let subtotal = 0;

        for (let i = 0; i < input.items.length; i++) {
          const inputItem = input.items[i];
          const variantSnap = variantSnapshots[i];
          const productSnap = productSnapshots[i];

          // 驗證商品文件存在
          if (!productSnap.exists) {
            throw new HttpsError(
              "not-found",
              `商品不存在：productId=${inputItem.productId}`
            );
          }

          // 驗證變體文件存在
          if (!variantSnap.exists) {
            throw new HttpsError(
              "not-found",
              `商品規格不存在：productId=${inputItem.productId}, variantId=${inputItem.variantId}`
            );
          }

          const productData = productSnap.data()!;
          const variantData = variantSnap.data()!;

          const currentStock = variantData.stock as number;
          const isPreorder = variantData.isPreorder as boolean;
          const { quantity } = inputItem;

          // ── 3b. 庫存不足且非預購商品 → 拋出錯誤 ──────────────────────────
          // 預購商品允許庫存為負數（代表超賣但已接受訂單）
          if (!isPreorder && currentStock < quantity) {
            logger.warn("createOrder：庫存不足", {
              severity: "WARNING",
              userId,
              productId: inputItem.productId,
              variantId: inputItem.variantId,
              currentStock,
              requestedQuantity: quantity,
            });
            throw new HttpsError(
              "invalid-argument",
              `商品「${productData.name as string}」庫存不足，剩餘 ${currentStock} 件，無法購買 ${quantity} 件`
            );
          }

          // ── 3c. 計算每項小計 ────────────────────────────────────────────
          // price 從 Firestore 讀取，不信任客戶端傳入
          const price = variantData.price as number;
          const itemSubtotal = price * quantity;
          subtotal += itemSubtotal;

          // 建立訂單明細項目（快照下單當下資訊）
          const orderItem: OrderItem = {
            productId: inputItem.productId,
            variantId: inputItem.variantId,
            productName: productData.name as string, // 商品名稱快照
            variantName: variantData.name as string, // 變體名稱快照
            price, // 單價快照
            quantity,
            isPreorder,
            // 僅在預購商品且有預計出貨日時才儲存
            ...(isPreorder && variantData.estimatedShipDate
              ? { estimatedShipDate: variantData.estimatedShipDate as admin.firestore.Timestamp }
              : {}),
          };

          orderItems.push(orderItem);
        }

        const total = subtotal + SHIPPING_FEE;
        const now = admin.firestore.Timestamp.now();

        // ── 3d. 扣減庫存 ────────────────────────────────────────────────────
        // 使用 FieldValue.increment 保持原子性
        // 預購商品庫存可為負數，一般商品已確認 stock >= quantity
        for (let i = 0; i < input.items.length; i++) {
          transaction.update(variantRefs[i], {
            stock: FieldValue.increment(-input.items[i].quantity),
            updatedAt: now,
          });
        }

        // ── 3e. 建立 orders/{orderId} 文件 ──────────────────────────────────
        const orderRef = db.collection("orders").doc(orderId);
        transaction.set(orderRef, {
          id: orderId,
          userId,
          items: orderItems,
          subtotal,
          shippingFee: SHIPPING_FEE,
          total,
          status: "pending",
          shippingAddress: input.shippingAddress,
          ...(input.note ? { note: input.note } : {}),
          createdAt: now,
          updatedAt: now,
        });

        // ── 3f. 清空 carts/{userId} 的 items 陣列 ───────────────────────────
        // 使用 set with merge=false 只更新 items 欄位，保留其他購物車欄位
        const cartRef = db.collection("carts").doc(userId);
        transaction.set(
          cartRef,
          {
            items: [],
            updatedAt: now,
          },
          { merge: true }
        );
      });
    } catch (err) {
      // 重新拋出已知的 HttpsError（not-found、invalid-argument 等）
      if (err instanceof HttpsError) throw err;

      logger.error("createOrder：Transaction 執行失敗", {
        severity: "ERROR",
        userId,
        error: (err as Error).message,
        stack: (err as Error).stack,
      });
      throw new HttpsError(
        "internal",
        "訂單建立失敗，請稍後再試。若已扣款請聯絡客服。"
      );
    }

    // ── 4. 成功回傳 orderId ──────────────────────────────────────────────────
    logger.info("createOrder：訂單建立成功", {
      severity: "INFO",
      userId,
      orderId,
    });

    return { orderId };
  }
);
