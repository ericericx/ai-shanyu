---
name: 山裕電商系統 v1 專案基礎資訊
description: shanyu-ecommerce-v1 的 Firebase 基礎架構狀態、專案 ID 與任務進度
type: project
---

山裕電商系統 v1 採用 Firebase + Flutter Web 架構，OpenSpec 變更名稱為 `shanyu-ecommerce-v1`。

**Firebase 專案 ID**：
- Staging（development）：`shayu-staging`
- Production：`shayu-production`（尚未建立，預留）

**Firebase CLI alias**：
- `staging` → `shayu-staging`
- `production` → `shayu-production`

**T-01 完成狀態（2026-03-29）**：
- `.firebaserc` 建立完成，設定 staging/production alias
- `firebase.json` 建立完成，涵蓋 Firestore、Functions、Storage、Hosting
- `firestore.rules` 建立（開發用寬鬆規則，T-03 會替換為正式版）
- `firestore.indexes.json` 建立（初始空白，T-03 會填入完整 indexes）
- `storage.rules` 建立（開發用寬鬆規則）
- `functions/` 初始化完成：TypeScript、Node.js 20、v2 API
- `shanyu_app/` Flutter Web 專案建立（org: com.shanyu，platforms: web only）
- `.gitignore` 建立，含 Firebase、Flutter、機密檔案的排除規則

**重要提醒**：
- `firestore.rules` 與 `storage.rules` 目前為 `allow read, write: if true` — 開發暫用，T-03 前禁止部署到 production
- `firebase_options_development.dart` 由 flutter-artisan 負責產出（T-01 產出物之一）
- Cloud Functions 使用 firebase-functions v6（v2 API），不是舊版 v1 API，`functions.region()` 方法不存在，須用 `onRequest({ region: ... })` 語法

**T-03 完成狀態（2026-03-29）**：
- `firestore.rules` 正式安全規則已撰寫並部署到 `shayu-staging`
- `firestore.indexes.json` 已填入 7 個複合索引並部署到 `shayu-staging`
- 舊的 `allow read, write: if true` 開發規則已替換完畢
- 規則涵蓋：users、products（含 variants 子集合）、categories、orders、carts、cms、productViews、chats（含 messages 子集合）、adminSettings
- 索引涵蓋：products x2、orders x2、productViews x2、chats x1

**重要設計決策（T-03）**：
- `products` 與 `categories` 為公開讀取（`allow read: if true`），配合前台無登入瀏覽需求
- `productViews` 允許匿名 create（匿名追蹤），但 update/delete 明確設為 `false`
- `chats` 的 chatId 設計為等於 userId（一人一 chat），因此規則用 `isOwner(chatId)` 而非讀取文件欄位
- `orders` 的 delete 明確設為 `false`（稽核需求，不允許實體刪除）
- 索引欄位名稱：`productViews` 用 `viewedAt`（非 design.md 的 `behaviors.date`）、products 用 `status`（非 `isPublished`）

**T-04 完成狀態（2026-03-29）**：
- `functions/src/utils/auth.ts`：verifyBearerToken、getUserDoc、isAdmin 工具函式
- `functions/src/utils/response.ts`：sendSuccess、sendError 及快捷函式（sendUnauthorized 等）
- `functions/src/utils/validators.ts`：safeParse、uidSchema、emailSchema、paginationSchema、setAdminClaimInputSchema
- `functions/src/config/cors.ts`：CORS middleware，允許 localhost:5000/8080 及 Firebase Hosting 網域
- `functions/src/index.ts`：auth 匯出 `onUserCreated`、`getMe`、`setAdminClaim`；並匯出 analytics／chat 等模組（見原始碼）
- cors、express、zod 及其型別定義均已安裝
- 所有 function region 統一為 `asia-east1`

**T-05 完成狀態（2026-03-30 更新）**：
- Firestore `users/{uid}`：`onUserCreated` 於新 Auth 帳號建立時寫入；`getMe` callable 可於缺文件時以 Admin SDK 補建；客戶端 `ensureUserFirestoreProfile` 仍於登入／註冊後補齊缺件（欄位一致）
- `functions/src/scripts/setBootstrapAdmin.ts` + `npm run bootstrap-admin -- <UID>`：Console 無法設 custom claims，用於首位 admin（需 ADC 或 `GOOGLE_APPLICATION_CREDENTIALS`）
- `setAdminClaim`：Callable，現有 admin 才能呼叫；雙重驗證：登入 + admin claim

**T-13 完成狀態（2026-03-29）**：
- `functions/src/orders/createOrder.ts`：Callable function，Firestore Transaction 原子扣庫存 + 建訂單 + 清購物車
- `functions/src/orders/getOrderHistory.ts`：Callable function，cursor-based 分頁查詢訂單歷史
- `functions/src/orders/index.ts`：模組匯出入口
- `functions/src/index.ts`：已匯出 `createOrder`、`getOrderHistory`
- 編譯確認通過（`npm run build` 無錯誤）

**重要設計細節（T-13）**：
- Zod v4 使用 `parseResult.error.issues`（非 v3 的 `errors`）
- `createOrder` Transaction 內必須先完成所有讀取後再執行寫入（Firestore Transaction 規則）
- 金額（price、subtotal）由後端從 variants 讀取，不信任客戶端傳入
- 預購商品（isPreorder=true）允許 stock 扣為負數；一般商品嚴格驗證庫存
- `getOrderHistory` cursor 安全性驗證：lastOrderId 對應文件的 userId 必須等於 auth.uid，防止以他人 orderId 作為分頁游標
- SHIPPING_FEE 目前固定為 0（免運），T-16 金流整合後可能改為動態計算

**Why**: 此為所有其他任務的基礎（T-01 阻塞全部後續任務），需要準確記錄狀態供後續任務參照。

**How to apply**: 後續任務執行前先確認此記憶中的狀態，避免重複建立或覆蓋已有內容。T-07 撰寫商品資料模型時須注意安全規則已假設 `status` 欄位（非 `isPublished`）。users 文件結構已由 T-05 定義，後續操作 users 集合應與此結構保持一致。
