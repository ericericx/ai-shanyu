## ADDED Requirements

### Requirement: Repository 提供 variant CRUD 方法
`ProductsAdminRepository` SHALL 提供以下方法操作 `products/{productId}/variants` 子集合：
- `watchVariants(productId)` → `Stream<List<AdminVariantModel>>`
- `createVariant(productId, {...})` → 新增文件
- `updateVariant(productId, variantId, {...})` → 更新文件
- `deleteVariant(productId, variantId)` → 刪除文件

`AdminVariantModel` SHALL 包含欄位：id、name、price、comparePrice、stock、unit、isPreorder。

#### Scenario: 監聽規格列表
- **WHEN** 呼叫 `watchVariants(productId)`
- **THEN** SHALL 回傳即時同步的 variant 列表 Stream

#### Scenario: 新增規格
- **WHEN** 呼叫 `createVariant` 並傳入 name、price、stock、unit
- **THEN** SHALL 在 Firestore 子集合新增文件，含 createdAt 時間戳

#### Scenario: 更新規格
- **WHEN** 呼叫 `updateVariant` 並傳入修改欄位
- **THEN** SHALL 更新對應文件，含 updatedAt 時間戳

#### Scenario: 刪除規格
- **WHEN** 呼叫 `deleteVariant`
- **THEN** SHALL 刪除對應文件

### Requirement: 農產卡片顯示「販售規格」按鈕
後台農產卡片 SHALL 在現有按鈕之後新增「販售規格」按鈕。

#### Scenario: 點擊「販售規格」
- **WHEN** 管理員點擊農產卡片上的「販售規格」按鈕
- **THEN** SHALL 開啟規格管理 Dialog

### Requirement: 規格管理 Dialog
Dialog SHALL 顯示該農產的所有販售規格列表，並支援新增、編輯、刪除。

#### Scenario: 顯示現有規格
- **WHEN** 開啟規格管理 Dialog
- **THEN** SHALL 列出所有規格，每筆顯示名稱、售價、庫存、單位

#### Scenario: 新增規格
- **WHEN** 管理員填寫名稱、售價、庫存、單位並點擊新增
- **THEN** SHALL 即時寫入 Firestore，列表自動更新

#### Scenario: 編輯規格
- **WHEN** 管理員點擊某規格的編輯按鈕
- **THEN** SHALL 展開為可編輯表單，修改後可儲存

#### Scenario: 刪除規格
- **WHEN** 管理員點擊某規格的刪除按鈕
- **THEN** SHALL 彈出確認框，確認後刪除

#### Scenario: 規格欄位驗證
- **WHEN** 名稱為空或售價 <= 0
- **THEN** SHALL 顯示驗證錯誤，不允許儲存

### Requirement: 規格欄位定義
每個規格 SHALL 包含以下可編輯欄位：
- **名稱**（必填）：如「4兩」「半斤」「2粒裝」
- **售價**（必填，正整數）：新台幣
- **原價**（選填）：顯示刪除線用
- **庫存數量**（必填，>= 0）
- **計量單位**（必填）：如「罐」「盒」「斤」「包」
- **是否預購**（布林，預設 false）

#### Scenario: 新增含所有欄位的規格
- **WHEN** 管理員填寫名稱「4兩」、售價 800、庫存 50、單位「罐」
- **THEN** SHALL 成功建立規格，前台可立即顯示

#### Scenario: 設定預購規格
- **WHEN** 管理員勾選「預購」
- **THEN** 該規格 SHALL 標記為 isPreorder = true，庫存為 0 時前台仍可下單
