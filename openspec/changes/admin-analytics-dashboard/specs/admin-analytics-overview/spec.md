## ADDED Requirements

### Requirement: 概覽統計卡片顯示四項關鍵指標
CRM 概覽 tab SHALL 顯示四張統計卡片，分別呈現今日瀏覽數、本月訂單數、本月營收、活躍用戶數。每張卡片 SHALL 包含指標名稱、數值與對應圖示。

#### Scenario: 管理員開啟 CRM 頁面時載入概覽統計
- **GIVEN** 管理員導航至 `/admin/crm` 頁面
- **WHEN** 頁面載入完成
- **THEN** 概覽 tab SHALL 預設顯示
- **AND** SHALL 呈現四張統計卡片：今日瀏覽數、本月訂單數、本月營收、活躍用戶數
- **AND** 每張卡片 SHALL 顯示對應的數值

#### Scenario: 統計資料載入中顯示 loading 狀態
- **GIVEN** 管理員開啟 CRM 頁面
- **WHEN** 概覽統計資料尚在查詢中
- **THEN** 卡片區塊 SHALL 顯示載入中指示器（CircularProgressIndicator）

#### Scenario: 統計資料載入失敗顯示錯誤訊息
- **GIVEN** Firestore 查詢失敗（網路錯誤或權限問題）
- **WHEN** 概覽統計無法取得資料
- **THEN** 概覽 tab SHALL 顯示錯誤訊息文字
- **AND** SHALL NOT 導致頁面崩潰

### Requirement: 今日瀏覽數統計
今日瀏覽數 SHALL 統計從今日 00:00（本地時間）起至目前為止，`pageViews` 集合中所有記錄的筆數。

#### Scenario: 今日有瀏覽記錄
- **GIVEN** `pageViews` 集合中今日有 150 筆記錄
- **WHEN** 概覽統計載入完成
- **THEN** 今日瀏覽數卡片 SHALL 顯示「150」

#### Scenario: 今日尚無瀏覽記錄
- **GIVEN** 今日尚未產生任何 `pageViews` 記錄（例如凌晨剛過）
- **WHEN** 概覽統計載入完成
- **THEN** 今日瀏覽數卡片 SHALL 顯示「0」

### Requirement: 本月訂單數統計
本月訂單數 SHALL 統計從本月 1 號 00:00 起至目前為止，`orders` 集合中所有訂單的筆數。

#### Scenario: 本月有訂單
- **GIVEN** `orders` 集合中本月有 42 筆訂單
- **WHEN** 概覽統計載入完成
- **THEN** 本月訂單數卡片 SHALL 顯示「42」

#### Scenario: 本月尚無訂單
- **GIVEN** 本月尚未產生任何訂單
- **WHEN** 概覽統計載入完成
- **THEN** 本月訂單數卡片 SHALL 顯示「0」

### Requirement: 本月營收統計
本月營收 SHALL 統計從本月 1 號 00:00 起至目前為止，`orders` 集合中所有訂單的 `total` 欄位加總。金額 SHALL 以新台幣格式顯示（例如「NT$ 12,500」）。

#### Scenario: 本月有營收
- **GIVEN** `orders` 集合中本月訂單總金額為 25800
- **WHEN** 概覽統計載入完成
- **THEN** 本月營收卡片 SHALL 顯示「NT$ 25,800」

#### Scenario: 本月尚無營收
- **GIVEN** 本月尚無訂單
- **WHEN** 概覽統計載入完成
- **THEN** 本月營收卡片 SHALL 顯示「NT$ 0」

### Requirement: 活躍用戶數統計
活躍用戶數 SHALL 統計從本月 1 號 00:00 起至目前為止，`pageViews` 集合中不重複的非 null `userId` 數量。匿名瀏覽（userId 為 null）SHALL NOT 計入活躍用戶數。

#### Scenario: 本月有多位活躍用戶
- **GIVEN** `pageViews` 集合中本月有 300 筆記錄，其中 userId 非 null 的不重複值有 18 個
- **WHEN** 概覽統計載入完成
- **THEN** 活躍用戶數卡片 SHALL 顯示「18」

#### Scenario: 本月僅有匿名瀏覽
- **GIVEN** `pageViews` 集合中本月所有記錄的 userId 皆為 null
- **WHEN** 概覽統計載入完成
- **THEN** 活躍用戶數卡片 SHALL 顯示「0」
