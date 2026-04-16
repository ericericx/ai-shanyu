## Why

後台 CRM 頁面（`/admin/crm`）目前僅提供商品瀏覽排行與瀏覽記錄查詢功能，管理員缺乏完整的經營數據視角。隨著 `pageViews` 集合（全站頁面瀏覽追蹤）已上線、訂單管理功能也已完善，管理員迫切需要更豐富的分析數據來輔助經營決策——包括頁面瀏覽趨勢、訂單統計、營收概覽與客戶行為分析。

目前管理員若要了解「今天有多少人造訪」「本月營收多少」「哪些頁面最熱門」，必須手動查閱 Firebase Console 或拼湊多個頁面的資料，效率低落且無法快速掌握整體狀況。

## What Changes

增強 CRM 頁面，從單一的商品瀏覽記錄查詢頁面，改造為多 tab 的分析儀表板：

- CRM 頁面改為 tab 式佈局，包含「概覽」「頁面分析」「商品分析」三個分頁
- 新增概覽統計卡片區塊，一目了然顯示關鍵經營指標
- 新增頁面瀏覽分析，聚合 `pageViews` 集合資料呈現熱門頁面排行
- 保留現有商品瀏覽分析功能於「商品分析」tab

## Capabilities

### New Capabilities
- `admin-analytics-overview`：概覽統計卡片，包含今日瀏覽數、本月訂單數、本月營收、活躍用戶數四項關鍵指標
- `admin-page-analytics`：頁面瀏覽排行與趨勢分析，從 `pageViews` 集合聚合資料，支援時間範圍篩選（今日/7天/30天）

### Modified Capabilities

## Impact

- **修改檔案**：`crm_page.dart`（改為 tab 佈局、新增概覽 tab 與頁面分析 tab UI）、`crm_repository.dart`（新增頁面瀏覽查詢與訂單/營收統計方法）、`crm_providers.dart`（新增概覽統計與頁面分析相關 Provider）
- **模型擴充**：`crm_models.dart`（新增概覽統計與頁面瀏覽排行資料模型）
- **Firestore**：讀取 `pageViews` 集合（頁面瀏覽聚合）、讀取 `orders` 集合（訂單數與營收統計）
- **現有功能**：商品分析（現有瀏覽記錄與排行）完整保留於「商品分析」tab，不受影響
