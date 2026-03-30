/**
 * Callable Function：查詢熱門商品排行（T-19 行為追蹤後端）
 *
 * 觸發方式：管理後台透過 Firebase Callable SDK 呼叫
 *
 * 業務邏輯：
 *   1. 驗證呼叫者已登入且擁有 admin custom claim
 *   2. 使用 Collection Group query 查詢 productViews collection
 *   3. 在記憶體中按 productId 聚合計數（Firestore 不支援 GROUP BY 原生聚合）
 *   4. 依瀏覽次數降序排序，回傳前 N 名
 *
 * 安全設計：
 *   - 雙重驗證：request.auth != null + admin custom claim
 *
 * 成本考量（重要）：
 *   - 此函式讀取所有符合條件的 productViews 文件後在記憶體聚合
 *   - 當 productViews 資料量極大時，成本與延遲均會顯著增加
 *   - 建議：若 productViews 總量超過 10 萬筆，應改為 counter 預聚合方案
 *     （每次寫入 productViews 時同步更新 productStats/{productId}.viewCount）
 *   - 可使用 startDate/endDate 縮小查詢範圍，降低讀取成本
 *
 * 記憶體聚合設計說明：
 *   Firestore 不支援 SQL GROUP BY 語義的聚合，
 *   因此必須在 Cloud Function 記憶體中讀取所有文件後計數排序。
 *   這是小規模資料的合理做法，但大規模時需預聚合。
 *
 * 失敗模式：
 *   - 未登入 → unauthenticated
 *   - 非 admin → permission-denied
 *   - 輸入格式錯誤 → invalid-argument
 *   - Firestore 查詢失敗 → internal
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { z } from "zod";

// ─── 輸入驗證 Schema ─────────────────────────────────────────────────────────

const getTopProductsInputSchema = z.object({
  // 回傳前 N 名，預設 5，最大 50
  limit: z.number().int().min(1).max(50).optional().default(5),
  // 可選：只聚合指定時間範圍內的瀏覽記錄
  startDate: z.string().datetime({ offset: true }).optional(),
  endDate: z.string().datetime({ offset: true }).optional(),
});

type GetTopProductsInput = z.infer<typeof getTopProductsInputSchema>;

// ─── 回應型別 ────────────────────────────────────────────────────────────────

interface TopProductEntry {
  productId: string;
  viewCount: number;
  rank: number;
}

interface GetTopProductsResponse {
  topProducts: TopProductEntry[];
  totalViewsInRange: number; // 符合條件的總瀏覽次數
  dataAsOf: string;          // 查詢時間（ISO 字串），方便前端顯示「資料更新時間」
}

// ─── Cloud Function ──────────────────────────────────────────────────────────

export const getTopProducts = onCall(
  {
    region: "asia-east1",
    // 記憶體聚合可能需要較長時間，設定寬裕 timeout
    timeoutSeconds: 60,
    // 增加記憶體以處理大量資料的記憶體聚合
    memory: "512MiB",
  },
  async (request): Promise<GetTopProductsResponse> => {
    // ── 1. 認證檢查：呼叫者必須已登入 ────────────────────────────────────────
    if (!request.auth) {
      logger.warn("getTopProducts：未登入的呼叫嘗試", {
        severity: "WARNING",
      });
      throw new HttpsError("unauthenticated", "請先登入");
    }

    // ── 2. 權限檢查：呼叫者必須擁有 admin custom claim ───────────────────────
    if (request.auth.token.admin !== true) {
      logger.warn("getTopProducts：非 admin 使用者嘗試存取", {
        severity: "WARNING",
        callerUid: request.auth.uid,
      });
      throw new HttpsError("permission-denied", "僅限 admin 存取此功能");
    }

    // ── 3. 輸入驗證 ──────────────────────────────────────────────────────────
    const parseResult = getTopProductsInputSchema.safeParse(request.data);
    if (!parseResult.success) {
      const firstError = parseResult.error.issues[0];
      logger.warn("getTopProducts：輸入驗證失敗", {
        severity: "WARNING",
        callerUid: request.auth.uid,
        issues: parseResult.error.issues,
      });
      throw new HttpsError(
        "invalid-argument",
        `輸入格式錯誤：${firstError?.message ?? "請確認所有欄位格式正確"}`
      );
    }

    const input: GetTopProductsInput = parseResult.data;
    const db = admin.firestore();

    try {
      // ── 4. 建構查詢（讀取所有符合條件的 productViews 文件）───────────────
      // 注意：此處讀取量與 productViews 資料量線性相關
      // 建議搭配日期範圍縮小查詢範圍
      let query: admin.firestore.Query = db.collection("productViews");

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

      // 若有日期範圍，需要在 viewedAt 上建立索引
      if (input.startDate || input.endDate) {
        query = query.orderBy("viewedAt", "desc");
      }

      // ── 5. 執行查詢並在記憶體中聚合 ─────────────────────────────────────────
      const snapshot = await query.get();

      logger.info("getTopProducts：讀取瀏覽記錄", {
        severity: "INFO",
        callerUid: request.auth.uid,
        totalDocs: snapshot.size,
      });

      // 記憶體中按 productId 計數（Map 保持插入順序，後續按 count 排序）
      const countMap = new Map<string, number>();

      for (const doc of snapshot.docs) {
        const productId = doc.data().productId as string;
        if (!productId) continue; // 跳過資料不完整的記錄

        const current = countMap.get(productId) ?? 0;
        countMap.set(productId, current + 1);
      }

      // 將 Map 轉換為陣列並按瀏覽次數降序排序
      const sortedEntries = Array.from(countMap.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, input.limit);

      // 加入排名
      const topProducts: TopProductEntry[] = sortedEntries.map(
        ([productId, viewCount], index) => ({
          productId,
          viewCount,
          rank: index + 1,
        })
      );

      const totalViewsInRange = snapshot.size;

      logger.info("getTopProducts：聚合完成", {
        severity: "INFO",
        callerUid: request.auth.uid,
        totalViewsInRange,
        uniqueProducts: countMap.size,
        returnCount: topProducts.length,
      });

      return {
        topProducts,
        totalViewsInRange,
        dataAsOf: new Date().toISOString(),
      };
    } catch (err) {
      // 重新拋出已知的 HttpsError
      if (err instanceof HttpsError) throw err;

      logger.error("getTopProducts：查詢或聚合失敗", {
        severity: "ERROR",
        callerUid: request.auth.uid,
        error: (err as Error).message,
        stack: (err as Error).stack,
      });
      throw new HttpsError("internal", "查詢熱門商品失敗，請稍後再試");
    }
  }
);
