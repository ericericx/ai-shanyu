## 1. 品牌色系替換

- [x] 1.1 更新 `main.dart` 的 `ColorScheme.fromSeed` 種子色為 `#B82020`
- [x] 1.2 更新 `app_nav_bar.dart` 的 `_NavBarTokens`：`brandBrown` → `#B82020`，`navLinkColor` / `navLinkHoverColor` → 深紅色系
- [x] 1.3 更新 `home_page.dart` 的 `_HomeTokens`：`brandBrown` / `brandBrownLight` → 深紅色系
- [x] 1.4 更新 `banner_carousel.dart` 的 `_BannerTokens`：佔位漸層色 → 深紅色系
- [x] 1.5 更新 `product_timeline.dart` 的 `_TimelineTokens`（若有棕色殘留）

## 2. NavBar 移除分類連結

- [x] 2.1 移除 `app_nav_bar.dart` 中桌機分類連結的 `if (isDesktop)` 區塊（`_NavCategoryLink` 相關）
- [x] 2.2 刪除 `_NavCategoryLink` widget 及其 State（已無使用）
- [x] 2.3 確認 NavBar 在桌機與手機版均正常顯示工具按鈕

## 3. 分類 Tab 列

- [x] 3.1 新增 `lib/features/home/presentation/widgets/category_tab_bar.dart`，實作 `CategoryTabBar` ConsumerWidget
- [x] 3.2 從 `categoriesProvider` 讀取分類資料，依 `sortOrder` 排序
- [x] 3.3 實作頁籤樣式（含品牌深紅 active/hover 色、圓角、橫向捲動）
- [x] 3.4 實作 loading skeleton 與空狀態（隱藏）
- [x] 3.5 點擊頁籤導向 `/products/{categoryId}`
- [x] 3.6 在 `home_page.dart` 的 `_HomeBody` 中，插入 `CategoryTabBar` 於 `BannerCarousel` 之前

## 4. Banner 最大寬度

- [x] 4.1 在 `home_page.dart` 的 `_HomeBody` 中，以 `Center` + `ConstrainedBox(maxWidth: 1440)` 包裹 `BannerCarousel`
- [x] 4.2 超過 1440px 時補 `horizontal padding: 24px`（使用 `Padding` 或調整 `ConstrainedBox`）
- [x] 4.3 確認 `aspectRatio: 2.5` 在各寬度下正確縮放

## 5. 線性農產時程

- [x] 5.1 重寫 `product_timeline.dart`：移除格狀 `_TimelineTable`、`_MonthHeader`、`_MonthCell`、`_ProductRow` 等 widget
- [x] 5.2 實作月份刻度列（X 軸），12 月等分，當前月份加粗標示
- [x] 5.3 實作農產品列：名稱 + `LayoutBuilder` 計算可用寬度後按比例繪製色條
- [x] 5.4 實作生長期色條（淺綠，圓端，`BorderRadius.circular`）
- [x] 5.5 實作採收期色條（深橘，圓端，疊於生長期上）
- [x] 5.6 實作跨年月份邏輯（起始月 > 結束月時拆為兩段色條）
- [x] 5.7 實作當前月份垂直虛線（`Positioned` + `CustomPaint` 或 `DashedLine`）
- [x] 5.8 點擊農產品列導向 `/products/{categoryId}`
- [x] 5.9 實作載入 skeleton 與空狀態
- [x] 5.10 確認手機版橫向捲動正常
