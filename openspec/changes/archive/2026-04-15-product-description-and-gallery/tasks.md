## 1. Model 與 Repository

- [x] 1.1 `AdminProductModel` 新增 `story`（String）與 `imageUrls`（List<String>）欄位，含 fromFirestore 解析
- [x] 1.2 `ProductsAdminRepository` 新增 `updateProductContent` 方法（description、story、imageUrls、coverImageUrl）
- [x] 1.3 `ProductsAdminRepository` 新增 `uploadProductImage` 方法（含 onProgress 回呼）

## 2. 資源準備

- [x] 2.1 將農產品籃子 placeholder 圖片加入 `assets/images/product_placeholder.png`，商品卡片無圖時使用

## 3. 後台 UI

- [x] 3.1 商品卡片新增第三個「內容」按鈕，調整 grid aspectRatio 與按鈕列為三欄；無圖時顯示 placeholder
- [x] 3.2 建立 `_EditContentDialog`：描述欄、故事欄、圖片管理區
- [x] 3.3 圖片管理區：顯示已上傳圖片縮圖列表，支援上移/下移/刪除，標示建議尺寸「1:1（800×800 px）」
- [x] 3.4 圖片管理區：新增圖片按鈕（至多 5 張限制）、上傳進度顯示
- [x] 3.5 圖片管理區：每張圖片可「設為預覽圖」，標記星號；刪除預覽圖時自動清空 coverImageUrl
- [x] 3.6 圖片管理區：點擊縮圖開啟全螢幕預覽器（覆蓋式，點擊背景關閉）
- [x] 3.7 串接 `_showEditContentDialog` 呼叫 `updateProductContent` 儲存（含 coverImageUrl）
