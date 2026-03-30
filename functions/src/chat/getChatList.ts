/**
 * Callable Function：查詢客服對話列表（T-20 即時 Chat 後端）
 *
 * 觸發方式：管理後台透過 Firebase Callable SDK 呼叫
 *
 * 業務邏輯：
 *   1. 驗證呼叫者已登入且擁有 admin custom claim
 *   2. 查詢所有 chats/ 頂層文件
 *   3. 可按 status 篩選（'open' / 'closed'）
 *   4. 按 lastMessageAt 降序排列（最新有訊息的對話優先）
 *   5. 回傳對話摘要列表
 *
 * 安全設計：
 *   - 雙重驗證：request.auth != null + admin custom claim
 *   - 此 API 只回傳摘要欄位，不包含訊息內容（訊息在子集合中）
 *
 * 成本考量：
 *   - 讀取所有 chats/ 文件（每個文件為一個用戶的對話摘要）
 *   - 對話數量通常遠小於訊息數量，成本可接受
 *   - 支援 status 篩選減少不必要的讀取
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

const chatStatusSchema = z.enum(["open", "closed"]);

const getChatListInputSchema = z.object({
  // 可選：按 status 篩選，不提供則回傳所有對話
  status: chatStatusSchema.optional(),
});

type GetChatListInput = z.infer<typeof getChatListInputSchema>;

// ─── 回應型別 ────────────────────────────────────────────────────────────────

interface ChatSummary {
  userId: string;
  lastMessage: string;
  lastMessageAt: string | null; // ISO 字串，無訊息時為 null
  unreadCount: number;
  status: "open" | "closed";
}

interface GetChatListResponse {
  chats: ChatSummary[];
  total: number;
}

// ─── Cloud Function ──────────────────────────────────────────────────────────

export const getChatList = onCall(
  {
    region: "asia-east1",
    timeoutSeconds: 30,
  },
  async (request): Promise<GetChatListResponse> => {
    // ── 1. 認證檢查：呼叫者必須已登入 ────────────────────────────────────────
    if (!request.auth) {
      logger.warn("getChatList：未登入的呼叫嘗試", {
        severity: "WARNING",
      });
      throw new HttpsError("unauthenticated", "請先登入");
    }

    // ── 2. 權限檢查：呼叫者必須擁有 admin custom claim ───────────────────────
    if (request.auth.token.admin !== true) {
      logger.warn("getChatList：非 admin 使用者嘗試存取", {
        severity: "WARNING",
        callerUid: request.auth.uid,
      });
      throw new HttpsError("permission-denied", "僅限 admin 存取此功能");
    }

    // ── 3. 輸入驗證 ──────────────────────────────────────────────────────────
    const parseResult = getChatListInputSchema.safeParse(request.data);
    if (!parseResult.success) {
      const firstError = parseResult.error.issues[0];
      logger.warn("getChatList：輸入驗證失敗", {
        severity: "WARNING",
        callerUid: request.auth.uid,
        issues: parseResult.error.issues,
      });
      throw new HttpsError(
        "invalid-argument",
        `輸入格式錯誤：${firstError?.message ?? "請確認所有欄位格式正確"}`
      );
    }

    const input: GetChatListInput = parseResult.data;
    const db = admin.firestore();

    try {
      // ── 4. 建構查詢 ─────────────────────────────────────────────────────────
      let query: admin.firestore.Query = db.collection("chats");

      // 按 status 篩選（若有指定）
      if (input.status) {
        query = query.where("status", "==", input.status);
      }

      // 按 lastMessageAt 降序排列（最新有訊息的對話優先顯示）
      // 注意：若有 status where 條件 + orderBy lastMessageAt，需建立複合索引
      query = query.orderBy("lastMessageAt", "desc");

      // ── 5. 執行查詢 ─────────────────────────────────────────────────────────
      const snapshot = await query.get();

      // ── 6. 序列化結果 ───────────────────────────────────────────────────────
      const chats: ChatSummary[] = snapshot.docs.map((doc) => {
        const data = doc.data();

        // lastMessageAt 可能為 Timestamp 或 null（新建立的對話尚無訊息）
        const lastMessageAt = data.lastMessageAt as
          | admin.firestore.Timestamp
          | null
          | undefined;

        return {
          userId: doc.id,
          lastMessage: (data.lastMessage as string | undefined) ?? "",
          lastMessageAt: lastMessageAt
            ? lastMessageAt.toDate().toISOString()
            : null,
          unreadCount: (data.unreadCount as number | undefined) ?? 0,
          status: (data.status as "open" | "closed" | undefined) ?? "open",
        };
      });

      logger.info("getChatList：查詢成功", {
        severity: "INFO",
        callerUid: request.auth.uid,
        statusFilter: input.status ?? "all",
        resultCount: chats.length,
      });

      return {
        chats,
        total: chats.length,
      };
    } catch (err) {
      // 重新拋出已知的 HttpsError
      if (err instanceof HttpsError) throw err;

      logger.error("getChatList：Firestore 查詢失敗", {
        severity: "ERROR",
        callerUid: request.auth.uid,
        error: (err as Error).message,
        stack: (err as Error).stack,
      });
      throw new HttpsError("internal", "查詢對話列表失敗，請稍後再試");
    }
  }
);
