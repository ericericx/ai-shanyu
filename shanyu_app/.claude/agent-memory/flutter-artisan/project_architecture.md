---
name: 山裕電商 Flutter 專案架構
description: 記錄 shanyu_app 的技術棧、目錄結構、套件版本與重要慣例
type: project
---

本專案為山裕農產品電商平台的 Flutter Web 前端，採用 development flavor。

**Flutter / Dart 版本**：Flutter 3.38.7、Dart 3.10.7（environment: sdk ^3.10.7）

**狀態管理**：`flutter_riverpod: ^2.6.1` + `riverpod_annotation: ^2.6.1`（code gen 模式，`@riverpod` / `@Riverpod(keepAlive: true)`）

**路由**：`go_router: ^14.8.1`，路由集中定義於 `lib/core/router/app_router.dart`，`appRouterProvider` 由 Riverpod 管理，內含 auth 守衛邏輯。

**Firebase**：`firebase_core`、`firebase_auth`、`cloud_firestore`、`firebase_storage`；開發環境使用 `lib/firebase_options_development.dart`，由 `lib/core/config/development.dart` 的 `developmentConfig` 注入。

**主要套件**：`carousel_slider: ^5.1.2`、`cached_network_image: ^3.4.1`、`url_launcher: ^6.3.2`

**目錄結構**：
- `lib/core/` — 路由、config
- `lib/features/auth/` — LoginPage, AuthRepository, auth_providers
- `lib/features/home/` — HomePage, BannerCarousel, cms_models, cms_repository, cms_providers
- `lib/shared/widgets/` — AppNavBar

**Provider 撰寫慣例**：每個 provider 檔案都必須同時 import `flutter_riverpod` 與 `riverpod_annotation`，否則 `Ref` 型別找不到（曾在 cms_providers.dart 踩坑）。

**Why:** `riverpod_annotation` 只提供 annotation，`Ref` 本身定義在 `flutter_riverpod`，缺少後者 import 會在 dart2js 編譯時報 "Type 'Ref' not found"。

**How to apply:** 每次新增 provider 檔案，確保同時有這兩行 import。
