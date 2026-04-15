## 1. Model 與 Repository

- [x] 1.1 在 `products_admin_repository.dart` 新增 `AdminVariantModel` 類別（id、name、price、comparePrice、stock、unit、isPreorder）含 fromFirestore
- [x] 1.2 `ProductsAdminRepository` 新增 `watchVariants`、`createVariant`、`updateVariant`、`deleteVariant` 四個方法

## 2. 後台 UI

- [x] 2.1 農產卡片新增第四個「販售規格」按鈕，串接 `_showVariantsDialog`
- [x] 2.2 建立 `_VariantsDialog`：使用 StreamProvider 即時顯示規格列表
- [x] 2.3 規格列表每筆顯示名稱、售價、庫存、單位，附編輯/刪除按鈕
- [x] 2.4 新增規格表單：名稱、售價、原價（選填）、庫存、單位、是否預購，含驗證
- [x] 2.5 編輯規格：點擊編輯展開為可編輯表單，儲存後更新 Firestore
- [x] 2.6 刪除規格：確認框後刪除
