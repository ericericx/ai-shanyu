## Context

前台 `ProductVariantModel` 對應 Firestore `products/{productId}/variants/{variantId}` 子集合，欄位包含 name、price、comparePrice、stock、unit、imageUrls、isPreorder、estimatedShipDate。前台商品詳情頁已能渲染 variant 列表並加入購物車。後台缺少 variant 管理能力。

## Goals / Non-Goals

**Goals:**
- 後台可對每個農產新增、編輯、刪除販售規格
- 規格列表即時同步 Firestore（使用 StreamProvider）
- 規格欄位：名稱、售價、原價（選填）、庫存、單位、是否預購

**Non-Goals:**
- 不處理 variant 附圖（imageUrls）管理，保持空列表
- 不處理預估出貨日（estimatedShipDate）編輯
- 不變更前台 UI

## Decisions

### 1. 入口：農產卡片新增「規格」按鈕

在現有三個按鈕（編輯狀態、編輯內容、農產時程）之後加第四個「販售規格」按鈕，開啟全功能的規格管理 Dialog。

### 2. 規格管理 Dialog 為單一 Dialog 內完成 CRUD

Dialog 內直接顯示規格列表，每個規格可展開編輯或刪除。新增規格在列表底部以表單形式加入。不另開子 Dialog，減少層級。

### 3. Repository 使用 Firestore 子集合直接操作

- `watchVariants(productId)` → Stream 監聯
- `createVariant(productId, data)` → add
- `updateVariant(productId, variantId, data)` → update
- `deleteVariant(productId, variantId)` → delete

### 4. 刪除規格需確認

刪除前彈出確認框，避免誤刪。

## Risks / Trade-offs

- **variant 刪除不影響已下單項目** → 購物車引用 variantId，刪除後購物車項目會顯示異常，但這是合理的業務行為（下架規格）
- **不處理 denormalized minPrice 更新** → `products/{id}.minPrice` 由 Cloud Functions 維護，後台不手動同步
