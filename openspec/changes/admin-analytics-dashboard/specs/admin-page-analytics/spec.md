## ADDED Requirements

### Requirement: 熱門頁面排行顯示
頁面分析 tab SHALL 顯示熱門頁面排行榜，列出指定時間範圍內瀏覽次數最高的前 10 個頁面。每個排行項目 SHALL 包含排名、頁面路徑、頁面標題與瀏覽次數。

#### Scenario: 有頁面瀏覽資料時顯示排行
- **GIVEN** `pageViews` 集合中指定時間範圍內有多個頁面的瀏覽記錄
- **WHEN** 管理員切換至「頁面分析」tab
- **THEN** SHALL 顯示瀏覽次數最高的前 10 個頁面排行
- **AND** 排行依瀏覽次數由高至低排列
- **AND** 每個項目 SHALL 顯示排名序號、頁面路徑（path）、頁面標題（title）與瀏覽次數

#### Scenario: 指定時間範圍內無瀏覽資料
- **GIVEN** `pageViews` 集合中指定時間範圍內沒有任何記錄
- **WHEN** 管理員查看頁面分析 tab
- **THEN** SHALL 顯示空狀態提示訊息（例如「該時段尚無頁面瀏覽記錄」）

#### Scenario: 頁面排行資料載入中
- **GIVEN** 管理員切換至頁面分析 tab 或變更時間範圍
- **WHEN** 資料尚在查詢與聚合中
- **THEN** SHALL 顯示載入中指示器

#### Scenario: 頁面排行資料載入失敗
- **GIVEN** Firestore 查詢失敗
- **WHEN** 頁面排行無法取得資料
- **THEN** SHALL 顯示錯誤訊息
- **AND** SHALL NOT 導致頁面崩潰

### Requirement: 時間範圍篩選
頁面分析 tab SHALL 提供時間範圍篩選功能，支援「今日」「近 7 天」「近 30 天」三個預設選項。篩選變更後 SHALL 重新查詢並更新排行資料。

#### Scenario: 預設顯示今日資料
- **GIVEN** 管理員首次切換至頁面分析 tab
- **WHEN** tab 載入完成
- **THEN** 時間範圍 SHALL 預設選中「今日」
- **AND** 排行 SHALL 顯示今日的頁面瀏覽統計

#### Scenario: 切換至近 7 天
- **GIVEN** 管理員正在查看頁面分析 tab，當前選中「今日」
- **WHEN** 管理員點擊「近 7 天」篩選按鈕
- **THEN** 「近 7 天」按鈕 SHALL 呈現選中狀態
- **AND** 排行 SHALL 重新載入，顯示過去 7 天的頁面瀏覽統計

#### Scenario: 切換至近 30 天
- **GIVEN** 管理員正在查看頁面分析 tab
- **WHEN** 管理員點擊「近 30 天」篩選按鈕
- **THEN** 「近 30 天」按鈕 SHALL 呈現選中狀態
- **AND** 排行 SHALL 重新載入，顯示過去 30 天的頁面瀏覽統計

### Requirement: 頁面瀏覽資料聚合邏輯
系統 SHALL 從 `pageViews` 集合查詢指定時間範圍內的記錄，在 client 端按 `path` 欄位分組計數，排序後回傳前 N 名。聚合查詢 SHALL 使用 `limit(1000)` 控制單次讀取量。

#### Scenario: 按 path 分組計數
- **GIVEN** `pageViews` 集合中近 7 天有以下記錄：`"/"` 出現 50 次、`"/products/fruit"` 出現 30 次、`"/cart"` 出現 20 次
- **WHEN** 系統執行頁面排行查詢（近 7 天）
- **THEN** 排行第 1 名 SHALL 為 `"/"`（50 次）
- **AND** 排行第 2 名 SHALL 為 `"/products/fruit"`（30 次）
- **AND** 排行第 3 名 SHALL 為 `"/cart"`（20 次）

#### Scenario: 相同 path 但不同 title 時以最新 title 為準
- **GIVEN** `pageViews` 中 path 為 `"/"` 的記錄有多筆，title 分別為 `"首頁"` 和 `"山羽首頁"`
- **WHEN** 系統聚合頁面排行
- **THEN** path `"/"` 的 title SHALL 使用最近一筆記錄的 title 值

#### Scenario: 查詢結果超過 1000 筆時截斷
- **GIVEN** 指定時間範圍內 `pageViews` 記錄超過 1000 筆
- **WHEN** 系統查詢 pageViews 集合
- **THEN** SHALL 僅讀取最近的 1000 筆記錄進行聚合
- **AND** 排行結果可能不完全精確，但 SHALL 反映近期趨勢
