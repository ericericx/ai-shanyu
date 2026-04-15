## Context

結帳頁位於 `shanyu_app/lib/features/orders/presentation/checkout_page.dart`，目前流程為：顯示訂單摘要（唯讀購物車商品） → 填寫收件資訊 → 確認送出。送出後呼叫 Cloud Function `createOrder`，後端在 Firestore Transaction 中驗證庫存、計算金額、建立訂單、清空購物車。

現有程式碼資產：
- `OrderModel`（`order_models.dart`）已有 `status`、`shippingAddress`、`items`、`total` 等欄位，但無 `paymentMethod`
- `OrderRepository.createOrder`（`order_repository.dart`）傳送 items、shippingAddress、note 至後端
- Cloud Function `createOrder`（`functions/src/orders/createOrder.ts`）使用 Zod 驗證輸入，Transaction 內建立訂單文件
- 結帳頁使用 `_SectionCard` 共用元件做區塊劃分，設計 Token 集中於 `_CheckoutTokens`

## Goals / Non-Goals

**Goals:**
- 結帳頁新增「付款方式選擇」步驟，使用者必須選擇付款方式才能下單
- 支援三種付款方式：貨到付款（cod）、銀行轉帳（bankTransfer）、信用卡（creditCard）
- 每種付款方式顯示圖示、名稱與簡要說明文字
- 選擇的付款方式隨訂單一起寫入 Firestore
- 訂單歷史與後台管理可顯示付款方式資訊

**Non-Goals:**
- 實際金流串接（線上刷卡、銀行 API 等）
- 付款狀態追蹤（已付/未付/退款）
- 付款方式的後台管理（啟用/停用）
- 信用卡資訊輸入表單

## Decisions

### D1：結帳頁改為兩步驟流程
**決策**：將結帳頁拆分為 Step 1（收件資訊）與 Step 2（付款方式選擇），使用 Stepper 概念但以簡潔的區塊切換實作。
**理由**：步驟化流程讓使用者更清楚目前進度，也為未來新增更多步驟（如折扣碼、發票資訊）預留擴充性。不使用 Flutter 原生 `Stepper` widget，因其樣式較難客製化，改用自訂步驟指示器搭配區塊顯示/隱藏。

### D2：PaymentMethod 定義為 enum
**決策**：在 `order_models.dart` 新增 `PaymentMethod` enum，包含 `cod`、`bankTransfer`、`creditCard` 三個值。
**理由**：enum 提供型別安全，避免拼字錯誤。後端（TypeScript）使用 Zod `z.enum()` 對應驗證。Firestore 儲存為字串（enum 的 name）。

### D3：付款方式選擇使用 Radio Card 樣式
**決策**：每種付款方式以獨立卡片呈現，包含圖示（Icon）、名稱、說明文字，選中時顯示品牌色邊框與勾選標記。
**理由**：卡片式選擇比傳統 Radio Button 更直觀，觸控面積更大，適合手機操作。

### D4：paymentMethod 為必填欄位
**決策**：`createOrder` 的 `paymentMethod` 為必填，Zod schema 中使用 `z.enum()`，不接受空值。
**理由**：既然已加入付款方式步驟，所有新訂單都應記錄付款方式。舊訂單（無此欄位）讀取時 `OrderModel.paymentMethod` 為 `null`，前端顯示為「未指定」。

### D5：預設選擇貨到付款
**決策**：進入 Step 2 時，預設選中「貨到付款」。
**理由**：減少使用者操作步驟，貨到付款為最常見的付款方式。使用者仍可自由切換。

## Architecture

### PaymentMethod enum（order_models.dart）

```dart
enum PaymentMethod {
  cod,          // 貨到付款
  bankTransfer, // 銀行轉帳
  creditCard;   // 信用卡

  static PaymentMethod? fromString(String? value) {
    if (value == null) return null;
    return PaymentMethod.values.firstWhere(
      (m) => m.name == value,
      orElse: () => PaymentMethod.cod,
    );
  }

  String get label { ... }  // 中文名稱
  String get description { ... }  // 說明文字
  IconData get icon { ... }  // 圖示
}
```

### 結帳頁步驟流程

```
┌─────────────────────────────────┐
│        訂單摘要（始終顯示）        │
├─────────────────────────────────┤
│  Step 1: 收件資訊               │
│  [姓名] [電話] [地址] ...       │
│  [下一步 →]                     │
├─────────────────────────────────┤
│  Step 2: 付款方式選擇            │
│  ┌───────────────────────┐      │
│  │ 💰 貨到付款           │ ← 選中 │
│  │ 收到商品時以現金付款    │      │
│  └───────────────────────┘      │
│  ┌───────────────────────┐      │
│  │ 🏦 銀行轉帳           │      │
│  │ 下單後以 ATM 或網銀轉帳 │      │
│  └───────────────────────┘      │
│  ┌───────────────────────┐      │
│  │ 💳 信用卡             │      │
│  │ 使用信用卡線上付款      │      │
│  └───────────────────────┘      │
│  [← 上一步]    [確認送出訂單]    │
└─────────────────────────────────┘
```

### 資料流

1. 使用者在 Step 1 填寫收件資訊，點擊「下一步」觸發表單驗證
2. 驗證通過後進入 Step 2，選擇付款方式（預設：貨到付款）
3. 點擊「確認送出訂單」，前端呼叫 `OrderRepository.createOrder`，傳送 `paymentMethod` 字串
4. Cloud Function `createOrder` 驗證 `paymentMethod` 為有效值（`cod` / `bankTransfer` / `creditCard`）
5. Firestore Transaction 內建立訂單文件時寫入 `paymentMethod` 欄位

### Firestore 變更

`orders/{orderId}` 文件新增欄位：
- `paymentMethod`: `string`（`"cod"` | `"bankTransfer"` | `"creditCard"`）

## Risks / Trade-offs

- **[向後相容]** 舊訂單無 `paymentMethod` 欄位 → `OrderModel.fromMap` 處理為 `null`，前端顯示「未指定」
- **[UX]** 新增步驟增加結帳流程長度 → 步驟指示器讓使用者清楚進度，且 Step 2 僅需一次點選
- **[未來擴充]** 金流實際串接時需大幅修改 Step 2 → 目前的 Radio Card 架構可在選中信用卡時展開卡號輸入表單，擴充性佳
