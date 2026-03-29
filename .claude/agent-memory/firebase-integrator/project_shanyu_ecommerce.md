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

**Why**: 此為所有其他任務的基礎（T-01 阻塞全部後續任務），需要準確記錄狀態供後續任務參照。

**How to apply**: 後續任務（T-04、T-05 等）執行前先確認此記憶中的狀態，避免重複建立或覆蓋已有內容。T-07 撰寫商品資料模型時須注意安全規則已假設 `status` 欄位（非 `isPublished`）。
