## Context

前台 `ProductDetailModel` 已有 `description`、`story`、`imageUrls` 欄位，前台商品詳情頁也已能渲染這些內容。但後台 `AdminProductModel` 缺少 `story` 和 `imageUrls`，且商品管理頁無對應的編輯 UI，管理員目前無法在後台填寫這些資料。

## Goals / Non-Goals

**Goals:**
- 後台可編輯商品的描述、故事、展示圖片（至多 5 張）
- 圖片支援上傳、刪除、拖曳排序
- 上傳時顯示進度

**Non-Goals:**
- 不變更前台 `ProductDetailModel` 或商品詳情頁（已支援）
- 不處理圖片裁切或壓縮
- 不新增 Cloud Functions

## Decisions

### 1. 編輯入口：商品卡片新增「內容」按鈕

在現有的「狀態」「時程」按鈕旁新增第三個「內容」按鈕，點擊開啟 `_EditContentDialog`。卡片 grid 的 `childAspectRatio` 需調整以容納三個按鈕。

### 2. 圖片上傳複用 CmsAdminRepository

`CmsAdminRepository.uploadImage` 已支援進度回呼，路徑改為 `products/<productId>/<uuid>_<filename>` 以區分 CMS 圖片。在 `ProductsAdminRepository` 新增 `uploadProductImage` 方法代理呼叫，或直接在 Dialog 中使用 Firebase Storage。

**決定**：在 `ProductsAdminRepository` 新增 `uploadProductImage` 方法，路徑為 `products/<fileName>`，保持與 CMS 上傳一致的 pattern。

### 3. 圖片排序使用上下箭頭

與 Banner 管理一致，使用上移/下移按鈕而非拖曳排序，避免 `ReorderableListView` 的已知 bug。

### 4. imageUrls 儲存格式

直接存為 Firestore Array（`List<String>`），與前台 `ProductDetailModel.fromFirestore` 讀取方式一致。

### 5. 預覽圖選擇機制

`coverImageUrl` 從 `imageUrls` 中選擇一張。圖片列表每張旁邊顯示「星號」按鈕，點擊即設為預覽圖。若刪除被選為預覽圖的圖片，`coverImageUrl` 自動清空。無圖或未選擇時，商品卡片與前台顯示 `assets/images/product_placeholder.png`（農產品籃子插圖）。

### 6. 圖片預覽器

點擊縮圖開啟全螢幕覆蓋式預覽（`showDialog` + `InteractiveViewer`），可縮放查看完整圖片，點擊背景或 X 按鈕關閉。

### 7. 圖片建議尺寸

上傳區標示「建議比例 1:1（例如 800×800 px）」，與商品列表卡片和前台詳情頁的正方形展示一致。

## Risks / Trade-offs

- **圖片刪除不清 Storage** → 目前不實作 Storage 檔案刪除（orphan files），未來可加排程清理
- **5 張上限為前端驗證** → 不在 Security Rules 強制，信任後台管理員
- **placeholder 為本地 asset** → 打包在 app 中，不依賴網路
