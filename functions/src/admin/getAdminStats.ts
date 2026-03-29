/**
 * Callable Function：後台統計資料查詢
 *
 * 用途：管理後台首頁儀表板，回傳系統基本統計數字
 * 觸發方式：Flutter/Web 管理後台透過 Firebase Callable SDK 呼叫
 *
 * 安全設計：
 *   - 雙重驗證：確認已登入 + 確認擁有 admin custom claim
 *   - 使用 Firestore Aggregation Query（count()），不讀取文件內容
 *     避免讀取大量使用者/訂單資料造成隱私風險與成本浪費
 *   - count() 計費：按 aggregation 查詢次數計費，不按文件數量計費
 *
 * 回傳資料：
 *   - totalUsers：系統總使用者數
 *   - totalOrders：系統總訂單數
 *   - pendingOrders：待處理訂單數（status == 'pending'）
 *
 * 失敗模式：
 *   - 呼叫者未登入 → unauthenticated
 *   - 呼叫者非 admin → permission-denied
 *   - Firestore 查詢失敗 → internal（記錄 ERROR，回傳通用錯誤訊息）
 *
 * 注意：若需新增統計項目，請評估是否改用 Firestore counter 累計寫入，
 *       以避免大量資料時 count() 查詢延遲增加。
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

/**
 * 統計結果型別
 */
interface AdminStats {
  totalUsers: number;
  totalOrders: number;
  pendingOrders: number;
}

export const getAdminStats = onCall(
  { region: "asia-east1" },
  async (request): Promise<AdminStats> => {
    // ── 1. 認證檢查：呼叫者必須已登入 ────────────────────────────────────────
    if (!request.auth) {
      logger.warn("getAdminStats：未登入的呼叫嘗試", { severity: "WARNING" });
      throw new HttpsError("unauthenticated", "請先登入");
    }

    // ── 2. 權限檢查：呼叫者必須擁有 admin custom claim ───────────────────────
    if (request.auth.token.admin !== true) {
      logger.warn("getAdminStats：非 admin 使用者嘗試存取後台統計", {
        severity: "WARNING",
        callerUid: request.auth.uid,
      });
      throw new HttpsError("permission-denied", "僅限 admin 存取此功能");
    }

    const db = admin.firestore();

    // ── 3. 執行三個平行 aggregation 查詢，降低總延遲 ────────────────────────
    // 使用 Firestore count() aggregation：
    //   - 計費單位為 aggregation 查詢次數，不按讀取文件數計費
    //   - 適合大量資料的計數場景，效能優於 getDocs().size
    try {
      const [
        usersCountSnap,
        ordersCountSnap,
        pendingOrdersCountSnap,
      ] = await Promise.all([
        // 總使用者數
        db.collection("users").count().get(),
        // 總訂單數
        db.collection("orders").count().get(),
        // 待處理訂單數（status == 'pending'）
        db.collection("orders")
          .where("status", "==", "pending")
          .count()
          .get(),
      ]);

      const stats: AdminStats = {
        totalUsers: usersCountSnap.data().count,
        totalOrders: ordersCountSnap.data().count,
        pendingOrders: pendingOrdersCountSnap.data().count,
      };

      logger.info("getAdminStats：查詢成功", {
        severity: "INFO",
        callerUid: request.auth.uid,
        stats,
      });

      return stats;
    } catch (err) {
      logger.error("getAdminStats：Firestore 查詢失敗", {
        severity: "ERROR",
        callerUid: request.auth.uid,
        error: (err as Error).message,
      });
      throw new HttpsError("internal", "查詢統計資料失敗，請稍後再試");
    }
  }
);
