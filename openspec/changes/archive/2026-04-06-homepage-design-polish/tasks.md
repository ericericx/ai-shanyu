## 1. 集中化設計 Token

- [x] 1.1 建立 `lib/shared/theme/app_design_tokens.dart`，定義 `AppDesignTokens` 類別，包含色彩、間距、圓角等全站 Token
- [x] 1.2 將 `home_page.dart` 的 `_HomeTokens` 改為引用 `AppDesignTokens`
- [x] 1.3 將 `banner_carousel.dart` 的 `_BannerTokens` 改為引用 `AppDesignTokens`
- [x] 1.4 將 `brand_story_section.dart` 的 `_BrandTokens` 改為引用 `AppDesignTokens`
- [x] 1.5 將 `category_tab_bar.dart` 的 `_Tokens` 改為引用 `AppDesignTokens`
- [x] 1.6 將 `product_timeline.dart` 的 `_TimelineTokens` 改為引用 `AppDesignTokens`
- [x] 1.7 將 `app_nav_bar.dart` 的 `_NavBarTokens` 改為引用 `AppDesignTokens`

## 2. Google Fonts 字型

- [x] 2.1 在 `pubspec.yaml` 新增 `google_fonts` 套件依賴並執行 `flutter pub get`
- [x] 2.2 在 `main.dart` 的 ThemeData 中設定 textTheme：標題用 Playfair Display、內文用 Inter、中文回退 Noto Sans TC

## 3. 首頁 CTA 區塊

- [x] 3.1 建立 `lib/features/home/presentation/widgets/cta_section.dart` CTA Widget
- [x] 3.2 在 `home_page.dart` 的 `_HomeBody` 中加入 CTA 區塊（季節時程之後）
