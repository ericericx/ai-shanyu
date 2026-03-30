# Design: navbar-dynamic-categories

## 架構決策

### 使用現有 `categoriesProvider`

`categoriesProvider` 已定義於 `product_providers.dart`，型別為 `AsyncValue<List<CategoryModel>>`（Riverpod code-gen stream provider）。`AppNavBar` 是 `ConsumerWidget`，可直接 `ref.watch(categoriesProvider)`，無需任何新增 Provider。

### `_NavCategory` 類別的處置

舊的 `_NavCategory` 私有類別（`label` + `categoryId`）是為了承載硬編碼資料而存在的輕量 DTO。改用動態資料後，直接操作 `CategoryModel` 即可，`_NavCategory` 類別與 `_kNavCategories` 常數一併刪除。

### 排序策略

`categoriesProvider` 返回的 `List<CategoryModel>` 順序取決於 Firestore query 排序。為確保前端排序穩定，在渲染前於 Widget 層執行 `sortedCategories = [...categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))`，不依賴 query 排序。

## 資料流

```
Firestore `categories` 集合
    │
    ▼
ProductRepository.watchCategories()   (Stream<List<CategoryModel>>)
    │
    ▼
categoriesProvider                    (AsyncValue<List<CategoryModel>>)
    │
    ▼
AppNavBar.build()  →  ref.watch(categoriesProvider).when(...)
    │
    ▼
_NavCategoryLink（每個 CategoryModel 一個）
```

## 變更範疇（Diff 摘要）

### 刪除

```dart
// 刪除整個 _NavCategory 類別
class _NavCategory { ... }

// 刪除硬編碼常數
const _kNavCategories = [ ... ];
```

### 修改：`AppNavBar.build()`

原本：
```dart
if (isDesktop) ...[
  ..._kNavCategories.map(
    (cat) => _NavCategoryLink(category: cat),
  ),
  const SizedBox(width: 16),
],
```

改為：
```dart
if (isDesktop) ...[
  ref.watch(categoriesProvider).when(
    loading: () => const SizedBox.shrink(),
    error: (_, __) => const SizedBox.shrink(),
    data: (categories) {
      final sorted = [...categories]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...sorted.map((cat) => _NavCategoryLink(category: cat)),
          if (sorted.isNotEmpty) const SizedBox(width: 16),
        ],
      );
    },
  ),
],
```

### 修改：`_NavCategoryLink`

將 `category` 型別從 `_NavCategory` 改為 `CategoryModel`，並更新對應的 `.label` → `.name`、`.categoryId` → `.id`。

### 新增 Import

```dart
import '../../features/products/models/category_model.dart';
import '../../features/products/providers/product_providers.dart';
```

## 影響評估

| 項目 | 影響 |
|------|------|
| 其他 Widget | 無 |
| Router | 無（路由格式不變） |
| Providers | 無（僅新增 watch，不修改） |
| Models | 無（僅新增 import，不修改） |
| 測試 | 若有 AppNavBar widget test 需更新 mock |
