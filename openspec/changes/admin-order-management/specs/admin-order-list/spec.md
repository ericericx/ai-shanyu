## ADDED Requirements

### Requirement: Repository 提供後台訂單查詢方法
`OrdersAdminRepository` SHALL 提供以下方法：
- `watchOrders({OrderStatus? status, int limit})` → `Stream<List<OrderModel>>`：即時監聽訂單列表，支援按狀態篩選
- `watchOrderCount()` → `Stream<Map<OrderStatus, int>>`：即時監聽各狀態訂單數量

訂單 SHALL 按 `createdAt` 降序排列（最新在前）。

#### Scenario: 監聽所有訂單
- **WHEN** 呼叫 `watchOrders()` 不帶 status 參數
- **THEN** SHALL 回傳所有訂單的即時 Stream，按 createdAt 降序

#### Scenario: 按狀態篩選訂單
- **WHEN** 呼叫 `watchOrders(status: OrderStatus.pending)`
- **THEN** SHALL 僅回傳狀態為 pending 的訂單

#### Scenario: 分頁限制
- **WHEN** 呼叫 `watchOrders(limit: 20)`
- **THEN** SHALL 最多回傳 20 筆訂單

### Requirement: 後台訂單列表頁
後台 `/admin/orders` SHALL 顯示訂單列表，取代現有 Placeholder。

#### Scenario: 顯示訂單列表
- **WHEN** 管理員進入 `/admin/orders`
- **THEN** SHALL 顯示訂單列表，每筆包含：訂單編號（後 8 碼）、客戶姓名、商品件數、訂單金額、狀態標籤、建立日期
- **AND** 訂單按建立日期降序排列

#### Scenario: 訂單列表為空
- **WHEN** 無任何訂單（或篩選結果為空）
- **THEN** SHALL 顯示空狀態提示文字「目前沒有訂單」

### Requirement: 訂單狀態篩選
訂單列表 SHALL 提供狀態篩選功能。

#### Scenario: 顯示狀態篩選列
- **WHEN** 管理員檢視訂單列表
- **THEN** SHALL 在列表上方顯示狀態篩選 Chip 列：全部、待確認、已確認、處理中、已出貨、已送達、已取消
- **AND** 每個 Chip SHALL 顯示該狀態的訂單數量

#### Scenario: 點擊篩選 Chip
- **WHEN** 管理員點擊「待確認」Chip
- **THEN** 列表 SHALL 僅顯示狀態為 pending 的訂單
- **AND** 該 Chip SHALL 顯示為選中狀態

#### Scenario: 點擊「全部」Chip
- **WHEN** 管理員點擊「全部」Chip
- **THEN** 列表 SHALL 顯示所有狀態的訂單

### Requirement: 訂單狀態標籤樣式
每筆訂單的狀態 SHALL 以彩色標籤顯示，不同狀態使用不同顏色。

#### Scenario: 各狀態對應顏色
- **WHEN** 訂單狀態為 pending
- **THEN** 標籤 SHALL 顯示橘色底色與「待確認」文字
- **WHEN** 訂單狀態為 confirmed
- **THEN** 標籤 SHALL 顯示藍色底色與「已確認」文字
- **WHEN** 訂單狀態為 processing
- **THEN** 標籤 SHALL 顯示紫色底色與「處理中」文字
- **WHEN** 訂單狀態為 shipped
- **THEN** 標籤 SHALL 顯示綠色底色與「已出貨」文字
- **WHEN** 訂單狀態為 delivered
- **THEN** 標籤 SHALL 顯示灰色底色與「已送達」文字
- **WHEN** 訂單狀態為 cancelled
- **THEN** 標籤 SHALL 顯示紅色底色與「已取消」文字
