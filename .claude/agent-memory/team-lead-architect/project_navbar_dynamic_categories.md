---
name: navbar-dynamic-categories 歸檔紀錄
description: NavBar 分類連結硬編碼 Bug Fix，2026-03-30 歸檔，移除 _kNavCategories 改接 categoriesProvider
type: project
---

NavBar 分類連結改為動態載入，2026-03-30 完成歸檔。

**Why:** `_kNavCategories` 硬編碼三個分類，導致 Firestore 無資料時仍顯示連結，且 CMS 後台新增分類後 NavBar 不更新。

**How to apply:** 未來若有類似「NavBar 靜態資料」問題，可參考此模式：直接在 ConsumerWidget 中 `ref.watch(xxxProvider).when()` 取代常數，前端排序在 Widget 層用 `..sort()` 處理，不依賴 Firestore query 排序。

**實作細節：**
- 移除：`_NavCategory` 類別、`_kNavCategories` 常數
- 新增：`categoriesProvider` watch，`.when(loading/error/data)` 三態處理
- `_NavCategoryLink.category` 型別改為 `CategoryModel`（`.id` / `.name`）
- 間距 `SizedBox(width: 16)` 僅在 `sorted.isNotEmpty` 時加入
- commit：`fix(T-BF-01): NavBar 分類連結改為動態載入`
- 歸檔路徑：`openspec/archived/navbar-dynamic-categories/`
