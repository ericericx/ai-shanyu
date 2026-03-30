---
name: admin-home-button 歸檔紀錄
description: AdminShell 後台返回首頁按鈕，2026-03-30 歸檔，commit aa6fd4e，桌機側欄 + 手機版雙佈局實作
type: project
---

admin-home-button change 於 2026-03-30 完成歸檔，commit aa6fd4e。

**Why:** 管理員在後台缺乏快速返回前台首頁的入口，需在 AdminShell 兩種佈局中加入一致的導覽出口。

**How to apply:** 未來若需在 AdminShell 側欄底部加入其他固定操作（如登出），可沿用相同模式 — 在 Expanded ListView 之後插入 Divider + _DesktopNavTile，手機版則在 bottomNavigationBar Column 頂部插入 Material > ListTile。

## 實作重點

- 桌機（`_DesktopLayout`）：側欄 Column 中，Expanded 後插入 `const Divider()` + `_DesktopNavTile(isSelected: false, onTap: () => context.go(AppRoutes.home))`
- 手機（`_MobileLayout`）：`bottomNavigationBar` 改為 `Column(mainAxisSize: MainAxisSize.min)`，NavigationBar 上方插入 `Material(color: surfaceContainerLow) > ListTile`
- `_kNavItems` 清單未動，tab 索引邏輯完全不受影響
- 新增 import `core/router/app_router.dart` 以使用 `AppRoutes.home`
- flutter analyze 零警告
