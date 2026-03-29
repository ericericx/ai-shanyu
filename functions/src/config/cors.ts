/**
 * CORS 設定
 *
 * 限制允許發起跨域請求的來源（Origin），防止 CSRF 與未授權的 API 呼叫。
 *
 * 允許清單：
 *   - http://localhost:5000  Flutter Web 開發伺服器（預設 port）
 *   - http://localhost:8080  備用開發 port
 *   - https://*.web.app      Firebase Hosting preview channels
 *   - https://*.firebaseapp.com  Firebase Hosting 預設網域
 *
 * 生產環境網域待確認後，透過環境變數 ALLOWED_ORIGIN 追加，
 * 或更新此設定並重新部署。
 */

import cors from "cors";

/**
 * 允許的 Origin 清單（靜態）
 * 注意：localhost 僅用於開發，部署到生產時確認移除或保持不影響安全性
 */
const ALLOWED_ORIGINS: (string | RegExp)[] = [
  "http://localhost:5000",
  "http://localhost:8080",
  // Firebase Hosting preview channels 與正式 Hosting 網域
  /^https:\/\/shayu-staging\.web\.app$/,
  /^https:\/\/shayu-staging--.*\.web\.app$/,
  /^https:\/\/shayu-staging\.firebaseapp\.com$/,
  /^https:\/\/shayu-production\.web\.app$/,
  /^https:\/\/shayu-production\.firebaseapp\.com$/,
];

/**
 * CORS middleware 設定
 *
 * 使用方式（於 onRequest function 中）：
 *   import { corsHandler } from "../config/cors";
 *   corsHandler(req, res, () => { ... });
 */
export const corsHandler = cors({
  origin: (origin, callback) => {
    // 無 origin（同源請求、伺服器端呼叫、curl 測試）直接放行
    if (!origin) {
      callback(null, true);
      return;
    }

    // 比對允許清單（支援字串完全匹配與正規表達式）
    const allowed = ALLOWED_ORIGINS.some((allowed) =>
      typeof allowed === "string" ? allowed === origin : allowed.test(origin)
    );

    if (allowed) {
      callback(null, true);
    } else {
      callback(new Error(`CORS: Origin '${origin}' 不在允許清單`));
    }
  },
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  // preflight 快取 10 分鐘，減少 OPTIONS 請求次數
  maxAge: 600,
});
