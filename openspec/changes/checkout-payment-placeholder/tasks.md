## 1. Model 擴充（後端 + 前端）

- [ ] 1.1 在 `order_models.dart` 新增 `PaymentMethod` enum，包含 `cod`、`bankTransfer`、`creditCard` 三個值，各自提供 `label`（中文名稱）、`description`（說明文字）、`icon`（IconData）getter，以及 `fromString` 靜態方法
- [ ] 1.2 在 `OrderModel` 新增 `paymentMethod` 欄位（型別 `PaymentMethod?`），更新 `fromMap` 工廠方法從 Firestore 文件解析此欄位（舊訂單無此欄位時為 `null`）
- [ ] 1.3 在 `OrderRepository.createOrder` 方法新增 `paymentMethod` 參數（型別 `PaymentMethod`，必填），並將 `paymentMethod.name` 加入 Cloud Function 呼叫的 payload

## 2. 結帳頁 UI 改造（前端）

- [ ] 2.1 將結帳頁改為兩步驟流程：新增 `_currentStep` 狀態變數（0 = 收件資訊、1 = 付款方式），新增步驟指示器 UI 元件顯示目前步驟（Step 1/2）
- [ ] 2.2 Step 1 區塊：將「確認送出訂單」按鈕改為「下一步」按鈕，點擊時驗證表單，通過後切換至 Step 2
- [ ] 2.3 Step 2 區塊：建立付款方式選擇 UI，使用 `_SectionCard` 包裹，內含三張 Radio Card（貨到付款、銀行轉帳、信用卡），預設選中貨到付款，點擊切換選中狀態
- [ ] 2.4 Step 2 底部按鈕列：左側「上一步」按鈕返回 Step 1（保留已填資料），右側「確認送出訂單」按鈕觸發下單流程（含 paymentMethod）
- [ ] 2.5 調整 `_submitOrder` 方法：將選中的 `PaymentMethod` 傳入 `OrderRepository.createOrder`

## 3. Cloud Function 修改（後端）

- [ ] 3.1 在 `createOrder.ts` 的 `createOrderInputSchema` 新增 `paymentMethod: z.enum(["cod", "bankTransfer", "creditCard"])` 必填欄位
- [ ] 3.2 在 Firestore Transaction 建立 `orders/{orderId}` 文件時，將 `paymentMethod` 寫入文件
