/**
 * 山裕電商系統 - Cloud Functions 入口
 *
 * 所有 function 統一在此匯出，region 統一為 asia-east1。
 * 各功能模組對應任務如下：
 *   - auth/     : T-05 使用者認證觸發器與 callable functions
 *   - products/ : T-14 預約上架排程（scheduledPublishProducts）
 *   - admin/    : T-17 角色變更同步 claim（onRoleUpdated）、後台統計（getAdminStats）
 *   - orders/   : T-13 訂單建立通知（onOrderCreated）
 *
 * 環境：Node.js 20, Firebase Functions v6（v2 API）
 * 注意：v2 API 使用 onRequest({ region: "asia-east1" }) 語法，
 *       不存在舊版 functions.region() 方法。
 */

import * as admin from "firebase-admin";

// 初始化 Firebase Admin SDK（使用預設服務帳號憑證，勿硬編碼任何 key）
admin.initializeApp();

// ─── 健康檢查（T-01 驗收）────────────────────────────────────────────────────
export { healthCheck } from "./health";

// ─── Auth 功能（T-05）────────────────────────────────────────────────────────
export { onUserCreated } from "./auth/onUserCreated";
export { setAdminClaim } from "./auth/setAdminClaim";
export { getMe } from "./auth/getMe";

// ─── 商品功能（T-14）─────────────────────────────────────────────────────────
export { scheduledPublishProducts } from "./products/scheduledPublish";

// ─── 管理後台功能（T-17）─────────────────────────────────────────────────────
export { onRoleUpdated } from "./admin/onRoleUpdated";
export { getAdminStats } from "./admin/getAdminStats";

// ─── 訂單功能（T-13，待實作）─────────────────────────────────────────────────
// export * from "./orders";
