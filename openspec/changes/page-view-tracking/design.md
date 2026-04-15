## Context

目前專案已有 `ProductViewTracker`（位於 `features/products/data/product_view_tracker.dart`），在使用者進入商品詳情頁時手動呼叫 `trackProductView()` 寫入 Firestore `productViews` 集合。後台 CRM 頁面（`features/admin/presentation/crm_page.dart`）透過 `CrmRepository` 讀取這些記錄並顯示熱門商品排行。

路由系統使用 GoRouter（`core/router/app_router.dart`），狀態管理使用 Riverpod + code generation（`@Riverpod` annotation）。GoRouter 支援 `observers` 參數，可注入 `NavigatorObserver` 子類別在頁面切換時自動觸發回呼。

現有程式碼資產：
- `ProductViewTracker`：fire-and-forget 模式 + 靜默失敗原則，可作為設計參考
- `app_router.dart`：`appRouter` 為 `@Riverpod(keepAlive: true)` Provider，回傳 `GoRouter` 實例
- Auth 狀態透過 `authStateProvider` 取得，可用於判斷 userId

## Goals / Non-Goals

**Goals:**
- 全站頁面瀏覽自動追蹤，涵蓋所有路由（首頁、分類頁、商品詳情、購物車、結帳、訂單等）
- 匿名與登入使用者皆追蹤
- 追蹤資料寫入 Firestore，供後台分析使用
- 不影響頁面載入效能（fire-and-forget）

**Non-Goals:**
- 後台頁面瀏覽統計 UI（後續迭代）
- 頁面停留時間追蹤
- 替換現有 `productViews` 追蹤（兩者獨立並行）
- 離線快取或批次上傳

## Decisions

### D1：使用 NavigatorObserver 自動追蹤而非手動埋點
**決策**：建立 `PageViewTrackerObserver extends NavigatorObserver`，在 `didPush` 和 `didReplace` 時自動記錄。
**理由**：自動追蹤可確保所有頁面都被涵蓋，無需在每個頁面手動呼叫追蹤方法。新增頁面時也無需額外設定。

### D2：資料寫入獨立的 `pageViews` 集合而非合併至 `productViews`
**決策**：新增 Firestore `pageViews` 集合，與 `productViews` 分開存放。
**理由**：`productViews` 專注於商品瀏覽，結構固定（含 productId）；`pageViews` 記錄所有頁面，結構不同（含 path、title、referrer）。分開存放方便各自查詢與索引。

### D3：SessionId 使用 UUID 在 App 啟動時產生
**決策**：每次 App 啟動（或重新整理）時產生一組 UUID v4 作為 sessionId，存於記憶體中。
**理由**：Web 環境下每次重新整理即為新 session，無需持久化。UUID 可唯一標識一次瀏覽工作階段，便於後續分析同一 session 的瀏覽路徑。

### D4：遵循現有 ProductViewTracker 的靜默失敗模式
**決策**：Firestore 寫入失敗時僅 `debugPrint`，不拋出例外、不影響頁面流程。
**理由**：追蹤為輔助功能，不應影響核心使用者體驗。與現有 `ProductViewTracker` 行為一致。

### D5：透過 Riverpod Provider 注入 Observer
**決策**：建立 `pageViewTrackerObserverProvider`，在 `appRouter` Provider 中透過 `ref.read` 取得 observer 實例並傳入 GoRouter 的 `observers` 參數。
**理由**：符合專案現有的 Riverpod 架構，方便管理依賴關係（取得 Firestore 實例與 Auth 狀態）。

## Firestore 資料結構

```
pageViews/{docId}
  path: string          // 路由路徑，例如 "/", "/products/fruit", "/cart"
  title: string         // 頁面標題，例如 "首頁", "水果分類", "購物車"
  userId: string | null // 登入使用者 UID，匿名時為 null
  timestamp: Timestamp  // 伺服器時間戳記
  sessionId: string     // UUID v4，同一 session 共用
  referrer: string      // 前一頁路徑，無前一頁時為空字串
```

## 架構概覽

```
core/
  router/
    app_router.dart          ← 修改：加入 observers 參數
  tracking/
    page_view_tracker.dart   ← 新增：NavigatorObserver + Firestore 寫入
    page_view_providers.dart ← 新增：Riverpod Provider
```

## Risks / Trade-offs

- **[Firestore 寫入量]** 每次頁面切換都寫入一筆文件，流量高時可能產生較多寫入 → fire-and-forget 模式不影響效能，後續可考慮批次寫入或 Cloud Functions 聚合
- **[NavigatorObserver 限制]** GoRouter 的 observer 在 `StatefulShellRoute` 下的子路由切換可能不會觸發 `didPush` → 需實測確認，必要時在 ShellRoute 層級額外處理
- **[Session 定義]** 瀏覽器重新整理即產生新 sessionId，無法追蹤跨 tab 行為 → Web 環境限制，可接受
