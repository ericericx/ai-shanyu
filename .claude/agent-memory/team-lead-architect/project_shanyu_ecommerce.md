---
name: 山裕電商系統 v1 — 專案基本資訊
description: 山裕電商系統的技術選型、範疇邊界、OpenSpec change 位置，與關鍵架構決策
type: project
---

## 山裕電商系統 v1 已立項

OpenSpec Change 路徑：`openspec/changes/shanyu-ecommerce-v1/`

產出物清單：
- `explore.md` — 範疇分析與技術評估
- `proposal.md` — 提案
- `specs.md` — 功能規格（14 個 SPEC）
- `design.md` — 技術設計（資料模型、架構、Cloud Functions、Indexes）
- `tasks.md` — 24 個任務，分配給 flutter-artisan（前端）與 firebase-integrator（後端）

**Why：** 客戶需要一個 Firebase 全棧的響應式農產品電商平台，支援季節性商品流水線展示與預購機制。

**How to apply：** 所有後續功能開發都應在此 change 下繼續，新功能用子 change 或新 change 建立。

## 技術選型
- 前端：Flutter Web + Riverpod + GoRouter
- 後端：Firebase（Firestore + Auth + Storage + Cloud Functions）
- 環境：development / production 兩個 Firebase 專案

## 關鍵範疇邊界
- 金流整合：排除，待後續版本
- Line/Facebook 通知 API：排除，此版本只保留資料欄位
- Native App：排除

## 任務分派（Sprint 1 P0 起始任務）
- firebase-integrator 從 T-01（Firebase 基礎架構）開始
- flutter-artisan 從 T-02（Flutter 初始化，需等 T-01）開始

## 立項日期：2026-03-29
