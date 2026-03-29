/**
 * Callable Function：取得訂單歷史（T-13）
 *
 * 觸發方式：Flutter/Web 客戶端透過 Firebase Callable SDK 呼叫
 *
 * 查詢邏輯：
 *   - 查詢 orders 集合中 userId == request.auth.uid 的文件
 *   - 按 createdAt DESC 排序（最新訂單在前）
 *   - 支援 cursor-based 分頁（startAfter 參數）
 *   - limit 預設 10，最大 50
 *
 * 安全設計：
 *   - userId 從已驗證的 request.auth.uid 取得，不接受客戶端傳入
 *   - 使用者只能查詢自己的訂單（userId 強制等於 auth.uid）
 *   - 此設計對應 Firestore 安全規則中 orders 的 isOwner 限制
 *
 * 分頁設計：
 *   - 使用 cursor-based（lastOrderId）分頁，優於 offset-based（offset 在大資料集性能差）
 *   - 客戶端保存最後一筆 orderId，下次呼叫時傳入取得下一頁
 *   - 回傳 hasMore 旗標，讓客戶端知道是否還有更多資料
 *
 * 失敗模式：
 *   - 未登入 → unauthenticated
 *   - 輸入格式錯誤 → invalid-argument
 *   - 系統錯誤 → internal
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { z } from "zod";
import type { Order } from "../types";

// ─── Zod 輸入驗證 Schema ─────────────────────────────────────────────────────

const getOrderHistoryInputSchema = z.object({
  // limit：每頁筆數，預設 10，最大 50
  limit: z
    .number()
    .int("limit 必須為整數")
    .min(1, "limit 最少為 1")
    .max(50, "limit 最多為 50")
    .optional()
    .default(10),
  // lastOrderId：上一頁最後一筆訂單的 ID，用於 cursor-based 分頁
  // 不傳入時取第一頁
  lastOrderId: z.string().min(1).optional(),
});

type GetOrderHistoryInput = z.infer<typeof getOrderHistoryInputSchema>;

// ─── 回應型別 ────────────────────────────────────────────────────────────────

interface GetOrderHistoryResponse {
  orders: Order[];
  hasMore: boolean; // true 表示還有下一頁
}

// ─── Cloud Function ──────────────────────────────────────────────────────────

export const getOrderHistory = onCall(
  { region: "asia-east1" },
  async (request): Promise<GetOrderHistoryResponse> => {
    // ── 1. 認證檢查：必須已登入 ─────────────────────────────────────────────
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "請先登入後再查詢訂單");
    }

    const userId = request.auth.uid;

    // ── 2. 輸入格式驗證（Zod）──────────────────────────────────────────────
    const parseResult = getOrderHistoryInputSchema.safeParse(request.data ?? {});
    if (!parseResult.success) {
      const firstError = parseResult.error.issues[0];
      logger.warn("getOrderHistory：輸入驗證失敗", {
        severity: "WARNING",
        userId,
        issues: parseResult.error.issues,
      });
      throw new HttpsError(
        "invalid-argument",
        `輸入格式錯誤：${firstError?.message ?? "請確認所有欄位格式正確"}`
      );
    }

    const input: GetOrderHistoryInput = parseResult.data;

    // ── 3. 查詢 Firestore ────────────────────────────────────────────────────
    const db = admin.firestore();

    try {
      // 基礎查詢：userId 過濾 + createdAt DESC 排序
      // 對應 firestore.indexes.json 中的 orders 複合索引：userId ASC + createdAt DESC
      let query = db
        .collection("orders")
        .where("userId", "==", userId)
        .orderBy("createdAt", "desc")
        .limit(input.limit + 1); // 多取一筆，用來判斷 hasMore

      // ── 3a. cursor-based 分頁：若有 lastOrderId，從該文件後開始取 ──────────
      if (input.lastOrderId) {
        const lastOrderSnap = await db
          .collection("orders")
          .doc(input.lastOrderId)
          .get();

        if (!lastOrderSnap.exists) {
          // lastOrderId 不存在時，視為從頭取（容錯：可能是訂單被刪除的極端情況）
          logger.warn("getOrderHistory：lastOrderId 不存在，從頭取", {
            severity: "WARNING",
            userId,
            lastOrderId: input.lastOrderId,
          });
        } else {
          // 安全性確認：cursor 文件必須屬於當前使用者（防止使用他人 orderId 作為 cursor）
          const lastOrderData = lastOrderSnap.data()!;
          if (lastOrderData.userId !== userId) {
            logger.error("getOrderHistory：cursor 文件 userId 不符", {
              severity: "ERROR",
              userId,
              lastOrderId: input.lastOrderId,
              cursorUserId: lastOrderData.userId,
            });
            throw new HttpsError(
              "permission-denied",
              "無權限存取此頁游標"
            );
          }

          query = query.startAfter(lastOrderSnap);
        }
      }

      const snapshot = await query.get();
      const docs = snapshot.docs;

      // ── 3b. 判斷是否還有下一頁 ──────────────────────────────────────────
      // 若取回的文件數 > limit，表示還有下一頁（移除多取的那一筆）
      const hasMore = docs.length > input.limit;
      const resultDocs = hasMore ? docs.slice(0, input.limit) : docs;

      // ── 3c. 組合回應 ─────────────────────────────────────────────────────
      const orders: Order[] = resultDocs.map(
        (doc) => doc.data() as Order
      );

      return {
        orders,
        hasMore,
      };
    } catch (err) {
      if (err instanceof HttpsError) throw err;

      logger.error("getOrderHistory：查詢失敗", {
        severity: "ERROR",
        userId,
        error: (err as Error).message,
      });
      throw new HttpsError("internal", "訂單查詢失敗，請稍後再試");
    }
  }
);
