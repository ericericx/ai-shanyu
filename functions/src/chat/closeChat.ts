/**
 * Callable Function：關閉客服對話（T-20 即時 Chat 後端）
 *
 * 觸發方式：管理後台透過 Firebase Callable SDK 呼叫
 *
 * 業務邏輯：
 *   1. 驗證呼叫者已登入且擁有 admin custom claim
 *   2. 驗證輸入 userId
 *   3. 確認目標 chat 文件存在
 *   4. 將 chats/{userId}.status 設為 'closed'
 *
 * 安全設計：
 *   - 雙重驗證：request.auth != null + admin custom claim
 *   - userId 從 request.data 取得，但必須確認文件存在才操作
 *   - 僅允許 admin 關閉對話，使用者無法自行關閉
 *
 * 冪等性：
 *   - 若對話已為 closed 狀態，重複呼叫不會發生錯誤（update 寫入相同值）
 *   - 適合前端因網路問題重試的場景
 *
 * 失敗模式：
 *   - 未登入 → unauthenticated
 *   - 非 admin → permission-denied
 *   - 輸入格式錯誤（userId 缺失或為空）→ invalid-argument
 *   - 目標 chat 文件不存在 → not-found
 *   - Firestore 更新失敗 → internal
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { z } from "zod";

// ─── 輸入驗證 Schema ─────────────────────────────────────────────────────────

const closeChatInputSchema = z.object({
  userId: z.string().min(1, "userId 不可為空"),
});

type CloseChatInput = z.infer<typeof closeChatInputSchema>;

// ─── 回應型別 ────────────────────────────────────────────────────────────────

interface CloseChatResponse {
  success: true;
  userId: string;
}

// ─── Cloud Function ──────────────────────────────────────────────────────────

export const closeChat = onCall(
  {
    region: "asia-east1",
    timeoutSeconds: 15,
  },
  async (request): Promise<CloseChatResponse> => {
    // ── 1. 認證檢查：呼叫者必須已登入 ────────────────────────────────────────
    if (!request.auth) {
      logger.warn("closeChat：未登入的呼叫嘗試", {
        severity: "WARNING",
      });
      throw new HttpsError("unauthenticated", "請先登入");
    }

    // ── 2. 權限檢查：呼叫者必須擁有 admin custom claim ───────────────────────
    if (request.auth.token.admin !== true) {
      logger.warn("closeChat：非 admin 使用者嘗試關閉對話", {
        severity: "WARNING",
        callerUid: request.auth.uid,
      });
      throw new HttpsError("permission-denied", "僅限 admin 執行此操作");
    }

    // ── 3. 輸入驗證 ──────────────────────────────────────────────────────────
    const parseResult = closeChatInputSchema.safeParse(request.data);
    if (!parseResult.success) {
      const firstError = parseResult.error.issues[0];
      logger.warn("closeChat：輸入驗證失敗", {
        severity: "WARNING",
        callerUid: request.auth.uid,
        issues: parseResult.error.issues,
      });
      throw new HttpsError(
        "invalid-argument",
        `輸入格式錯誤：${firstError?.message ?? "請確認所有欄位格式正確"}`
      );
    }

    const input: CloseChatInput = parseResult.data;
    const db = admin.firestore();
    const chatRef = db.collection("chats").doc(input.userId);

    try {
      // ── 4. 確認 chat 文件存在 ─────────────────────────────────────────────
      const chatSnap = await chatRef.get();

      if (!chatSnap.exists) {
        logger.warn("closeChat：目標對話不存在", {
          severity: "WARNING",
          callerUid: request.auth.uid,
          targetUserId: input.userId,
        });
        throw new HttpsError(
          "not-found",
          `使用者 ${input.userId} 的對話不存在`
        );
      }

      // ── 5. 更新 status 為 'closed' ─────────────────────────────────────────
      // 同時重設 unreadCount 為 0（對話關閉時清除未讀標記）
      await chatRef.update({
        status: "closed",
        unreadCount: 0,
        closedAt: admin.firestore.FieldValue.serverTimestamp(),
        closedBy: request.auth.uid,
      });

      logger.info("closeChat：對話已關閉", {
        severity: "INFO",
        callerUid: request.auth.uid,
        targetUserId: input.userId,
      });

      return {
        success: true,
        userId: input.userId,
      };
    } catch (err) {
      // 重新拋出已知的 HttpsError
      if (err instanceof HttpsError) throw err;

      logger.error("closeChat：Firestore 更新失敗", {
        severity: "ERROR",
        callerUid: request.auth.uid,
        targetUserId: input.userId,
        error: (err as Error).message,
        stack: (err as Error).stack,
      });
      throw new HttpsError("internal", "關閉對話失敗，請稍後再試");
    }
  }
);
