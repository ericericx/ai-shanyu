# 設計：admin-entry-button

## 元件設計

### 新增 Widget：`_AdminEntryButton`

位置：`shanyu_app/lib/shared/widgets/app_nav_bar.dart`

```
_AdminEntryButton（ConsumerWidget）
  └── ref.watch(isAdminProvider)
       ├── loading → SizedBox.shrink()
       ├── error   → SizedBox.shrink()
       └── data(true)  → SizedBox(40x40)
                           └── IconButton
                                ├── icon: Icons.admin_panel_settings_outlined
                                ├── color: _NavBarTokens.brandBrown
                                ├── iconSize: 22
                                ├── tooltip: '後台管理'
                                ├── splashRadius: 20
                                └── onPressed: context.go(AppRoutes.adminCms)
```

### NavBar Row 修改

在 `AppNavBar.build()` 中，原有的右側序列：

```
_ChatButton → SizedBox(4) → _CartButton → SizedBox(4) → _UserAction
```

修改為：

```
_ChatButton → SizedBox(4) → _CartButton → SizedBox(4) → _AdminEntryButton → SizedBox(4) → _UserAction
```

### AsyncValue 處理策略

`isAdminProvider` 為 `FutureProvider<bool>`，使用 `ref.watch(isAdminProvider)` 取得 `AsyncValue<bool>`。

採用 `.when()` 解包：

```dart
return ref.watch(isAdminProvider).when(
  loading: () => const SizedBox.shrink(),
  error: (_, __) => const SizedBox.shrink(),
  data: (isAdmin) {
    if (!isAdmin) return const SizedBox.shrink();
    return SizedBox(
      width: _NavBarTokens.iconButtonSize,
      height: _NavBarTokens.iconButtonSize,
      child: IconButton(
        onPressed: () => context.go(AppRoutes.adminCms),
        icon: const Icon(Icons.admin_panel_settings_outlined),
        color: _NavBarTokens.brandBrown,
        iconSize: 22,
        tooltip: '後台管理',
        splashRadius: 20,
      ),
    );
  },
);
```

## 不需要修改的檔案

| 檔案 | 理由 |
|------|------|
| `app_router.dart` | 路由 `/admin/cms` 已存在 |
| `admin_providers.dart` | `isAdminProvider` 已存在且功能完整 |
| `firestore.rules` | 無資料存取需求 |
| `admin_providers.g.dart` | 不修改 provider，無需重新 codegen |

## 需要修改的檔案

| 檔案 | 修改內容 |
|------|---------|
| `shanyu_app/lib/shared/widgets/app_nav_bar.dart` | 1. 新增 `_AdminEntryButton` class；2. 在 `AppNavBar.build()` Row 中插入 `_AdminEntryButton()` 與對應間距 |

## 資料流

```
Firebase Auth Token Claims
        ↓
isAdminProvider (FutureProvider<bool>)
        ↓
_AdminEntryButton (ConsumerWidget)
        ↓
AsyncValue<bool>.when(...)
        ↓
顯示/隱藏 IconButton
```

## 無障礙與 UX 考量

- `tooltip: '後台管理'` 提供螢幕閱讀器支援
- `splashRadius: 20` 保持與現有按鈕視覺一致
- loading 期間不顯示而非顯示 placeholder，避免管理員登入瞬間的 UI 跳動
