## Why

目前系統僅有商品點擊追蹤（`ProductViewTracker` 寫入 Firestore `productViews` 集合），只能了解哪些商品被瀏覽過。然而，管理員無法了解客戶在各頁面的瀏覽行為——例如有多少人進入首頁後前往分類頁、有多少人瀏覽購物車但未完成結帳等。

需要全站頁面瀏覽追蹤功能，自動記錄使用者在首頁、分類頁、商品詳情頁、購物車、結帳頁等各頁面的瀏覽行為，以便後台 CRM 進行流量分析與轉換漏斗分析。

## What Changes

- 建立 `PageViewTracker`，使用 GoRouter 的 `NavigatorObserver` 在頁面切換時自動記錄瀏覽事件至 Firestore `pageViews` 集合
- 每筆記錄包含 path、title、userId（可選）、timestamp、sessionId、referrer
- 匿名與登入使用者皆追蹤，採用 fire-and-forget 模式不阻塞頁面載入
- 將 Observer 整合至 `app_router.dart` 的 GoRouter 設定中
- 建立對應的 Riverpod Provider 供整合使用

## Capabilities

### New Capabilities
- `page-view-tracking`：全站頁面瀏覽自動追蹤，透過 GoRouter NavigatorObserver 記錄頁面瀏覽至 Firestore

### Modified Capabilities

## Impact

- **新增檔案**：`page_view_tracker.dart`（NavigatorObserver + Firestore 寫入邏輯）、`page_view_providers.dart`（Riverpod Provider）
- **修改檔案**：`app_router.dart`（GoRouter 加入 `observers` 參數，注入 PageViewTracker observer）
- **Firestore**：新增 `pageViews` 集合，每筆文件包含 path、title、userId、timestamp、sessionId、referrer
- **現有功能**：不影響現有 `productViews` 追蹤，兩者獨立運作
