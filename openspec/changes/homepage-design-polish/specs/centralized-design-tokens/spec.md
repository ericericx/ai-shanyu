## ADDED Requirements

### Requirement: 集中化設計 Token 檔案
系統 SHALL 在 `lib/shared/theme/app_design_tokens.dart` 提供 `abstract final class AppDesignTokens`，以靜態常數集中管理全站設計 Token。

Token 類別 SHALL 包含以下區塊：
- **色彩**：brandRed、brandRedDark、surface、textPrimary、textSecondary、divider
- **間距**：pagePadding、sectionGap、contentMaxWidth
- **圓角**：radiusSm、radiusMd

所有 Token 值 SHALL 與現有各 widget 的 `_XxxTokens` 類別中的值一致。

#### Scenario: Token 檔案存在且可匯入
- **WHEN** 任何 widget 檔案 import `app_design_tokens.dart`
- **THEN** 可透過 `AppDesignTokens.brandRed` 等靜態存取方式取得 Token 值

#### Scenario: Token 值與現有定義一致
- **WHEN** 比對 `AppDesignTokens.brandRed` 與原 `_HomeTokens.brandRed`
- **THEN** 兩者 SHALL 為相同值 `Color(0xFFB82020)`

### Requirement: 各 widget Token 類別引用集中 Token
各 widget 內部的 `_XxxTokens` 類別（`_HomeTokens`、`_BannerTokens`、`_BrandTokens`、`_Tokens`、`_TimelineTokens`、`_NavBarTokens`）的色彩與間距值 SHALL 改為引用 `AppDesignTokens` 的對應常數。

#### Scenario: HomeTokens 引用集中 Token
- **WHEN** 檢視 `home_page.dart` 的 `_HomeTokens.brandRed`
- **THEN** 其值 SHALL 為 `AppDesignTokens.brandRed`（而非硬編碼 `Color(0xFFB82020)`）

#### Scenario: 所有 widget Token 無硬編碼色值
- **WHEN** 搜尋首頁相關 widget 檔案中的 `Color(0xFF` 模式
- **THEN** 色彩值 SHALL 全部來自 `AppDesignTokens` 引用，無直接硬編碼
