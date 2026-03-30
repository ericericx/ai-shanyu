/**
 * Callable Function：查詢商品瀏覽統計（T-19 行為追蹤後端）
 *
 * 觸發方式：管理後台透過 Firebase Callable SDK 呼叫
 *
 * 業務邏輯：
 *   1. 驗證呼叫者已登入且擁有 admin custom claim
 *   2. 依照輸入條件查詢 productViews collection：
 *      - 可選：按 productId 篩選
 *      - 可選：按 viewedAt 日期範圍篩選（ISO 字串轉 Timestamp）
 *      - 支援 cursor 分頁（lastDocId）
 *   3. 回傳記錄列表與下一頁 cursor
 *
 * 安全設計：
 *   - 雙重驗證：request.auth != null + admin custom claim
 *   - 所有查詢條件皆在後端套用，不信任客戶端可取得任意資料
 *   - startDate/endDate 轉換失敗時明確回傳 invalid-argument
 *
 * 成本考量：
 *   - 使用 cursor 分頁，每次最多讀取 limit + 1 筆（用於判斷是否有下一頁）
 *   - limit 預設 20，最大 100，避免單次讀取過多文件
 *
 * 失敗模式：
 *   - 未登入 → unauthenticated
 *   - 非 admin → permission-denied
 *   - 日期格式錯誤 → invalid-argument
 *   - Firestore 查詢失敗 → internal
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { z } from "zod";

// ─── 輸入驗證 Schema ─────────────────────────────────────────────────────────

const getProductViewStatsInputSchema = z.object({
  productId: z.string().min(1).optional(),
  // ISO 8601 格式，例如 "2024-01-01T00:00:00.000Z"
  startDate: z.string().datetime({ offset: true }).optional(),
  endDate: z.string().datetime({ offset: true }).optional(),
  // limit 預設 20，最大 100（避免讀取過多文件）
  limit: z.number().int().min(1).max(100).optional().default(20),
  // cursor 分頁：上一頁回傳的最後一筆文件 ID
  lastDocId: z.string().min(1).optional(),
});

type GetProductViewStatsInput = z.infer<typeof getProductViewStatsInputSchema>;

// ─── 回應型別 ────────────────────────────────────────────────────────────────

interface ProductViewRecord {
  id: string;
  productId: string;
  userId: string | null;   // 未登入使用者為 null
  sessionId: string;
  viewedAt: string;        // ISO 字串（序列化給客戶端）
  durationSeconds?: number;
  referrer?: string;
}

interface GetProductViewStatsResponse {
  records: ProductViewRecord[];
  total: number;           // 本次查詢結果筆數（不含分頁）
  hasMore: boolean;        // 是否還有下一頁
  nextCursorId: string | null; // 下一頁 cursor
}

// ─── Cloud Function ──────────────────────────────────────────────────────────

export const getProductViewStats = onCall(
  {
    region: "asia-east1",
    timeoutSeconds: 30,
  },
  async (request): Promise<GetProductViewStatsResponse> => {
    // ── 1. 認證檢查：呼叫者必須已登入 ────────────────────────────────────────
    if (!request.auth) {
      logger.warn("getProductViewStats：未登入的呼叫嘗試", {
        severity: "WARNING",
      });
      throw new HttpsError("unauthenticated", "請先登入");
    }

    // ── 2. 權限檢查：呼叫者必須擁有 admin custom claim ───────────────────────
    if (request.auth.token.admin !== true) {
      logger.warn("getProductViewStats：非 admin 使用者嘗試存取", {
        severity: "WARNING",
        callerUid: request.auth.uid,
      });
      throw new HttpsError("permission-denied", "僅限 admin 存取此功能");
    }

    // ── 3. 輸入驗證 ──────────────────────────────────────────────────────────
    const parseResult = getProductViewStatsInputSchema.safeParse(request.data);
    if (!parseResult.success) {
      const firstError = parseResult.error.issues[0];
      logger.warn("getProductViewStats：輸入驗證失敗", {
        severity: "WARNING",
        callerUid: request.auth.uid,
        issues: parseResult.error.issues,
      });
      throw new HttpsError(
        "invalid-argument",
        `輸入格式錯誤：${firstError?.message ?? "請確認所有欄位格式正確"}`
      );
    }

    const input: GetProductViewStatsInput = parseResult.data;
    const db = admin.firestore();

    try {
      // ── 4. 建構查詢 ─────────────────────────────────────────────────────────
      let query: admin.firestore.Query = db.collection("productViews");

      // 4a. 按 productId 篩選
      if (input.productId) {
        query = query.where("productId", "==", input.productId);
      }

      // 4b. 按 viewedAt 日期範圍篩選
      if (input.startDate) {
        const startTimestamp = admin.firestore.Timestamp.fromDate(
          new Date(input.startDate)
        );
        query = query.where("viewedAt", ">=", startTimestamp);
      }

      if (input.endDate) {
        const endTimestamp = admin.firestore.Timestamp.fromDate(
          new Date(input.endDate)
        );
        query = query.where("viewedAt", "<=", endTimestamp);
      }

      // 按 viewedAt 降序排列（最新的先回傳）
      query = query.orderBy("viewedAt", "desc");

      // 4c. cursor 分頁：從 lastDocId 指定的文件後開始
      if (input.lastDocId) {
        const lastDocSnap = await db
          .collection("productViews")
          .doc(input.lastDocId)
          .get();

        // 若 cursor 文件不存在，視為無效 cursor，直接忽略（從頭開始）
        if (lastDocSnap.exists) {
          query = query.startAfter(lastDocSnap);
        } else {
          logger.warn("getProductViewStats：cursor 文件不存在，從頭查詢", {
            severity: "WARNING",
            callerUid: request.auth.uid,
            lastDocId: input.lastDocId,
          });
        }
      }

      // 多取一筆用於判斷是否還有下一頁（limit + 1 技巧）
      const fetchLimit = input.limit + 1;
      query = query.limit(fetchLimit);

      // ── 5. 執行查詢 ─────────────────────────────────────────────────────────
      const snapshot = await query.get();

      // 判斷是否有下一頁
      const hasMore = snapshot.docs.length === fetchLimit;
      // 實際回傳的文件（不含探測用的第 N+1 筆）
      const docs = hasMore ? snapshot.docs.slice(0, input.limit) : snapshot.docs;

      // ── 6. 序列化結果 ───────────────────────────────────────────────────────
      const records: ProductViewRecord[] = docs.map((doc) => {
        const data = doc.data();
        const viewedAt = data.viewedAt as admin.firestore.Timestamp;

        return {
          id: doc.id,
          productId: data.productId as string,
          userId: (data.userId as string | null) ?? null,
          sessionId: data.sessionId as string,
          viewedAt: viewedAt.toDate().toISOString(),
          ...(data.durationSeconds !== undefined
            ? { durationSeconds: data.durationSeconds as number }
            : {}),
          ...(data.referrer !== undefined
            ? { referrer: data.referrer as string }
            : {}),
        };
      });

      const nextCursorId = hasMore && docs.length > 0
        ? (docs[docs.length - 1]?.id ?? null)
        : null;

      logger.info("getProductViewStats：查詢成功", {
        severity: "INFO",
        callerUid: request.auth.uid,
        productId: input.productId ?? "all",
        resultCount: records.length,
        hasMore,
      });

      return {
        records,
        total: records.length,
        hasMore,
        nextCursorId,
      };
    } catch (err) {
      // 重新拋出已知的 HttpsError
      if (err instanceof HttpsError) throw err;

      logger.error("getProductViewStats：Firestore 查詢失敗", {
        severity: "ERROR",
        callerUid: request.auth.uid,
        error: (err as Error).message,
        stack: (err as Error).stack,
      });
      throw new HttpsError("internal", "查詢瀏覽統計失敗，請稍後再試");
    }
  }
);
