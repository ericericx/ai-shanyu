# Tasks: navbar-dynamic-categories

## 任務列表

### T-BF-01：移除硬編碼分類常數並接入 `categoriesProvider`

**負責**：flutter-artisan
**狀態**：done

**描述**：

修改 `shanyu_app/lib/shared/widgets/app_nav_bar.dart`，完成以下所有變更：

1. 新增 import：
   - `../../features/products/models/category_model.dart`
   - `../../features/products/providers/product_providers.dart`

2. 刪除 `_NavCategory` 類別（第 35–40 行）與 `_kNavCategories` 常數（第 42–46 行）。

3. 修改 `_NavCategoryLink`：
   - `category` 欄位型別由 `_NavCategory` 改為 `CategoryModel`
   - `widget.category.categoryId` 改為 `widget.category.id`
   - `widget.category.label` 改為 `widget.category.name`

4. 修改 `AppNavBar.build()` 中的桌機分類連結區塊：
   - 移除 `..._kNavCategories.map(...)` 靜態渲染
   - 改為 `ref.watch(categoriesProvider).when(loading/error/data)` 動態渲染
   - `data` callback：對 categories 依 `sortOrder` 升冪排序後，以 `Row` 渲染所有 `_NavCategoryLink`
   - `loading` 與 `error` callback：返回 `SizedBox.shrink()`
   - `SizedBox(width: 16)` 的間距僅在有分類時加入

**驗收標準**：

- [x] 編譯無錯誤、無警告
- [x] `_NavCategory` 類別與 `_kNavCategories` 常數已完全移除
- [x] `_NavCategoryLink.category` 型別為 `CategoryModel`
- [x] `AppNavBar` 使用 `ref.watch(categoriesProvider).when(...)` 渲染分類
- [x] 手機版（`isDesktop == false`）行為不變
- [x] 完成後立即 git commit（commit message 格式：`fix(T-BF-01): NavBar 分類連結改為動態載入`）

**相依**：無

---

## 歸檔資訊

- **歸檔日期**：2026-03-30
- **commit**：`fix(T-BF-01): NavBar 分類連結改為動態載入`
- **驗證結果**：全部 PASS（S-01、S-02、S-03、T-BF-01 驗收標準）
- **實作 Agent**：flutter-artisan
