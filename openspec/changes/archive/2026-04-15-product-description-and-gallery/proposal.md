## Why

商品後台目前無法編輯描述（description）、品牌故事（story）與多張展示圖片（imageUrls）。前台 `ProductDetailModel` 已有這些欄位並能渲染，但後台 `AdminProductModel` 缺少 `story` 和 `imageUrls`，且無對應的編輯 UI。管理員需要在後台完整管理商品內容，包含文字描述與至多 5 張展示圖片。

## What Changes

- `AdminProductModel` 新增 `story` 和 `imageUrls` 欄位
- `ProductsAdminRepository` 新增 `updateProductContent` 方法，寫入 description、story、imageUrls
- 後台商品卡片新增「編輯內容」按鈕，開啟內容編輯 Dialog
- 內容編輯 Dialog 包含：description 文字欄、story 長文欄、多圖上傳區（至多 5 張，支援排序與刪除）
- 圖片上傳複用 `CmsAdminRepository.uploadImage`（含進度顯示）

## Capabilities

### New Capabilities
- `product-content-editor`: 後台商品內容編輯功能（描述、故事、多圖管理）

### Modified Capabilities

## Impact

- **檔案修改**：`AdminProductModel`（新增欄位）、`ProductsAdminRepository`（新增方法）、`products_admin_page.dart`（新增編輯 Dialog 與按鈕）
- **Firestore**：寫入 `products/{id}` 的 `description`、`story`、`imageUrls` 欄位（前台已可讀取，無需變更前台）
- **依賴**：複用 `CmsAdminRepository.uploadImage` 上傳圖片至 Storage
