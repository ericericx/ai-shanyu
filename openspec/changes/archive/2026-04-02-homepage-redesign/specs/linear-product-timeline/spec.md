## ADDED Requirements

### Requirement: 農產時程以水平線性時程軸呈現
系統 SHALL 將 `ProductTimeline` 重新設計為水平線性時程軸，以連續色條（非格狀色塊）呈現每個農產品的生長期與採收期。

- X 軸 SHALL 為 1–12 月，等分顯示月份刻度
- 每個農產品 SHALL 佔一橫列，名稱顯示於列左側
- 生長期 SHALL 以淺綠色連續色條（圓端）標示，對應起訖月份
- 採收期 SHALL 以深橘色連續色條（圓端）標示，對應起訖月份，疊在生長期上方
- 當前月份 SHALL 以垂直虛線標示於對應 X 軸位置
- 色條寬度 SHALL 根據月份比例計算（`startMonth / 12` 到 `endMonth / 12`）
- 跨年月份範圍（如 10 月 ~ 2 月）SHALL 正確計算並渲染
- 手機版 SHALL 支援橫向捲動

#### Scenario: 顯示農產品生長期色條
- **WHEN** 農產品有生長期月份資料
- **THEN** 對應月份範圍顯示淺綠色連續圓端色條

#### Scenario: 顯示農產品採收期色條
- **WHEN** 農產品有採收期月份資料
- **THEN** 對應月份範圍顯示深橘色連續圓端色條，採收期優先顯示於生長期之上

#### Scenario: 當前月份垂直線標示
- **WHEN** 使用者查看時程軸
- **THEN** 當前月份位置有垂直虛線橫跨所有農產品列

#### Scenario: 跨年月份正確渲染
- **WHEN** 農產品的起始月份大於結束月份（如 10 月 ~ 2 月）
- **THEN** 色條正確跨越年底，10月至12月為一段，1月至2月為另一段（或以兩段色條分別渲染）

#### Scenario: 點擊農產品列導向分類頁
- **WHEN** 使用者點擊任一農產品列
- **THEN** 路由導向 `/products/{categoryId}`

#### Scenario: 載入中顯示 skeleton
- **WHEN** `productTimelineProvider` 處於 loading 狀態
- **THEN** 顯示時程軸 skeleton 佔位

#### Scenario: 無資料時顯示空狀態
- **WHEN** `productTimelineProvider` 回傳空列表
- **THEN** 顯示「目前無農產品時程資料」文字
