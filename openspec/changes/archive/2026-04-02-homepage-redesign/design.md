## Context

首頁目前採用大地棕色系（seed `#5C4033`），設計 Token 分散在各個 widget 檔案中（`_HomeTokens`、`_NavBarTokens`、`_BannerTokens`、`_TimelineTokens`）。分類連結直接嵌在 `AppNavBar` 的 `Row` 中，手機版完全隱藏。`ProductTimeline` 以 `SingleChildScrollView` 包裹的格狀表格呈現，橫向捲動體驗在手機上不佳。

## Goals / Non-Goals

**Goals:**
- 全站品牌色由棕轉深紅，視覺與 CHIEN.SHAN YU 識別一致
- NavBar 瘦身為純工具欄，分類獨立為 `CategoryTabBar`
- Banner 在大螢幕上不過度拉伸，加 maxWidth 與側邊 padding
- `ProductTimeline` 改為線性時程軸，視覺更直覺、手機體驗更好

**Non-Goals:**
- 不新增 Firestore collection 或 Cloud Functions
- 不修改路由結構
- 不更動 CMS 後台頁面的色系（後台維持現有風格）
- 不引入新的狀態管理套件

## Decisions

### D1：品牌色不抽成獨立 `app_colors.dart`，改為更新各 widget Token

現有各 widget 都有自己的私有 `abstract final class _XxxTokens`，已是慣例。抽成全域 `AppColors` 需大規模重構，風險高且超出本次範疇。

**決策**：直接更新各 `_XxxTokens` 內的色碼，同步更新 `main.dart` 的 `ColorScheme.fromSeed` 種子色為 `#B82020`。

### D2：`CategoryTabBar` 為獨立 widget，插入 `HomePage` 而非 `AppNavBar`

`AppNavBar` 目前以 `PreferredSizeWidget` 實作，高度固定 64px。若把 Tab 列塞進 AppBar 會複雜化 `preferredSize`。

**決策**：`CategoryTabBar` 作為獨立 `ConsumerWidget`，放在 `HomePage` 的 `body` 最頂部（Banner 之前），並以 `SliverPersistentHeader` 或 `StickyHeader` 方式黏著頂部捲動（或先以 `Column` 方式實作，不黏著）。初版不做黏著，後續可升級。

**替代方案考量**：使用 `AppBar.bottom`（TabBar）— 會強制首頁用 `DefaultTabController`，不適合動態分類數量且耦合度高，捨棄。

### D3：Banner maxWidth 以 `Center` + `ConstrainedBox` 包裹

與 `BrandStorySection` 和 `_ProductTimelineSection` 做法一致，不引入新模式。

**決策**：在 `BannerCarousel` 外包 `Center` + `ConstrainedBox(maxWidth: 1440)`，並在超過該寬度時補 `horizontal padding: 24px`。

### D4：線性時程軸設計

每個農產品一列，X 軸為 1–12 月，用連續色條（圓端）標示生長期與採收期範圍，當前月份以垂直虛線標示。

**決策**：
- 整體結構：`Column`（農產品列表）內每列為 `Row`（名稱 + `CustomPaint` 或 `Stack`）
- 用 `Positioned` + 計算百分比寬度繪製色條（不用 Cell 格狀）
- 當前月份用全欄垂直線（`Positioned` 元素）疊在所有列上方
- 手機橫向捲動保留，但改為 `LayoutBuilder` 判斷最小渲染寬度

## Risks / Trade-offs

- **avif 圖片支援**：Flutter Web 對 avif 的支援取決於瀏覽器，Chrome/Edge 支援良好，Safari 14.1+ 支援。風險低，已確認使用 `Image.asset`。
- **CategoryTabBar 不黏著**：初版不做 sticky，使用者捲動後分類列消失。接受此取捨，後續再升級。
- **色系散落各 widget**：逐一更新 Token 容易漏改。需逐檔確認所有 `0xFF5C4033`、`0xFF8D6E63`、`0xFF4E342E`、`0xFF6D4C41`、`0xFF2D2118` 等棕色色碼。

## Open Questions

- `CategoryTabBar` 是否需要 active state（當使用者在某分類頁時，對應 Tab 顯示為選中）？→ 初版不實作，點擊即導頁，不保持選中狀態。
