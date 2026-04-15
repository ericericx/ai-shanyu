## 1. 資料模型與 Repository

- [ ] 1.1 建立 `page_view_tracker.dart`（位於 `core/tracking/`），包含 `PageViewRecord` 資料類別，定義 path、title、userId、timestamp、sessionId、referrer 欄位
- [ ] 1.2 在 `PageViewTracker` 中實作 `trackPageView()` 方法，採用 fire-and-forget 模式寫入 Firestore `pageViews` 集合，失敗時僅 debugPrint 不拋出例外
- [ ] 1.3 實作 sessionId 機制：App 啟動時產生 UUID v4 作為 sessionId，存於 PageViewTracker 實例記憶體中，同一 session 共用

## 2. GoRouter Observer 整合

- [ ] 2.1 在 `page_view_tracker.dart` 中建立 `PageViewTrackerObserver extends NavigatorObserver`，覆寫 `didPush` 與 `didReplace` 方法，從 Route settings 取得路徑資訊後呼叫 `trackPageView()`
- [ ] 2.2 實作頁面標題對應邏輯：根據路由路徑對應中文頁面標題（首頁、分類頁、商品詳情、購物車、結帳、訂單等）
- [ ] 2.3 實作 referrer 追蹤：在 Observer 中維護前一頁路徑，didPush 時將當前頁設為下一次的 referrer

## 3. Provider 串接

- [ ] 3.1 建立 `page_view_providers.dart`（位於 `core/tracking/`），提供 `pageViewTrackerProvider` 與 `pageViewTrackerObserverProvider`（`@Riverpod` annotation）
- [ ] 3.2 修改 `app_router.dart`：在 `GoRouter` 建構時加入 `observers` 參數，注入 `PageViewTrackerObserver` 實例
- [ ] 3.3 整合 Auth 狀態：Provider 中透過 `ref.watch(authStateProvider)` 取得當前 userId，傳入 PageViewTracker 供記錄使用
