## ADDED Requirements

### Requirement: 結帳頁顯示付款方式選擇
結帳頁 SHALL 在收件資訊填寫完成後，顯示付款方式選擇步驟。

#### Scenario: 步驟化結帳流程
- **WHEN** 使用者進入結帳頁（`/orders/new`）
- **THEN** SHALL 顯示 Step 1「收件資訊」區塊
- **AND** SHALL 顯示步驟指示器（Step 1/2）
- **AND** Step 2「付款方式選擇」區塊 SHALL 尚未顯示

#### Scenario: 從 Step 1 前進到 Step 2
- **WHEN** 使用者在 Step 1 填寫完所有必填欄位，點擊「下一步」
- **THEN** SHALL 驗證表單欄位
- **AND** 驗證通過後 SHALL 切換至 Step 2「付款方式選擇」區塊
- **AND** 步驟指示器 SHALL 更新為 Step 2/2

#### Scenario: 表單驗證未通過時不前進
- **WHEN** 使用者在 Step 1 有必填欄位未填寫或格式錯誤，點擊「下一步」
- **THEN** SHALL 顯示對應的錯誤訊息
- **AND** SHALL 停留在 Step 1，不前進至 Step 2

#### Scenario: 從 Step 2 返回 Step 1
- **WHEN** 使用者在 Step 2 點擊「上一步」
- **THEN** SHALL 返回 Step 1「收件資訊」區塊
- **AND** 先前填寫的收件資訊 SHALL 保留不遺失

#### Scenario: 付款方式選項顯示
- **WHEN** 使用者進入 Step 2
- **THEN** SHALL 顯示三種付款方式選項卡片：
  - 貨到付款（`cod`）：圖示 `Icons.local_shipping`、說明「收到商品時以現金付款」
  - 銀行轉帳（`bankTransfer`）：圖示 `Icons.account_balance`、說明「下單後以 ATM 或網銀轉帳」
  - 信用卡（`creditCard`）：圖示 `Icons.credit_card`、說明「使用信用卡線上付款」
- **AND** 預設 SHALL 選中「貨到付款」

#### Scenario: 切換付款方式
- **WHEN** 使用者點擊某一付款方式卡片
- **THEN** 該卡片 SHALL 顯示選中狀態（品牌色邊框 + 勾選圖示）
- **AND** 先前選中的卡片 SHALL 取消選中狀態

### Requirement: 付款方式資料欄位
`OrderModel` SHALL 新增 `paymentMethod` 欄位，記錄使用者選擇的付款方式。

#### Scenario: PaymentMethod enum 定義
- **GIVEN** 系統定義 `PaymentMethod` enum
- **THEN** SHALL 包含以下值：
  - `cod`（貨到付款）
  - `bankTransfer`（銀行轉帳）
  - `creditCard`（信用卡）
- **AND** 每個值 SHALL 提供中文 `label`、`description` 說明文字與 `icon` 圖示

#### Scenario: OrderModel 包含 paymentMethod
- **GIVEN** `OrderModel` 資料模型
- **THEN** SHALL 包含 `paymentMethod` 欄位，型別為 `PaymentMethod?`（可為 null）
- **AND** `fromMap` 工廠方法 SHALL 從 Firestore 文件的 `paymentMethod` 字串欄位解析
- **AND** 若 Firestore 文件無 `paymentMethod` 欄位（舊訂單），SHALL 解析為 `null`

#### Scenario: 前端 Repository 傳送 paymentMethod
- **GIVEN** `OrderRepository.createOrder` 方法
- **THEN** SHALL 新增 `paymentMethod` 參數（型別 `PaymentMethod`，必填）
- **AND** 呼叫 Cloud Function 時 SHALL 將 `paymentMethod.name` 字串包含於 payload 中

### Requirement: 訂單建立時記錄付款方式
Cloud Function `createOrder` SHALL 接受並儲存付款方式。

#### Scenario: Zod schema 驗證 paymentMethod
- **GIVEN** `createOrder` Cloud Function 的輸入驗證
- **THEN** `createOrderInputSchema` SHALL 新增 `paymentMethod` 欄位
- **AND** SHALL 使用 `z.enum(["cod", "bankTransfer", "creditCard"])` 驗證
- **AND** `paymentMethod` SHALL 為必填欄位

#### Scenario: paymentMethod 無效值
- **WHEN** 客戶端傳送 `paymentMethod` 為無效值（如空字串、`"bitcoin"`）
- **THEN** SHALL 回傳 `invalid-argument` 錯誤
- **AND** 錯誤訊息 SHALL 包含格式錯誤說明

#### Scenario: paymentMethod 寫入 Firestore
- **WHEN** `createOrder` 驗證通過並執行 Firestore Transaction
- **THEN** `orders/{orderId}` 文件 SHALL 包含 `paymentMethod` 欄位
- **AND** 欄位值 SHALL 為客戶端傳送的有效付款方式字串（`"cod"` / `"bankTransfer"` / `"creditCard"`）

#### Scenario: 確認送出訂單包含付款方式
- **WHEN** 使用者在 Step 2 選擇付款方式後點擊「確認送出訂單」
- **THEN** SHALL 呼叫 `OrderRepository.createOrder` 並傳送所選的 `paymentMethod`
- **AND** 成功後 SHALL 導向訂單成功頁（`/orders/success/{orderId}`）
- **AND** 購物車 SHALL 被清空
