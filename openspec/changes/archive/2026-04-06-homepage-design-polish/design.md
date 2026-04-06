## Context

山裕首頁目前使用 Flutter 預設字型，設計 Token 分散在 6 個 widget 的私有 `_XxxTokens` 類別中（`_HomeTokens`、`_BannerTokens`、`_BrandTokens`、`_Tokens`、`_TimelineTokens`、`_NavBarTokens`），且頁面底部無行動呼籲區塊。需透過字型升級、Token 集中化、CTA 新增來提升整體質感。

## Goals / Non-Goals

**Goals:**
- 建立集中化設計 Token 系統，讓全站色彩、間距、字型可一處維護
- 引入 Google Fonts（Playfair Display + Inter + Noto Sans TC）提升字型質感
- 新增首頁底部 CTA 區塊引導轉化

**Non-Goals:**
- 不重新設計首頁佈局或區塊順序
- 不變更現有品牌色（`#B82020` 紅色系維持不動）
- 不新增後端 API 或 Firestore 結構
- 不處理商品列表頁面的實作

## Decisions

### 1. 集中 Token 檔案位置：`lib/shared/theme/app_design_tokens.dart`

放在 `shared/theme/` 下，與 `main.dart` 的 ThemeData 同層級概念。使用 `abstract final class AppDesignTokens` 以靜態常數方式提供，與現有各 widget 的 Token 模式一致。

**替代方案**：使用 `ThemeExtension` 動態注入 — 過度設計，目前只有一套主題，靜態常數足夠。

### 2. 字型方案：google_fonts 套件 + ThemeData 統一設定

在 `main.dart` 的 `ThemeData.textTheme` 中設定全站預設字型為 Inter，標題類（displayLarge/Medium/Small、headlineLarge/Medium）使用 Playfair Display。中文回退至 Noto Sans TC。

**替代方案**：下載字型檔放 assets — 增加 app 體積，且 google_fonts 套件有快取機制，Web 端本就從 Google CDN 載入。

### 3. Token 遷移策略：漸進替換

各 widget 的 `_XxxTokens` 類別內容改為引用 `AppDesignTokens` 的對應常數，而非直接刪除私有類別。這樣每個 widget 仍保有命名空間清晰度，但值的來源統一。

### 4. CTA 區塊設計：靜態 Widget，不依賴 CMS

CTA 文案與按鈕暫時寫死在程式碼中（「立即選購當季水果」），未來可擴充為 CMS 驅動。按鈕連結至 `/products` 路由（需確認路由是否已存在）。

## Risks / Trade-offs

- **google_fonts 網路依賴** → Web 端從 CDN 載入，離線時回退至系統字型；可接受，目標平台為 Web
- **Token 遷移遺漏** → 透過 Grep 搜尋所有 `Color(0xFF` 確認無遺漏硬編碼色值
- **CTA 路由不存在** → 若 `/products` 路由尚未建立，CTA 按鈕暫時可導向首頁頂部或顯示 Coming Soon
