/**
 * 山裕電商系統 - Cloud Functions 入口
 *
 * 此檔案為 T-01 初始骨架，各功能模組會在對應任務中實作：
 *   - auth.ts     : T-05 使用者認證觸發器（onUserCreated）
 *   - products.ts : T-14 預約上架排程（scheduledPublishProducts）
 *   - orders.ts   : T-13 訂單建立通知（onOrderCreated）
 *   - admin.ts    : T-17 管理員權限設定（setAdminClaim）
 *
 * 環境：Node.js 20, Firebase Functions v6
 */

import * as admin from "firebase-admin";

// 初始化 Firebase Admin SDK（使用預設服務帳號憑證，勿硬編碼任何 key）
admin.initializeApp();

// 匯出各功能模組（目前為預留，各模組在對應任務完成後取消註解）
// export * from "./auth";
// export * from "./products";
// export * from "./orders";
// export * from "./admin";

/**
 * 健康檢查 HTTP Function
 * 用途：確認 Cloud Functions 部署正常（T-01 驗收使用）
 */
export { healthCheck } from "./health";
