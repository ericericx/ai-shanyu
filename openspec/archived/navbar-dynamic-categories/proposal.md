# Proposal: navbar-dynamic-categories

## 問題描述

`AppNavBar` 的分類導覽連結使用 `const _kNavCategories = [...]` 硬編碼三筆資料（梨山茶、水蜜桃、梨子）。這導致兩個 Bug：

1. **Bug 1**：即使 Firestore 中沒有任何分類，NavBar 仍固定顯示三個連結。
2. **Bug 2**：透過後台 CMS 新增或刪除分類後，NavBar 不會即時更新，因為分類資料從不從 Firestore 讀取。

## 根本原因

`shanyu_app/lib/shared/widgets/app_nav_bar.dart` 第 42–46 行：

```dart
const _kNavCategories = [
  _NavCategory(label: '梨山茶', categoryId: 'lishan-tea'),
  _NavCategory(label: '水蜜桃', categoryId: 'peach'),
  _NavCategory(label: '梨子', categoryId: 'pear'),
];
```

此常數從未被替換為動態資料源。`categoriesProvider`（`Stream<List<CategoryModel>>`）早已存在於 `product_providers.dart`，只需在 `AppNavBar` 中 `ref.watch` 即可。

## 提案目標

將 `AppNavBar` 的分類連結改為從 `categoriesProvider` 動態讀取，實現：

- 無 Firestore 分類時，NavBar 不顯示任何分類連結。
- CMS 新增/刪除分類後，NavBar 即時反映（Stream 驅動，無需手動刷新）。
- 載入中顯示骨架（skeleton）或隱藏，不閃爍舊資料。

## 範疇限制

- **僅修改** `app_nav_bar.dart`。
- **不修改** providers、models、router，均維持現狀。
- **不涉及** 手機版導覽（手機版本無分類連結，維持現狀）。
- 不需要 QA Agent 介入（精簡 Bug Fix）。

## 成功標準

1. 啟動應用後，NavBar 分類連結完全來自 Firestore `categories` 集合。
2. Firestore 中無分類時，NavBar 中段空白，不顯示任何分類連結。
3. 在 CMS 後台新增一個分類後，NavBar 在下一個 Stream event 後顯示該分類（通常 < 1 秒）。
4. 現有所有其他 NavBar 功能（Logo、購物車、Chat、後台按鈕、使用者動作）不受影響。
