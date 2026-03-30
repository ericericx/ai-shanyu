# 提案：admin-entry-button

## 變更摘要

在 `AppNavBar` 右側新增一個後台入口按鈕，僅在目前使用者具備管理員身份（`isAdminProvider == true`）時顯示。點擊後導向 `/admin/cms`。

## 動機

目前管理員登入後，若要進入後台必須手動輸入 URL `/admin/cms`，沒有視覺化的入口按鈕。本變更改善管理員的操作流程，提供一個常駐且清晰的後台入口。

## 範疇

### 在範疇內

- 在 `AppNavBar` 的 `_UserAction` 左側新增 `_AdminEntryButton` widget
- 使用 `isAdminProvider` 偵測管理員身份，非 admin 不顯示
- 點擊後透過 `context.go(AppRoutes.adminCms)` 跳轉後台
- 處理 `isAdminProvider` 的 loading / error 狀態（兩者均顯示 `SizedBox.shrink()`）

### 不在範疇內

- Admin 路由守衛（已由現有 `adminGuard` provider 處理）
- ProfilePage 增設後台入口
- Admin 角色管理 UI
- Firestore security rules 修改

## 技術決策

| 項目 | 決策 | 理由 |
|------|------|------|
| 入口位置 | NavBar（`_UserAction` 左側） | 全站常駐，`app_nav_bar.dart` 已有 admin_providers import |
| 圖示 | `Icons.admin_panel_settings_outlined` | 語意清晰，符合 Material Design 後台慣例 |
| 顯示條件 | `isAdminProvider.future` 為 `true` 時才顯示 | 非 admin 完全不可見，避免資安疑慮 |
| loading 狀態 | `SizedBox.shrink()` | 避免 UI 閃爍，保持 NavBar 穩定寬度 |
| 顏色 | `_NavBarTokens.brandBrown` | 與現有按鈕一致 |

## 產出物狀態

- [x] proposal.md
- [x] specs.md
- [x] design.md
- [x] tasks.md

## 歸檔紀錄

- 實作 commit：`6d4a127`
- 歸檔日期：2026-03-30
- 驗證結果：全部 PASS（F-01 / F-02 / F-03）
- 狀態：**ARCHIVED**
