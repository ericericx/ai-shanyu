## Why

現有首頁採用大地棕色系，視覺語言與品牌識別（CHIEN.SHAN YU 深紅色系）不一致，且導覽結構在分類數量增加後擴充性不足。重新設計首頁視覺系統與導覽架構，以強化品牌辨識度並提升使用者瀏覽體驗。

## What Changes

- **品牌色系全站替換**：全站設計 Token 由大地棕色（`#5C4033`）替換為品牌深紅色（`#B82020`）
- **分類 Tab 列**：NavBar 下方新增水平分類頁籤列，取代原本塞在 NavBar 內的分類連結；NavBar 僅保留 Logo + 工具（Chat、購物車、後台、使用者）
- **Banner 最大寬度限制**：BannerCarousel 加入 `maxWidth: 1440px` 上限，超過寬度時左右補 padding，維持視覺比例
- **農產線性時程**：重新設計 `ProductTimeline`，從格狀表格改為水平線性時程軸（每個農產品一條軌道，月份刻度在上方）

## Capabilities

### New Capabilities

- `brand-color-system`：全站統一品牌色 Token，深紅色系替換棕色系，集中定義供所有元件參照
- `category-tab-bar`：首頁 NavBar 下方的動態分類頁籤列，從 Firestore 讀取分類資料，點擊導向對應分類頁
- `banner-max-width`：Banner 輪播的最大寬度限制與響應式 padding 行為
- `linear-product-timeline`：以水平線性時程軸呈現農產品生長/採收月份，取代現有格狀表格

### Modified Capabilities

<!-- 無現有 spec 需修改 -->

## Impact

- `lib/shared/widgets/app_nav_bar.dart`：移除分類連結，新增分類 Tab 列佔位（或抽出獨立 widget）
- `lib/features/home/presentation/home_page.dart`：插入 `CategoryTabBar` widget；調整 Token 色碼
- `lib/features/home/presentation/widgets/banner_carousel.dart`：加入最大寬度約束與 padding 邏輯
- `lib/features/home/presentation/widgets/product_timeline.dart`：全面重寫為線性時程軸
- `lib/main.dart`：更新 `ColorScheme.fromSeed` 種子色
- 無新增 Firestore 資料結構，分類資料沿用既有 `categoriesProvider`
