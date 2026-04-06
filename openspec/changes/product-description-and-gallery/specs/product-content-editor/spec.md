## ADDED Requirements

### Requirement: AdminProductModel 包含 story 與 imageUrls 欄位
`AdminProductModel` SHALL 包含 `story`（String?）與 `imageUrls`（List<String>）欄位，從 Firestore 讀取。

#### Scenario: 讀取含 story 與 imageUrls 的商品
- **WHEN** Firestore 文件包含 `story` 和 `imageUrls` 欄位
- **THEN** `AdminProductModel.fromFirestore` SHALL 正確解析這兩個欄位

#### Scenario: 讀取無 story 與 imageUrls 的舊商品
- **WHEN** Firestore 文件缺少 `story` 或 `imageUrls` 欄位
- **THEN** `story` SHALL 預設為空字串，`imageUrls` SHALL 預設為空列表

### Requirement: 後台可更新商品描述、故事與圖片
`ProductsAdminRepository` SHALL 提供 `updateProductContent` 方法，接受 `id`、`description`、`story`、`imageUrls`、`coverImageUrl` 參數，寫入 Firestore。

#### Scenario: 更新商品內容
- **WHEN** 管理員呼叫 `updateProductContent`
- **THEN** Firestore `products/{id}` 的 `description`、`story`、`imageUrls`、`coverImageUrl`、`updatedAt` 欄位 SHALL 被更新

### Requirement: 後台可上傳商品圖片
`ProductsAdminRepository` SHALL 提供 `uploadProductImage` 方法，將圖片上傳至 Firebase Storage `products/` 路徑，支援進度回呼，回傳下載 URL。

#### Scenario: 上傳商品圖片並取得 URL
- **WHEN** 管理員上傳一張圖片
- **THEN** 圖片 SHALL 儲存至 `products/<fileName>`，方法 SHALL 回傳公開下載 URL

### Requirement: 商品卡片顯示「內容」編輯按鈕
後台商品卡片 SHALL 在「狀態」「時程」按鈕之外新增「內容」按鈕。

#### Scenario: 點擊「內容」按鈕
- **WHEN** 管理員點擊商品卡片上的「內容」按鈕
- **THEN** SHALL 開啟內容編輯 Dialog

### Requirement: 內容編輯 Dialog
Dialog SHALL 包含以下欄位：
- 商品描述（TextFormField，1–3 行）
- 品牌故事（TextFormField，5+ 行，可展開）
- 展示圖片區（顯示已上傳圖片，支援新增、刪除、排序）

#### Scenario: 編輯描述與故事
- **WHEN** 管理員修改描述或故事文字並點擊儲存
- **THEN** SHALL 將更新寫入 Firestore

#### Scenario: 新增展示圖片
- **WHEN** 管理員點擊新增圖片按鈕並選擇檔案
- **THEN** 圖片 SHALL 上傳並顯示進度，完成後加入圖片列表

#### Scenario: 圖片數量上限
- **WHEN** 已有 5 張展示圖片
- **THEN** 新增圖片按鈕 SHALL 被停用，顯示「已達上限」

#### Scenario: 刪除展示圖片
- **WHEN** 管理員點擊某張圖片的刪除按鈕
- **THEN** 該圖片 SHALL 從列表中移除（儲存後生效）

#### Scenario: 排序展示圖片
- **WHEN** 管理員點擊上移或下移按鈕
- **THEN** 該圖片 SHALL 在列表中交換位置（儲存後生效）

### Requirement: 選擇預覽圖（coverImageUrl）
內容編輯 Dialog 的圖片列表中，每張圖片 SHALL 可被指定為商品預覽圖（coverImageUrl）。

#### Scenario: 指定預覽圖
- **WHEN** 管理員點擊某張圖片的「設為預覽圖」按鈕
- **THEN** 該圖片 SHALL 被標記為預覽圖，卡片上顯示星號或標籤區分
- **AND** 儲存時 `coverImageUrl` SHALL 更新為該圖片的 URL

#### Scenario: 未選擇預覽圖時使用 placeholder
- **WHEN** 商品沒有任何展示圖片，或未指定預覽圖
- **THEN** 商品卡片與前台 SHALL 顯示農產品籃子 placeholder 圖片（`assets/images/product_placeholder.png`）

#### Scenario: 預覽圖隨圖片刪除自動清除
- **WHEN** 管理員刪除了被指定為預覽圖的圖片
- **THEN** `coverImageUrl` SHALL 自動清空，回退為 placeholder

### Requirement: 圖片上傳建議尺寸標示
圖片上傳區 SHALL 標示建議尺寸：「建議比例 1:1（例如 800×800 px）」。

#### Scenario: 上傳區顯示建議尺寸
- **WHEN** 管理員檢視圖片上傳區
- **THEN** SHALL 顯示建議尺寸提示文字

### Requirement: 圖片預覽器
在內容編輯 Dialog 中，管理員 SHALL 可點擊圖片縮圖開啟全尺寸預覽。

#### Scenario: 點擊縮圖預覽
- **WHEN** 管理員點擊某張圖片縮圖
- **THEN** SHALL 開啟全螢幕覆蓋式預覽，顯示完整圖片
- **AND** 點擊背景或關閉按鈕 SHALL 關閉預覽
