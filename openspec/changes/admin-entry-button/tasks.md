# 任務：admin-entry-button

## 任務列表

### T-01：實作 `_AdminEntryButton` widget 並整合至 NavBar

**負責人：** flutter-artisan
**優先級：** P0（唯一任務）
**相依：** 無

**描述：**
在 `shanyu_app/lib/shared/widgets/app_nav_bar.dart` 中完成以下兩項修改：

1. 新增 `_AdminEntryButton` class（`ConsumerWidget`）：
   - `ref.watch(isAdminProvider).when(...)` 處理三種狀態
   - loading / error → `SizedBox.shrink()`
   - data(false) → `SizedBox.shrink()`
   - data(true) → 40x40 `SizedBox` 包含 `IconButton`
   - 圖示：`Icons.admin_panel_settings_outlined`，size 22
   - 顏色：`_NavBarTokens.brandBrown`
   - tooltip：`'後台管理'`
   - splashRadius：20
   - onPressed：`context.go(AppRoutes.adminCms)`

2. 修改 `AppNavBar.build()` 的 Row children：
   - 在 `_CartButton()` 與 `_UserAction()` 之間插入：
     `const SizedBox(width: 4), _AdminEntryButton(),`

**接受標準：**
- [ ] Admin 帳號登入後，NavBar 右側出現後台入口圖示按鈕
- [ ] 一般使用者登入後，按鈕不可見
- [ ] 未登入狀態下，按鈕不可見
- [ ] 點擊按鈕後跳轉至 `/admin/cms`
- [ ] Tooltip 顯示「後台管理」
- [ ] NavBar 高度保持 64dp 不變
- [ ] 手機與桌機版面均正確顯示

**實作完成後：**
1. 執行 `flutter analyze` 確認無靜態分析錯誤
2. 執行 `/opsx:verify`
3. 執行 `/opsx:archive`
4. 立即 git commit（message 範例：`feat(T-01): NavBar 新增後台入口按鈕`）
5. 通知 team-lead-architect 任務完成

## 任務狀態追蹤

| Task | 負責人 | 狀態 |
|------|--------|------|
| T-01 | flutter-artisan | completed |
