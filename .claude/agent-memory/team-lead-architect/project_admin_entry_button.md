---
name: admin-entry-button 歸檔紀錄
description: NavBar 後台入口按鈕功能已完成歸檔，實作細節與決策紀錄
type: project
---

NavBar 後台入口按鈕（admin-entry-button）已於 2026-03-30 完成並歸檔。

- 實作 commit：`6d4a127`（flutter-artisan）
- 修改檔案：`shanyu_app/lib/shared/widgets/app_nav_bar.dart` 唯一
- 新增 widget：`_AdminEntryButton`（ConsumerWidget），以 `isAdminProvider.when()` 控制顯示
- NavBar 右側順序：Chat → Cart → AdminEntry → UserAction
- OpenSpec 路徑：`openspec/changes/admin-entry-button/`

**Why:** 管理員原本需手動輸入 `/admin/cms` URL，缺乏視覺化入口。

**How to apply:** 如未來需要新增其他 admin-only 的 NavBar 元件，可參照此模式：以 `isAdminProvider.when()` 包裹，loading/error/false 均回傳 `SizedBox.shrink()`。
