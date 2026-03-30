---
change: admin-home-button
type: feature
status: archived
created: 2026-03-30
---

# Design: 後台返回首頁按鈕

## 架構決策

### 不引入新 Widget 類別
「返回首頁」按鈕直接複用現有的 `_DesktopNavTile`（桌機）和 `ListTile`（手機），不新增獨立 Widget class，降低維護成本。

### 不修改 `_kNavItems`
此按鈕不屬於後台導覽 tab，不應影響 `navigationShell.currentIndex`。因此不加入 `_kNavItems` 清單，而是在佈局層獨立渲染。

### 路由跳轉
使用 `context.go(AppRoutes.home)` 直接跳轉，符合 GoRouter 的命令式導覽慣例，與 `_UnauthorizedPage` 內的既有用法一致。

---

## 桌機版 `_DesktopLayout` 修改設計

```
Column
  ├── SizedBox(height: 24)
  ├── Padding > Text('山裕後台')          ← 現有標題
  ├── SizedBox(height: 24)
  ├── Expanded > ListView.builder(...)    ← 現有 nav items
  ├── const Divider()                     ← 新增：視覺分隔線
  └── _DesktopNavTile(                    ← 新增：返回首頁按鈕
        item: _NavItem(
          label: '返回首頁',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          path: AppRoutes.home,
        ),
        isSelected: false,
        onTap: () => context.go(AppRoutes.home),
      )
```

`_DesktopNavTile` 接收 `BuildContext` 需透過 `Builder` widget 或將 `context` 傳入 callback 的方式取得，因為 `_DesktopLayout` 的 `_onDestinationSelected` 目前不持有 `context`。

解法：`onTap` callback 改為 `VoidCallback`，在 `build` 方法中使用 `context` closure 傳入：
```dart
onTap: () => context.go(AppRoutes.home),
```
直接在 `build` 方法的 `Column children` 裡內聯定義即可，不需傳遞 context 到其他方法。

---

## 手機版 `_MobileLayout` 修改設計

原本 `Scaffold.bottomNavigationBar` 只接受單一 Widget。為了在 `NavigationBar` 上方插入「返回首頁」列，將 `bottomNavigationBar` 改為 `Column`，內含：

```
Column(mainAxisSize: MainAxisSize.min)
  ├── Material(color: colorScheme.surfaceContainerLow)
  │   └── ListTile(
  │         leading: Icon(Icons.home_outlined),
  │         title: Text('返回首頁'),
  │         dense: true,
  │         onTap: () => context.go(AppRoutes.home),
  │       )
  └── NavigationBar(...)                  ← 現有，不改動
```

注意：`Scaffold.bottomNavigationBar` 可接受任意 Widget，改為 `Column` 完全合法。

---

## 受影響檔案

| 檔案 | 變更類型 |
|------|---------|
| `shanyu_app/lib/features/admin/presentation/admin_shell.dart` | 修改 |

---

## 不受影響範圍

- `app_router.dart` — 不變
- `admin_providers.dart` — 不變
- 任何 Firebase / Cloud Functions — 不變
- 現有 5 個後台 tab 的選取與路由邏輯 — 不變
