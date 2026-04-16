## 1. Repository 擴充（新增頁面瀏覽與統計查詢方法）

- [ ] 1.1 在 `crm_models.dart` 新增 `OverviewStats` 資料類別（todayPageViews、monthlyOrders、monthlyRevenue、activeUsers）與 `PopularPage` 資料類別（path、title、viewCount）
- [ ] 1.2 在 `crm_repository.dart` 新增 `getOverviewStats()` 方法：查詢 `pageViews` 集合取得今日瀏覽數與本月活躍用戶數，查詢 `orders` 集合取得本月訂單數與營收
- [ ] 1.3 在 `crm_repository.dart` 新增 `getTopPages({required DateTime since, int limit = 10})` 方法：查詢 `pageViews` 集合，client 端按 path 分組計數，回傳前 N 名熱門頁面

## 2. Provider 新增

- [ ] 2.1 在 `crm_providers.dart` 新增 `overviewStatsProvider`（`@riverpod` FutureProvider），呼叫 `CrmRepository.getOverviewStats()`
- [ ] 2.2 在 `crm_providers.dart` 新增 `topPagesProvider`（`@riverpod` FutureProvider，接受 `DateTime since` 參數），呼叫 `CrmRepository.getTopPages()`

## 3. CRM 頁面 tab 改造

- [ ] 3.1 將 `CrmPage` 改為 `TabBar` + `TabBarView` 佈局，包含三個 tab：「概覽」「頁面分析」「商品分析」
- [ ] 3.2 將現有的篩選列、熱門商品排行、瀏覽記錄列表移至「商品分析」tab，確保現有功能完整保留

## 4. 概覽 tab UI

- [ ] 4.1 建立概覽 tab 元件，以 2x2 網格佈局顯示四張統計卡片（今日瀏覽數、本月訂單數、本月營收、活躍用戶數）
- [ ] 4.2 實作統計卡片元件（StatCard），包含圖示、指標名稱、數值，營收金額以 NT$ 格式顯示
- [ ] 4.3 實作載入中與錯誤狀態處理

## 5. 頁面分析 tab UI

- [ ] 5.1 建立頁面分析 tab 元件，頂部放置時間範圍篩選按鈕列（今日 / 近 7 天 / 近 30 天），下方顯示熱門頁面排行
- [ ] 5.2 實作時間範圍篩選邏輯：點擊切換按鈕後重新查詢對應時間範圍的資料
- [ ] 5.3 實作熱門頁面排行列表項（PageRankCard），顯示排名、頁面路徑、頁面標題與瀏覽次數
- [ ] 5.4 實作載入中、空狀態與錯誤狀態處理
