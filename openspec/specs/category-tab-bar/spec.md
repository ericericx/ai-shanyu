# category-tab-bar Specification

## Purpose
TBD - created by archiving change homepage-redesign. Update Purpose after archive.
## Requirements
### Requirement: 首頁顯示分類頁籤列
系統 SHALL 在首頁 Banner 上方顯示水平分類頁籤列（`CategoryTabBar`），從 `categoriesProvider` 動態載入分類資料並依 `sortOrder` 排序。

- 分類列表 SHALL 依 `sortOrder` 升序排列
- 每個分類以頁籤（Tab chip）呈現，顯示分類名稱
- 頁籤列 SHALL 支援橫向捲動（分類數量多時）
- 分類資料載入中時，頁籤列 SHALL 顯示 skeleton 佔位
- 分類資料為空時，頁籤列 SHALL 隱藏（`SizedBox.shrink`）

#### Scenario: 分類載入完成顯示頁籤
- **WHEN** `categoriesProvider` 回傳分類列表
- **THEN** 頁籤列顯示所有分類，依 `sortOrder` 排列

#### Scenario: 點擊分類頁籤導向分類頁
- **WHEN** 使用者點擊某分類頁籤
- **THEN** 路由導向 `/products/{categoryId}`

#### Scenario: 分類載入中顯示 skeleton
- **WHEN** `categoriesProvider` 處於 loading 狀態
- **THEN** 頁籤列顯示 skeleton 佔位元件

#### Scenario: 無分類時不顯示
- **WHEN** `categoriesProvider` 回傳空列表或發生錯誤
- **THEN** 頁籤列不佔用任何空間

### Requirement: NavBar 移除分類連結
系統 SHALL 將 `AppNavBar` 中的分類連結（`_NavCategoryLink` 列表）從 NavBar Row 移除，NavBar 僅保留 Logo 與工具按鈕。

#### Scenario: 桌機 NavBar 不顯示分類連結
- **WHEN** 使用者以桌機寬度（≥ 600dp）造訪任何頁面
- **THEN** NavBar 中段不顯示任何分類文字連結

#### Scenario: NavBar 工具按鈕保持不變
- **WHEN** 使用者查看 NavBar
- **THEN** Chat、購物車、後台入口、使用者動作按鈕仍正常顯示

