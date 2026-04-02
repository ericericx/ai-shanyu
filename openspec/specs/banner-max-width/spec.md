# banner-max-width Specification

## Purpose
TBD - created by archiving change homepage-redesign. Update Purpose after archive.
## Requirements
### Requirement: Banner 具有最大顯示寬度
系統 SHALL 限制 `BannerCarousel` 的最大渲染寬度為 `1440px`。當視窗寬度超過 `1440px` 時，Banner SHALL 置中顯示並在左右補 `horizontal padding: 24px`。

#### Scenario: 視窗寬度超過 1440px 時 Banner 置中並有側邊距
- **WHEN** 使用者在寬度 > 1440px 的螢幕瀏覽首頁
- **THEN** Banner 最大寬度為 1440px，左右各有 24px padding，置中顯示

#### Scenario: 視窗寬度不超過 1440px 時 Banner 全寬
- **WHEN** 使用者在寬度 ≤ 1440px 的螢幕瀏覽首頁
- **THEN** Banner 延伸至視窗全寬，無額外側邊距

#### Scenario: Banner 圖片比例維持不變
- **WHEN** Banner 在任何寬度下渲染
- **THEN** 圖片依 `aspectRatio: 2.5` 等比例縮放，不變形

