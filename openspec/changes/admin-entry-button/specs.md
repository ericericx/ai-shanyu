# 規格：admin-entry-button

## 功能規格

### F-01：後台入口按鈕顯示條件

**描述：** NavBar 右側在 `_UserAction` 左側顯示一個後台入口圖示按鈕。

**條件：**
- 當 `isAdminProvider` 解析為 `true` 時：顯示後台入口按鈕
- 當 `isAdminProvider` 解析為 `false` 時：不顯示（`SizedBox.shrink()`）
- 當 `isAdminProvider` 處於 loading 狀態時：不顯示（`SizedBox.shrink()`）
- 當 `isAdminProvider` 發生 error 時：不顯示（`SizedBox.shrink()`）
- 當使用者未登入時：`isAdminProvider` 本身回傳 `false`，按鈕不顯示

**接受標準：**
- [ ] 以管理員帳號登入 → 按鈕可見
- [ ] 以一般使用者帳號登入 → 按鈕不可見
- [ ] 未登入狀態 → 按鈕不可見
- [ ] 頁面初次載入 loading 期間 → 按鈕不可見（無閃爍）

### F-02：後台入口按鈕互動

**描述：** 管理員點擊後台入口按鈕後，導向後台首頁。

**行為：**
- 點擊按鈕呼叫 `context.go(AppRoutes.adminCms)`
- 使用 `tooltip: '後台管理'` 提示文字
- hover 效果：符合 Material InkWell 標準行為

**接受標準：**
- [ ] 點擊按鈕後跳轉至 `/admin/cms`
- [ ] Tooltip 顯示「後台管理」
- [ ] 按鈕 touch target 符合 40x40dp 最小尺寸

### F-03：NavBar 佈局一致性

**描述：** 新增按鈕後，NavBar 的視覺佈局與間距必須保持一致。

**規格：**
- 後台入口按鈕尺寸：`_NavBarTokens.iconButtonSize`（40x40dp）
- 後台入口按鈕與 `_UserAction` 之間間距：`SizedBox(width: 4)`
- 後台入口按鈕顏色：`_NavBarTokens.brandBrown`
- 圖示：`Icons.admin_panel_settings_outlined`，size 22

**接受標準：**
- [ ] 桌機（>= 600dp）：按鈕正確顯示在 Chat / 購物車 / 頭像右側序列中
- [ ] 手機（< 600dp）：按鈕正確顯示，不影響現有元素排列
- [ ] NavBar 高度不受影響（保持 64dp）
