/**
 * Firestore Trigger：同步使用者角色到 Firebase Auth Custom Claims
 *
 * 觸發時機：users/{uid} 文件被更新時
 * 功能：當 role 欄位變更為 'admin' 時，設定 Firebase Auth custom claim { admin: true }；
 *       若 role 從 'admin' 變更為其他值，撤銷 claim 設為 { admin: false }。
 *
 * 安全設計：
 *   - custom claim 由 Admin SDK 設定，客戶端無法自行修改
 *   - 只在 role 實際發生變更時才呼叫 setCustomUserClaims，避免不必要的 Auth 操作
 *   - updatedAt 由 Function 更新，不信任客戶端傳入的時間戳
 *
 * 冪等性：
 *   - setCustomUserClaims 為覆寫操作，重複執行結果一致
 *   - 若 before/after role 相同，Function 提早返回，不執行任何副作用
 *
 * 注意：custom claims 在使用者下次重新取得 ID token 前不會生效（最長 1 小時）
 *       建議在前端收到 role 更新的通知後，呼叫 user.getIdToken(true) 強制刷新
 *
 * 失敗模式：
 *   - setCustomUserClaims 失敗 → 記錄 ERROR 並重新拋出（Firestore trigger 會重試）
 *   - Firestore updatedAt 更新失敗 → 記錄 WARNING，不阻斷主流程
 *     （claim 已成功設定，updatedAt 落後可接受，後續操作會覆蓋）
 */

import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

export const onRoleUpdated = onDocumentUpdated(
  {
    document: "users/{uid}",
    region: "asia-east1",
  },
  async (event): Promise<void> => {
    const uid = event.params.uid;

    // ── 1. 防禦性檢查：確保 before/after 資料存在 ───────────────────────────
    // onDocumentUpdated 理論上保證兩者都有值，但防禦性處理避免型別警告
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      logger.warn("onRoleUpdated：before 或 after 資料不存在，略過處理", {
        severity: "WARNING",
        uid,
      });
      return;
    }

    const roleBefore = beforeData.role as string | undefined;
    const roleAfter = afterData.role as string | undefined;

    // ── 2. 角色未變更則提早返回（避免不必要的 Auth 操作）───────────────────
    if (roleBefore === roleAfter) {
      return;
    }

    // ── 3. 決定要設定的 custom claim ────────────────────────────────────────
    const isNowAdmin = roleAfter === "admin";
    const wasAdmin = roleBefore === "admin";

    // 只處理：admin 晉升 或 admin 撤銷
    // 其他角色間的轉換（e.g. customer -> staff）不影響 admin claim
    if (!isNowAdmin && !wasAdmin) {
      logger.info("onRoleUpdated：非 admin 相關的角色變更，略過 claim 處理", {
        severity: "INFO",
        uid,
        roleBefore,
        roleAfter,
      });
      return;
    }

    const newClaim = { admin: isNowAdmin };

    // ── 4. 更新 Firebase Auth custom claim ──────────────────────────────────
    try {
      await admin.auth().setCustomUserClaims(uid, newClaim);

      logger.info("onRoleUpdated：custom claim 已同步", {
        severity: "INFO",
        uid,
        roleBefore,
        roleAfter,
        adminClaim: isNowAdmin,
      });
    } catch (err) {
      logger.error("onRoleUpdated：setCustomUserClaims 失敗", {
        severity: "ERROR",
        uid,
        roleBefore,
        roleAfter,
        error: (err as Error).message,
      });
      throw err; // 重新拋出，讓 Firestore trigger 重試
    }

    // ── 5. 更新 Firestore users/{uid} 的 updatedAt ──────────────────────────
    // 此步驟為輔助記錄，失敗不應阻斷主流程（claim 已成功設定）
    try {
      await admin
        .firestore()
        .collection("users")
        .doc(uid)
        .update({
          updatedAt: admin.firestore.Timestamp.now(),
        });
    } catch (err) {
      // 記錄警告但不重新拋出：updatedAt 落後可接受，不值得觸發重試
      logger.warn("onRoleUpdated：更新 updatedAt 失敗（非致命）", {
        severity: "WARNING",
        uid,
        error: (err as Error).message,
      });
    }
  }
);
