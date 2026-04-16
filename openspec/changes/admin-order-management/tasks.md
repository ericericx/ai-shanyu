## 1. Repository 與 Provider

- [x] 1.1 建立 `orders_admin_repository.dart`，包含 `watchOrders`（支援 status 篩選與 limit）、`watchOrderCount`、`updateOrderStatus` 方法
- [x] 1.2 建立 `orders_admin_providers.dart`，包含 repository provider、訂單列表 StreamProvider、訂單數量 StreamProvider

## 2. 訂單列表頁

- [x] 2.1 建立 `orders_admin_page.dart`，替換 router 中的 Placeholder，顯示訂單列表
- [x] 2.2 實作狀態篩選 Chip 列（全部 + 六種狀態），每個 Chip 顯示訂單數量
- [x] 2.3 實作訂單卡片/列表項：訂單編號（後 8 碼）、客戶姓名、商品件數、金額、狀態標籤、日期
- [x] 2.4 實作狀態標籤彩色樣式（pending 橘/confirmed 藍/processing 紫/shipped 綠/delivered 灰/cancelled 紅）
- [x] 2.5 實作空狀態提示與載入中狀態

## 3. 訂單詳情 Dialog

- [x] 3.1 建立訂單詳情 Dialog：顯示訂單基本資訊（編號、日期、狀態、備註）
- [x] 3.2 顯示商品明細列表（名稱、規格、單價、數量、小計、預購標示）
- [x] 3.3 顯示收件地址區塊（姓名、電話、完整地址）
- [x] 3.4 顯示金額摘要（小計、運費、總計）

## 4. 訂單狀態更新

- [x] 4.1 實作狀態更新按鈕（依目前狀態顯示可用的下一步操作）
- [x] 4.2 實作確認框與取消訂單的二次警告確認
- [x] 4.3 串接 `updateOrderStatus` 儲存至 Firestore，Dialog 狀態即時更新
