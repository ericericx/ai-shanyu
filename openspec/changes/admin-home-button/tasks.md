---
change: admin-home-button
type: feature
status: archived
created: 2026-03-30
---

# Tasks: 後台返回首頁按鈕

## T-1：實作桌機版側欄底部「返回首頁」按鈕

**負責人：** flutter-artisan
**相依：** 無

**工作項目：**
1. 開啟 `shanyu_app/lib/features/admin/presentation/admin_shell.dart`
2. 在 `_DesktopLayout.build` 方法的側欄 `Column` 中，`Expanded` 之後插入：
   - `const Divider()`
   - `_DesktopNavTile`，傳入 `isSelected: false`，`onTap: () => context.go(AppRoutes.home)`，item 使用 `_NavItem(label: '返回首頁', icon: Icons.home_outlined, selectedIcon: Icons.home, path: AppRoutes.home)`

**驗收條件：**
- [ ] 桌機寬度 >= 600dp，側欄底部可見「返回首頁」按鈕（帶分隔線）
- [ ] 點擊後導向 `/`（HomePage）
- [ ] 現有 5 個 nav tile 選取狀態不受影響

---

## T-2：實作手機版底部「返回首頁」列

**負責人：** flutter-artisan
**相依：** 無（可與 T-1 同步進行）

**工作項目：**
1. 在 `_MobileLayout.build` 方法中，將 `bottomNavigationBar` 的值改為 `Column(mainAxisSize: MainAxisSize.min, children: [...])`
2. Column 內容：
   - `Material(color: Theme.of(context).colorScheme.surfaceContainerLow, child: ListTile(leading: Icon(Icons.home_outlined), title: Text('返回首頁'), dense: true, onTap: () => context.go(AppRoutes.home)))`
   - 原有 `NavigationBar(...)` Widget（不改動其屬性）

**驗收條件：**
- [ ] 手機寬度 < 600dp，底部 NavigationBar 上方可見「返回首頁」列
- [ ] 點擊後導向 `/`（HomePage）
- [ ] 原有 NavigationBar 5 個目的地與 selectedIndex 邏輯不受影響

---

## T-3：verify + archive + git commit

**負責人：** flutter-artisan
**相依：** T-1、T-2 皆完成

**工作項目：**
1. 執行 `/opsx:verify`，確認實作符合 proposal / specs / design 產出物
2. 執行 `/opsx:archive`，將 `admin-home-button` 歸檔
3. 立即建立 git commit，commit message 格式：`feat(admin-home-button): 後台側欄與手機版加入返回首頁按鈕`
4. 通知 team-lead-architect 完成

**驗收條件：**
- [ ] `openspec/changes/admin-home-button/` 已歸檔
- [ ] git commit 已建立，範疇對應此次變更
