## Why

農產品有不同販售規格（如春茶 4兩/半斤/1斤、雪梨 2粒裝/5粒裝），每種規格有獨立定價與庫存。前台 `ProductVariantModel` 已完整支援（name、price、comparePrice、stock、unit、isPreorder），資料存於 Firestore `products/{id}/variants/{variantId}` 子集合。但後台完全沒有規格管理 UI，管理員無法新增、編輯或刪除販售規格。

## What Changes

- `ProductsAdminRepository` 新增 variant CRUD 方法（watchVariants、createVariant、updateVariant、deleteVariant）
- 後台農產卡片新增「規格」按鈕，開啟規格管理 Dialog
- 規格管理 Dialog：列出現有規格、新增/編輯/刪除規格
- 每個規格可設定：名稱（如「4兩」）、售價、原價（選填）、庫存數量、計量單位（如「罐」「盒」「斤」）、是否預購

## Capabilities

### New Capabilities
- `product-variant-crud`: 後台農產販售規格的完整 CRUD 管理

### Modified Capabilities

## Impact

- **檔案修改**：`ProductsAdminRepository`（新增 variant 方法）、`products_admin_page.dart`（新增規格按鈕與 Dialog）
- **Firestore**：讀寫 `products/{id}/variants` 子集合（結構與前台 `ProductVariantModel` 一致）
- **前台**：無需變更，已可讀取 variants
