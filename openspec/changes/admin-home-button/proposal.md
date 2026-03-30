---
change: admin-home-button
type: feature
status: archived
created: 2026-03-30
author: team-lead-architect
---

# Proposal: 後台返回首頁按鈕

## 背景

管理員在後台操作時，沒有直觀的方式回到前台首頁（`/`）。目前 `AdminShell` 的導覽結構僅包含後台內部頁面的切換，缺少「離開後台」的入口。

## 目標

在 `AdminShell` 兩種佈局（桌機側欄、手機版）中，各自加入一個視覺清晰、操作一致的「返回首頁」按鈕，點擊後執行 `context.go(AppRoutes.home)`。

## 範疇

- 僅修改 `admin_shell.dart` 一個檔案
- 不新增路由、不新增 Provider、不新增頁面
- 不影響現有 `_kNavItems` 清單

## 非範疇

- 登出功能
- 手機版 AppBar 的完整設計（保持最小改動）
- Admin 權限判斷邏輯

## 成功標準

1. 桌機版：側欄底部出現「返回首頁」按鈕，點擊後導向 `/`
2. 手機版：底部 NavigationBar 上方出現「返回首頁」按鈕列，點擊後導向 `/`
3. 樣式與現有導覽項目一致（使用 `Icons.home_outlined`）
4. 不影響現有導覽邏輯（`selectedIndex`、`goBranch`）
