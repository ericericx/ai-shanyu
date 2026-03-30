---
change: admin-home-button
type: feature
status: archived
created: 2026-03-30
---

# Specs: 後台返回首頁按鈕

## S-01 桌機版側欄底部按鈕

**目標元件：** `_DesktopLayout`

**規格：**
- 在 `_DesktopLayout` 的側欄 `Column` 中，`Expanded`（ListView）之後插入一個「返回首頁」按鈕
- 外觀使用 `_DesktopNavTile`，傳入：
  - `item`: `_NavItem(label: '返回首頁', icon: Icons.home_outlined, selectedIcon: Icons.home, path: AppRoutes.home)`
  - `isSelected`: 恆為 `false`（此按鈕不參與 tab 選取邏輯）
  - `onTap`: `() => context.go(AppRoutes.home)`
- 按鈕置於側欄底部，與 `Expanded` 之間保留 `const Divider()` 視覺分隔

**驗收條件：**
- [ ] 桌機寬度 >= 600dp 時，側欄底部可見「返回首頁」按鈕
- [ ] 點擊後 `context.go('/')` 被呼叫，頁面導向 `HomePage`
- [ ] 按鈕不改變 `navigationShell.currentIndex`

---

## S-02 手機版返回首頁入口

**目標元件：** `_MobileLayout`

**規格：**
- 在 `_MobileLayout` 的 `NavigationBar` 之上插入一個 `Material` 容器，內含 `ListTile`：
  - `leading`: `Icon(Icons.home_outlined)`
  - `title`: `Text('返回首頁')`
  - `onTap`: `() => context.go(AppRoutes.home)`
  - `dense: true`
  - 背景色使用 `colorScheme.surfaceContainerLow`（與桌機側欄一致）
- `_MobileLayout.build` 改用 `Column` 包裹 `body + ListTile + NavigationBar`，或將 `bottomNavigationBar` 改為自訂 `Column` Widget

**驗收條件：**
- [ ] 手機寬度 < 600dp 時，底部 NavigationBar 上方可見「返回首頁」列
- [ ] 點擊後 `context.go('/')` 被呼叫，頁面導向 `HomePage`
- [ ] 原有 `NavigationBar` 的 5 個目的地與選取邏輯不受影響
