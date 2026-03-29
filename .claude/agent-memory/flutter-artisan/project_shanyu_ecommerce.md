---
name: 山裕電商 Flutter Web 專案初始化
description: 山裕電商 shanyu_app 的初始化狀態、Firebase 設定、套件版本、目錄結構與 Flavor 架構概覽
type: project
---

Flutter Web 專案 `shanyu_app/` 已完成 T-02 初始化，可正常 build web。

**Why:** Team Lead 指派 T-02 任務，建立 Flutter Web 電商前端的開發基礎。

**How to apply:** 後續所有前端功能開發在此基礎上進行，注意 flavor 機制與目錄規範。

## Firebase
- 專案：`shayu-staging`（staging 環境）
- Firebase App ID（Web）：`1:973958853185:web:d44f7550dcdd00bd028cc0`
- 選項檔案：`lib/firebase_options_development.dart`（由 flutterfire CLI 自動產生）

## Flavor 架構
- Development 設定：`lib/core/config/development.dart` → `developmentConfig`
- AppConfig class：`lib/core/config/app_config.dart`，含 `flavor`、`firebaseProjectId`、`apiBaseUrl`、`appDisplayName`
- 目前 `main.dart` 直接使用 `developmentConfig`；未來拆分 `main_dev.dart` / `main_prod.dart`

## 核心套件版本（pubspec.yaml）
- firebase_core: ^3.13.0
- firebase_auth: ^5.5.2
- cloud_firestore: ^5.6.6
- firebase_storage: ^12.4.4
- go_router: ^14.8.1
- flutter_riverpod: ^2.6.1
- riverpod_annotation: ^2.6.1
- hooks_riverpod: ^2.6.1
- flutter_hooks: ^0.20.5
- build_runner: ^2.4.14（dev）
- riverpod_generator: ^2.6.5（dev）

## 目錄結構
```
lib/
  core/
    config/   — AppConfig, development.dart
    router/   — app_router.dart（GoRouter 集中定義）
    theme/    — 待建立設計 token
  features/
    auth / home / products / cart / orders / profile / admin
  shared/
    widgets / models
  firebase_options_development.dart
  main.dart
```

## Router 路由表（app_router.dart）
- `/` — 首頁
- `/login` — 登入
- `/products/:categoryId` — 商品列表
- `/products/:categoryId/:productId` — 商品詳情（nested route）
- `/cart` — 購物車
- `/orders` — 訂單列表
- `/profile` — 會員中心
- `/admin` — 後台管理
