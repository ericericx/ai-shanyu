# homepage-cta-section Specification

## Purpose
首頁底部行動呼籲區塊，引導使用者進入商品頁。

## Requirements

### Requirement: 首頁底部 CTA 區塊
首頁 SHALL 在季節農產時程區塊之後顯示一個行動呼籲（CTA）區塊。

CTA 區塊 SHALL 包含：
- 標題文字：「探索當季好果」
- 副標題文字：「從梨山到您的餐桌，每一口都是大自然的恩賜」
- 主要按鈕：「立即選購」，按鈕背景色為 `AppDesignTokens.brandRed`
- 區塊背景：使用品牌紅色淡化漸層營造視覺收尾感

#### Scenario: CTA 區塊在首頁底部可見
- **WHEN** 使用者滾動至首頁底部
- **THEN** SHALL 看到 CTA 區塊，位於季節農產時程之後

#### Scenario: CTA 按鈕點擊導航
- **WHEN** 使用者點擊「立即選購」按鈕
- **THEN** SHALL 導航至商品列表頁路由（`/products`）；若路由不存在，SHALL 滾動回頁面頂部作為臨時替代

### Requirement: CTA 區塊響應式佈局
CTA 區塊 SHALL 在不同螢幕寬度下正確顯示。

#### Scenario: 桌面版顯示
- **WHEN** 螢幕寬度 >= 600px
- **THEN** CTA 區塊 SHALL 水平置中，最大寬度不超過 `AppDesignTokens.contentMaxWidth`

#### Scenario: 行動版顯示
- **WHEN** 螢幕寬度 < 600px
- **THEN** CTA 區塊 SHALL 全寬顯示，內容垂直排列，按鈕寬度自適應
