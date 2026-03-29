import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';

part 'auth_providers.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

/// AuthRepository 單例。整個 App 共用同一個實例。
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository();

// ── Auth 狀態 StreamProvider ──────────────────────────────────────────────────

/// 監聽 Firebase Auth 狀態流。
/// - `AsyncData(User)` → 已登入
/// - `AsyncData(null)`  → 未登入
/// - `AsyncLoading()`   → 初始化中
@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}

// ── 目前使用者 Provider ───────────────────────────────────────────────────────

/// 取得目前登入的 User 物件（同步，未登入為 null）。
/// 依賴 authStateProvider 的最新值，確保資料一致。
@riverpod
User? currentUser(Ref ref) {
  return ref.watch(authStateProvider).valueOrNull;
}
