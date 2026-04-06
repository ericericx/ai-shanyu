## Why

首頁目前缺少自訂字型（使用 Flutter 預設字體）、沒有明確的行動呼籲（CTA）區塊，且設計 Token 分散在各 widget 內部（`_HomeTokens`、`_BannerTokens`、`_BrandTokens` 等），導致全站色彩與間距難以統一維護。透過引入 Google Fonts 字型、新增底部 CTA 區塊、並將 Token 集中管理，可以用最小改動達到最大的視覺質感提升。

## What Changes

- 引入 Google Fonts 套件，設定 Playfair Display（標題）+ Inter（內文）+ Noto Sans TC（中文）作為全站字型
- 在 `main.dart` 的 ThemeData 中統一定義字型與文字樣式
- 新增集中化設計 Token 檔案 `app_design_tokens.dart`，統一管理全站色彩、間距、圓角等 Token
- 將各 widget 內部的 `_XxxTokens` 類別改為引用集中 Token
- 在首頁底部（季節時程之後）新增 CTA 區塊（「立即選購當季水果」），引導使用者前往商品頁

## Capabilities

### New Capabilities
- `centralized-design-tokens`: 建立集中化設計 Token 系統，取代分散在各 widget 內的 Token 類別
- `google-fonts-typography`: 引入 Google Fonts 並設定全站字型層級（標題/內文/中文）
- `homepage-cta-section`: 首頁底部行動呼籲區塊，引導使用者進入商品頁

### Modified Capabilities
- `brand-color-system`: Token 來源從各 widget 內部的私有類別改為引用集中 Token 檔案

## Impact

- **套件依賴**：新增 `google_fonts` 套件
- **檔案新增**：`lib/shared/theme/app_design_tokens.dart`
- **檔案修改**：`main.dart`（ThemeData 字型設定）、`home_page.dart`（新增 CTA 區塊、改用集中 Token）、`banner_carousel.dart`、`brand_story_section.dart`、`category_tab_bar.dart`、`product_timeline.dart`、`app_nav_bar.dart`（皆改為引用集中 Token）
- **路由**：CTA 按鈕需連結至商品列表頁路由
