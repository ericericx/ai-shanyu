## Context

前台已有完整的訂單建立與訂單歷史功能。Firestore `orders` 集合儲存所有訂單，每筆包含 userId、items、shippingAddress、status、subtotal、shippingFee、total、note、createdAt。前台透過 Cloud Functions (`createOrder`、`getOrderHistory`) 操作訂單。後台目前 `/admin/orders` 為 Placeholder，管理員無法管理訂單。

現有程式碼資產：
- `OrderModel`、`OrderItemModel`、`ShippingAddress`、`OrderStatus` 已定義於 `features/orders/models/order_models.dart`
- `OrderStatus` 已含六種狀態與中文 label
- 後台架構採用 `features/admin/` 目錄，Repository + Riverpod Provider 模式

## Goals / Non-Goals

**Goals:**
- 後台管理員可查看所有客戶訂單
- 支援按狀態篩選與按時間排序
- 可檢視訂單完整詳情（商品、地址、金額）
- 可更新訂單狀態（含狀態流轉規則）

**Non-Goals:**
- 訂單建立或修改商品內容（由前台客戶操作）
- 退款或金流操作（金流尚未實作）
- 訂單匯出（CSV/Excel）
- 訂單通知（Email/SMS）

## Decisions

### D1：直接讀取 Firestore 而非新增 Cloud Function
**決策**：後台訂單讀取直接透過 Firestore SDK，不新增 Cloud Function。
**理由**：後台已有 admin 權限驗證（custom claims），直接讀取 Firestore 更簡潔，且可使用 StreamProvider 即時更新。現有 CRM、Products Admin 都採用此模式。

### D2：複用 OrderModel 而非新建 Admin 專用 Model
**決策**：直接複用 `features/orders/models/order_models.dart` 的 `OrderModel`。
**理由**：後台需要讀取的欄位與前台完全一致，無需額外欄位。避免重複定義。

### D3：狀態更新僅寫入 status 與 updatedAt
**決策**：狀態更新只修改 `status` 和 `updatedAt` 兩個欄位。
**理由**：保持最小寫入範圍，避免意外覆蓋其他欄位。

### D4：訂單詳情使用 Dialog 而非獨立頁面
**決策**：訂單詳情以 Dialog 呈現，與農產管理的內容編輯 Dialog 風格一致。
**理由**：保持後台操作一致性，管理員可快速查看後關閉繼續處理其他訂單。

## Risks / Trade-offs

- **[效能]** 訂單量大時列表載入可能變慢 → 使用分頁（每頁 20 筆）+ Firestore 索引
- **[權限]** 後台直接讀取 Firestore 需確保 Security Rules 正確 → 現有 rules 已限制 admin 角色
- **[並行]** 多個管理員同時更新同一訂單狀態 → Firestore 自動處理最後寫入，低頻場景可接受
