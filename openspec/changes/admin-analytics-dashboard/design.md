## Context

後台 CRM 頁面（`features/admin/presentation/crm_page.dart`）目前為單一長頁面，透過 `CustomScrollView` 顯示篩選列、熱門商品排行與商品瀏覽記錄列表。資料來源為 `CrmRepository` 讀取 Firestore `productViews` 集合，狀態管理使用 Riverpod（`@riverpod` annotation + code generation）。

已上線的相關資產：
- `pageViews` 集合：全站頁面瀏覽追蹤，每筆包含 path、title、userId、timestamp、sessionId、referrer
- `OrdersAdminRepository`：後台訂單查詢，可讀取 `orders` 集合（含 status、total、createdAt）
- `OrderModel`、`OrderStatus`：訂單資料模型，已定義於 `features/orders/models/order_models.dart`

## Goals / Non-Goals

**Goals:**
- 將 CRM 頁面改造為 tab 式分析儀表板，提供多維度經營數據
- 概覽 tab 一目了然顯示今日瀏覽數、本月訂單數、本月營收、活躍用戶數
- 頁面分析 tab 呈現熱門頁面排行，支援時間範圍篩選
- 完整保留現有商品分析功能

**Non-Goals:**
- 即時更新（StreamProvider）— 本次使用 FutureProvider，手動重新整理即可
- 圖表視覺化（折線圖、長條圖）— 後續迭代加入
- 匯出報表（CSV/Excel）
- 轉換漏斗分析（需更複雜的 session 路徑分析）

## Decisions

### D1：CRM 頁面改為 TabBar + TabBarView 佈局
**決策**：將 CrmPage 從 `ConsumerStatefulWidget` 改為含有 `TabController` 的三 tab 佈局：「概覽」「頁面分析」「商品分析」。
**理由**：三個分析維度各有不同的資料來源與互動方式，tab 佈局讓管理員可快速切換檢視，同時保持每個 tab 內容的獨立性與可維護性。

### D2：概覽統計直接查詢 Firestore 做 client 端聚合
**決策**：今日瀏覽數從 `pageViews` 集合以 timestamp 篩選後取 count；本月訂單數和營收從 `orders` 集合篩選 createdAt 後聚合；活躍用戶數從 `pageViews` 集合取不重複 userId 數量。
**理由**：與現有 `getTopProducts` 的 client 端聚合策略一致。資料量在可控範圍內（每日數百至數千筆），client 端聚合足夠。若後續資料量成長，可改為 Cloud Functions 定期計算。

### D3：頁面分析從 pageViews 集合聚合熱門頁面
**決策**：從 `pageViews` 集合查詢指定時間範圍內的記錄，在 client 端按 path 分組計數，排序後取前 10 名。
**理由**：與 `getTopProducts` 採用相同的 client 端聚合策略，實作簡潔。pageViews 集合的 path 欄位即可直接用於分組。

### D4：新增方法至現有 CrmRepository 而非新建 Repository
**決策**：在 `CrmRepository` 中新增 `getPageViewStats`、`getOverviewStats`、`getTopPages` 等方法。
**理由**：CRM 分析是同一個功能域，所有分析查詢集中管理。避免過度拆分增加複雜度。

### D5：時間範圍篩選使用預設快捷選項
**決策**：頁面分析 tab 提供「今日」「近 7 天」「近 30 天」三個快捷按鈕，不提供自訂日期範圍。
**理由**：降低 UI 複雜度，這三個時間範圍涵蓋最常見的分析需求。商品分析 tab 已有自訂日期範圍功能。

## 頁面架構

```
CrmPage (TabBar + TabBarView)
├── Tab 0: 概覽
│   └── OverviewTab
│       ├── StatCard（今日瀏覽數）    ← pageViews WHERE timestamp >= today
│       ├── StatCard（本月訂單數）    ← orders WHERE createdAt >= monthStart
│       ├── StatCard（本月營收）      ← orders WHERE createdAt >= monthStart, SUM(total)
│       └── StatCard（活躍用戶數）    ← pageViews WHERE timestamp >= monthStart, DISTINCT userId
│
├── Tab 1: 頁面分析
│   └── PageAnalyticsTab
│       ├── TimeRangeSelector（今日 / 7天 / 30天）
│       └── TopPagesList（熱門頁面排行 Top 10）
│           └── PageRankCard（path, title, viewCount）
│
└── Tab 2: 商品分析（現有功能）
    └── ProductAnalyticsTab
        ├── _SearchBar（現有篩選列）
        ├── _TopProductsSection（現有熱門排行）
        └── _ViewRecordsList（現有記錄列表）
```

## Repository 擴充

```dart
// CrmRepository 新增方法

/// 概覽統計
Future<OverviewStats> getOverviewStats()
  // 1. 今日瀏覽數：pageViews WHERE timestamp >= today 00:00
  // 2. 本月訂單數：orders WHERE createdAt >= 本月 1 號
  // 3. 本月營收：orders WHERE createdAt >= 本月 1 號，SUM(total)
  // 4. 活躍用戶數：pageViews WHERE timestamp >= 本月 1 號，DISTINCT non-null userId

/// 熱門頁面排行
Future<List<PopularPage>> getTopPages({
  required DateTime since,
  int limit = 10,
})
  // pageViews WHERE timestamp >= since，client 端按 path 分組計數
```

## Firestore 查詢

### pageViews 集合查詢
```
pageViews
  .where('timestamp', isGreaterThanOrEqualTo: since)
  .orderBy('timestamp', descending: true)
  .limit(1000)  // client 端聚合上限
```

### orders 集合查詢
```
orders
  .where('createdAt', isGreaterThanOrEqualTo: monthStart)
  .get()
  // client 端計算 count 與 SUM(total)
```

## 資料模型

```dart
/// 概覽統計資料
class OverviewStats {
  final int todayPageViews;     // 今日瀏覽數
  final int monthlyOrders;      // 本月訂單數
  final double monthlyRevenue;  // 本月營收
  final int activeUsers;        // 活躍用戶數（本月不重複 userId）
}

/// 熱門頁面排行項目
class PopularPage {
  final String path;       // 路由路徑
  final String title;      // 頁面標題
  final int viewCount;     // 瀏覽次數
}
```

## Risks / Trade-offs

- **[Firestore 讀取量]** 概覽統計需查詢 `pageViews` 和 `orders` 兩個集合，每次開啟 CRM 頁面會產生讀取 → 使用 `limit(1000)` 控制單次讀取量，FutureProvider 可快取結果
- **[聚合精確度]** client 端聚合受限於 `limit(1000)`，若單月記錄超過 1000 筆，統計數字會偏低 → 初期流量下可接受，後續可改為 Cloud Functions 定期聚合
- **[頁面標題對應]** `pageViews` 的 title 欄位由前端 `PageViewTracker` 寫入，可能為空或不一致 → 顯示時以 path 為主，title 為輔助資訊
