## Why

後台 `/admin/orders` 目前僅為 Placeholder 頁面，管理員無法查看客戶訂單、追蹤訂單狀態或更新出貨進度。前台已有完整的下單與訂單歷史功能，Firestore `orders` 集合也已儲存完整訂單資料，但後台缺少對應的管理介面。

## What Changes

- 新建 `OrdersAdminRepository` 提供後台訂單查詢與狀態更新方法（直接讀寫 Firestore，不經 Cloud Functions）
- 新建後台訂單列表頁，支援按狀態篩選、按日期排序、分頁載入
- 新建訂單詳情 Dialog，顯示完整訂單資訊（商品明細、收件地址、備註、時間軸）
- 管理員可更新訂單狀態（pending → confirmed → processing → shipped → delivered，或任意狀態 → cancelled）
- 訂單列表顯示狀態標籤、金額、商品件數、建立日期

## Capabilities

### New Capabilities
- `admin-order-list`: 後台訂單列表（篩選、排序、分頁）
- `admin-order-detail`: 後台訂單詳情檢視與狀態更新

### Modified Capabilities

## Impact

- **新增檔案**：`orders_admin_repository.dart`、`orders_admin_page.dart`、admin order providers
- **修改檔案**：`app_router.dart`（將 Placeholder 替換為實際頁面）
- **Firestore**：讀取 `orders` 集合（全部訂單）、寫入 `status` 欄位
- **現有模型**：複用 `OrderModel`、`OrderItemModel`、`ShippingAddress`、`OrderStatus`
