/**
 * Firestore Trigger：監聽新聊天訊息（T-20 即時 Chat 後端）
 *
 * 觸發路徑：chats/{userId}/messages/{messageId}（onCreate）
 *
 * 業務邏輯：
 *   1. 取得新訊息的 senderId
 *   2. 若訊息來自使用者（senderId != 'admin'）：
 *      - 更新父文件 chats/{userId}：
 *        - unreadCount +1（FieldValue.increment，原子性）
 *        - lastMessage：訊息內容截斷至 50 字（防止文件欄位過大）
 *        - lastMessageAt：serverTimestamp
 *        - status：設為 'open'
 *   3. 若訊息來自 admin，不更新 unreadCount（管理員已讀，不產生未讀通知）
 *
 * 設計說明：
 *   - 使用 FieldValue.increment 而非讀-計算-寫，確保並發安全
 *   - lastMessage 截斷至 50 字避免父文件過大影響 chat 列表查詢效能
 *   - 使用 serverTimestamp 確保時間戳一致性（不依賴客戶端時鐘）
 *   - 使用 merge: true 確保父文件不存在時自動建立（防止 trigger 在父文件建立前觸發時失敗）
 *
 * 冪等性說明：
 *   - Firestore triggers 在極少數情況下可能重複觸發
 *   - FieldValue.increment 本身不冪等，但重複觸發的影響為 unreadCount 輕微偏高
 *   - 若需嚴格冪等，可在訊息文件記錄 processed 旗標，但成本較高
 *   - 目前設計接受極低機率的輕微計數偏差（符合聊天場景容忍度）
 *
 * 失敗模式：
 *   - 訊息文件資料缺失（senderId/content 為 undefined）→ 記錄 WARNING 並跳過
 *   - Firestore 更新失敗 → 記錄 ERROR（Cloud Functions 會自動重試，需注意冪等性）
 */

import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";
import { FieldValue } from "firebase-admin/firestore";

// 訊息摘要最大長度（字元數）
const LAST_MESSAGE_MAX_LENGTH = 50;

// admin 的固定 senderId 識別值
const ADMIN_SENDER_ID = "admin";

export const onChatMessage = onDocumentCreated(
  {
    document: "chats/{userId}/messages/{messageId}",
    region: "asia-east1",
  },
  async (event) => {
    const { userId, messageId } = event.params;

    // ── 1. 取得訊息資料 ───────────────────────────────────────────────────────
    const messageData = event.data?.data();

    if (!messageData) {
      // 文件資料為空（極少數情況），記錄並跳過
      logger.warn("onChatMessage：訊息文件資料為空", {
        severity: "WARNING",
        userId,
        messageId,
      });
      return;
    }

    const senderId = messageData.senderId as string | undefined;

    if (!senderId) {
      logger.warn("onChatMessage：訊息缺少 senderId，跳過處理", {
        severity: "WARNING",
        userId,
        messageId,
      });
      return;
    }

    // ── 2. 只在使用者訊息時更新父文件（admin 訊息不產生未讀計數）──────────
    if (senderId === ADMIN_SENDER_ID) {
      logger.info("onChatMessage：admin 訊息，跳過 unreadCount 更新", {
        severity: "INFO",
        userId,
        messageId,
      });
      return;
    }

    // ── 3. 建構 lastMessage 摘要（截斷至 50 字）──────────────────────────────
    const rawContent = (messageData.content as string | undefined) ?? "";
    // 截斷並加上省略號（若超過長度）
    const lastMessage =
      rawContent.length > LAST_MESSAGE_MAX_LENGTH
        ? rawContent.slice(0, LAST_MESSAGE_MAX_LENGTH) + "…"
        : rawContent;

    // ── 4. 更新父文件 chats/{userId} ─────────────────────────────────────────
    const db = admin.firestore();
    const chatRef = db.collection("chats").doc(userId);

    try {
      await chatRef.set(
        {
          // FieldValue.increment 確保並發安全（原子性加 1）
          unreadCount: FieldValue.increment(1),
          lastMessage,
          // serverTimestamp 確保時間戳由 Firestore 伺服器產生，不依賴客戶端時鐘
          lastMessageAt: FieldValue.serverTimestamp(),
          // 有新使用者訊息時，對話狀態重設為 open
          status: "open",
        },
        // merge: true 確保父文件不存在時自動建立，而非覆蓋整個文件
        { merge: true }
      );

      logger.info("onChatMessage：父文件更新成功", {
        severity: "INFO",
        userId,
        messageId,
        lastMessageLength: lastMessage.length,
      });
    } catch (err) {
      logger.error("onChatMessage：更新父文件失敗", {
        severity: "ERROR",
        userId,
        messageId,
        error: (err as Error).message,
        stack: (err as Error).stack,
      });
      // 重新拋出錯誤，讓 Cloud Functions 執行自動重試機制
      throw err;
    }
  }
);
