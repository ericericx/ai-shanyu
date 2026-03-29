/**
 * Callable Function：為指定使用者設定 admin custom claim
 *
 * 用途：T-17 管理後台的前置準備，允許現有 admin 晉升其他使用者為 admin
 * 觸發方式：Flutter/Web 客戶端透過 Firebase Callable SDK 呼叫
 *
 * 安全設計：
 *   - 雙重驗證：先確認呼叫者已登入（auth != null），再確認呼叫者擁有 admin claim
 *   - 目標 uid 必須通過 Zod schema 驗證，防止格式異常輸入
 *   - setCustomUserClaims 為 Admin SDK 操作，不影響客戶端能直接修改
 *
 * 注意：custom claims 在下次 token refresh 前不會在客戶端生效（最長 1 小時）
 * 建議呼叫後強制客戶端執行 user.getIdToken(true) 以立即取得新 token
 *
 * 失敗模式：
 *   - 呼叫者未登入 → unauthenticated
 *   - 呼叫者非 admin → permission-denied
 *   - 目標 uid 不存在 → not-found
 *   - 輸入格式錯誤 → invalid-argument
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { safeParse, setAdminClaimInputSchema } from "../utils/validators";

export const setAdminClaim = onCall(
  { region: "asia-east1" },
  async (request): Promise<{ success: true; message: string }> => {
    // ── 1. 認證檢查：呼叫者必須已登入 ────────────────────────────────────────
    if (!request.auth) {
      logger.warn("setAdminClaim：未登入的呼叫嘗試", { severity: "WARNING" });
      throw new HttpsError("unauthenticated", "請先登入");
    }

    // ── 2. 權限檢查：呼叫者必須已有 admin claim ───────────────────────────────
    const callerClaims = request.auth.token;
    if (callerClaims.admin !== true) {
      logger.warn("setAdminClaim：非 admin 呼叫者嘗試提升權限", {
        severity: "WARNING",
        callerUid: request.auth.uid,
      });
      throw new HttpsError("permission-denied", "僅限 admin 執行此操作");
    }

    // ── 3. 輸入驗證：透過 Zod schema 確認 uid 格式 ───────────────────────────
    const parseResult = safeParse(setAdminClaimInputSchema, request.data);
    if (!parseResult.success) {
      throw new HttpsError(
        "invalid-argument",
        `輸入格式錯誤：${parseResult.errors.join(", ")}`
      );
    }

    const { uid: targetUid } = parseResult.data;

    // ── 4. 確認目標使用者存在 ────────────────────────────────────────────────
    try {
      await admin.auth().getUser(targetUid);
    } catch (err) {
      const error = err as admin.FirebaseError;
      if (error.code === "auth/user-not-found") {
        throw new HttpsError("not-found", `找不到 uid 為 ${targetUid} 的使用者`);
      }
      // 其他 Auth 錯誤
      logger.error("setAdminClaim：讀取目標使用者失敗", {
        severity: "ERROR",
        targetUid,
        errorCode: error.code,
      });
      throw new HttpsError("internal", "系統發生錯誤，請稍後再試");
    }

    // ── 5. 設定 admin custom claim ───────────────────────────────────────────
    try {
      await admin.auth().setCustomUserClaims(targetUid, { admin: true });

      logger.info("admin claim 設定成功", {
        severity: "INFO",
        callerUid: request.auth.uid,
        targetUid,
      });

      return {
        success: true,
        message: `使用者 ${targetUid} 已設定為 admin。客戶端須執行 getIdToken(true) 以立即生效。`,
      };
    } catch (err) {
      logger.error("setAdminClaim：設定 custom claim 失敗", {
        severity: "ERROR",
        targetUid,
        error: (err as Error).message,
      });
      throw new HttpsError("internal", "設定 admin 失敗，請稍後再試");
    }
  }
);
