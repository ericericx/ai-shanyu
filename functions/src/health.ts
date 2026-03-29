/**
 * 健康檢查 Function
 * T-01 驗收用：確認 Cloud Functions 部署成功
 *
 * firebase-functions v6 使用 v2 API
 */

import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

/**
 * GET /healthCheck
 * 回傳系統狀態與版本資訊
 * 無敏感資料，不需要認證
 */
export const healthCheck = onRequest(
  { region: "asia-east1" },
  (req, res) => {
    // 只允許 GET 請求
    if (req.method !== "GET") {
      res.status(405).json({ error: "Method Not Allowed" });
      return;
    }

    try {
      res.status(200).json({
        status: "ok",
        project: process.env.GCLOUD_PROJECT || "shayu-staging",
        region: "asia-east1",
        timestamp: new Date().toISOString(),
        version: "1.0.0",
      });
    } catch (error) {
      logger.error("healthCheck 發生錯誤", { error });
      res.status(500).json({ error: "Internal Server Error" });
    }
  }
);
