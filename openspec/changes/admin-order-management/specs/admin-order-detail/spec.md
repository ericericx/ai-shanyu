## ADDED Requirements

### Requirement: 訂單詳情 Dialog
管理員 SHALL 可點擊訂單列表中的任一訂單，開啟訂單詳情 Dialog。

#### Scenario: 開啟訂單詳情
- **WHEN** 管理員點擊訂單列表中的某筆訂單
- **THEN** SHALL 開啟 Dialog 顯示完整訂單資訊

#### Scenario: 顯示訂單基本資訊
- **WHEN** 訂單詳情 Dialog 開啟
- **THEN** SHALL 顯示：訂單編號、建立日期時間、目前狀態標籤、備註（如有）

#### Scenario: 顯示商品明細
- **WHEN** 訂單詳情 Dialog 開啟
- **THEN** SHALL 列出所有訂單商品，每筆顯示：商品名稱、規格名稱、單價、數量、小計
- **AND** 預購商品 SHALL 標示「預購」標籤與預估出貨日

#### Scenario: 顯示收件地址
- **WHEN** 訂單詳情 Dialog 開啟
- **THEN** SHALL 顯示收件人姓名、電話、完整地址（郵遞區號 + 縣市 + 地址）

#### Scenario: 顯示金額摘要
- **WHEN** 訂單詳情 Dialog 開啟
- **THEN** SHALL 顯示商品小計、運費、訂單總計

### Requirement: 訂單狀態更新
管理員 SHALL 可在訂單詳情 Dialog 中更新訂單狀態。

#### Scenario: 顯示可用的下一個狀態
- **WHEN** 訂單目前狀態為 pending
- **THEN** SHALL 顯示「確認訂單」和「取消訂單」按鈕
- **WHEN** 訂單目前狀態為 confirmed
- **THEN** SHALL 顯示「開始處理」和「取消訂單」按鈕
- **WHEN** 訂單目前狀態為 processing
- **THEN** SHALL 顯示「已出貨」和「取消訂單」按鈕
- **WHEN** 訂單目前狀態為 shipped
- **THEN** SHALL 顯示「已送達」按鈕
- **WHEN** 訂單狀態為 delivered 或 cancelled
- **THEN** SHALL 不顯示狀態更新按鈕（終態）

#### Scenario: 更新訂單狀態
- **WHEN** 管理員點擊狀態更新按鈕
- **THEN** SHALL 彈出確認框，確認後更新 Firestore `orders/{orderId}` 的 `status` 和 `updatedAt` 欄位
- **AND** Dialog 中的狀態標籤 SHALL 即時更新

#### Scenario: 取消訂單需二次確認
- **WHEN** 管理員點擊「取消訂單」
- **THEN** SHALL 彈出警告確認框，文字標示「取消後無法恢復」
- **AND** 確認後 status SHALL 更新為 cancelled

### Requirement: Repository 提供訂單狀態更新方法
`OrdersAdminRepository` SHALL 提供 `updateOrderStatus(orderId, newStatus)` 方法。

#### Scenario: 更新狀態成功
- **WHEN** 呼叫 `updateOrderStatus('abc123', OrderStatus.confirmed)`
- **THEN** Firestore `orders/abc123` 的 `status` SHALL 更新為 'confirmed'
- **AND** `updatedAt` SHALL 更新為伺服器時間戳
