/**
 * 排程 Function：自動發布預約上架商品
 *
 * 觸發時機：每小時執行一次（Cloud Scheduler）
 * 功能：查詢 status == 'draft' 且 scheduledAt <= now 的商品，
 *       批次更新 status 為 'active' 並寫入 publishedAt。
 *
 * 安全注意：
 *   - 此 function 由 Cloud Scheduler 觸發，無客戶端呼叫入口
 *   - 使用 Admin SDK 寫入，不受 Security Rules 限制（符合預期）
 *
 * 冪等性：
 *   - 查詢條件已包含 scheduledAt != null，避免意外處理無排程商品
 *   - 若同一筆商品在本批次已更新（status 已非 draft），下次觸發時查詢條件自然排除
 *
 * Firestore batch 限制：每批次最多 500 筆寫入操作
 *   - 若待處理商品 > 500，超出部分等下次排程觸發時處理（每小時一次，影響可接受）
 *
 * 失敗模式：
 *   - Firestore 查詢失敗 → 記錄 ERROR，讓 Cloud Scheduler 依設定重試
 *   - batch.commit() 失敗 → 記錄 ERROR 並重新拋出，觸發重試
 *     （batch 操作為全成功或全失敗，不會有部分更新問題）
 */

import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions/v2";
import { Timestamp } from "firebase-admin/firestore";

/**
 * scheduledPublishProducts
 *
 * 排程：每小時整點執行
 * Region：asia-east1（與其他 functions 保持一致）
 */
export const scheduledPublishProducts = onSchedule(
  {
    schedule: "every 1 hours",
    region: "asia-east1",
    timeoutSeconds: 300, // 大量商品時給予足夠執行時間
  },
  async (): Promise<void> => {
    const db = admin.firestore();
    const now = Timestamp.now();

    // ── 1. 查詢所有到期待發布的商品 ─────────────────────────────────────────
    // 條件：
    //   - status == 'draft'：僅處理草稿狀態
    //   - scheduledAt != null：確保有設定預約時間
    //   - scheduledAt <= now：預約時間已到期
    //
    // 注意：Firestore 不等式查詢在同一欄位需複合索引，
    //       此查詢使用 scheduledAt 的兩個條件（!= null + <=），
    //       實際等同於 scheduledAt <= now（null 值不會被 <= 匹配到），
    //       但加上 where('scheduledAt', '!=', null) 可避免 null 被意外包含。
    let snapshot: admin.firestore.QuerySnapshot;

    try {
      snapshot = await db
        .collection("products")
        .where("status", "==", "draft")
        .where("scheduledAt", "!=", null)
        .where("scheduledAt", "<=", now)
        .limit(500) // Firestore batch 最多 500 筆，確保不超過限制
        .get();
    } catch (err) {
      logger.error("scheduledPublishProducts：查詢待發布商品失敗", {
        severity: "ERROR",
        error: (err as Error).message,
      });
      throw err; // 重新拋出讓 Cloud Scheduler 依設定重試
    }

    // ── 2. 無待處理商品則提早結束 ────────────────────────────────────────────
    if (snapshot.empty) {
      logger.info("scheduledPublishProducts：無待發布商品", {
        severity: "INFO",
        checkedAt: now.toDate().toISOString(),
      });
      return;
    }

    // ── 3. 批次更新 status 為 'active' ──────────────────────────────────────
    // 使用 Firestore Batch Write：保證原子性，全部成功或全部失敗
    const batch = db.batch();

    snapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: "active",
        publishedAt: now,
        updatedAt: now,
      });
    });

    try {
      await batch.commit();

      logger.info("scheduledPublishProducts：批次發布商品成功", {
        severity: "INFO",
        publishedCount: snapshot.size,
        publishedAt: now.toDate().toISOString(),
        productIds: snapshot.docs.map((doc) => doc.id),
      });
    } catch (err) {
      logger.error("scheduledPublishProducts：批次更新失敗", {
        severity: "ERROR",
        attemptedCount: snapshot.size,
        error: (err as Error).message,
      });
      throw err; // 重新拋出讓 Cloud Scheduler 依設定重試
    }
  }
);
