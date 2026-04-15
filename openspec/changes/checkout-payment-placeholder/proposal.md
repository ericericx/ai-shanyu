## Why

目前結帳流程（`/orders/new`）僅包含「收件資訊填寫」與「確認送出」兩個環節，缺少付款方式選擇步驟。未來串接金流（信用卡線上付款、銀行轉帳等）時，需要此 UI 基礎設施已就位，才能快速對接。現階段先建立付款方式選擇的 UI 與資料欄位，實際金流串接留待後續階段處理。

## What Changes

- **結帳頁改為兩步驟流程**：Step 1 收件資訊 → Step 2 付款方式選擇 → 確認下單
- **OrderModel 新增 `paymentMethod` 欄位**：記錄使用者選擇的付款方式（`cod`、`bankTransfer`、`creditCard`）
- **Cloud Function `createOrder` 擴充**：接受並儲存 `paymentMethod` 參數，寫入 Firestore `orders` 文件
- **前端 `OrderRepository.createOrder` 擴充**：傳送 `paymentMethod` 至後端

## Capabilities

### New Capabilities
- `checkout-payment-method`: 結帳頁付款方式選擇（UI + 資料記錄）

### Modified Capabilities
（無）

## Impact

- **修改檔案**：
  - `shanyu_app/lib/features/orders/presentation/checkout_page.dart` — 新增付款方式選擇步驟 UI
  - `shanyu_app/lib/features/orders/models/order_models.dart` — 新增 `PaymentMethod` enum 與 `OrderModel.paymentMethod` 欄位
  - `shanyu_app/lib/features/orders/data/order_repository.dart` — `createOrder` 新增 `paymentMethod` 參數
  - `functions/src/orders/createOrder.ts` — Zod schema 新增 `paymentMethod` 驗證，寫入 Firestore
- **Firestore**：`orders/{orderId}` 文件新增 `paymentMethod` 字串欄位
- **向後相容**：既有訂單無 `paymentMethod` 欄位，讀取時預設為 `null`（不影響現有功能）
