import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/providers/auth_providers.dart';

part 'admin_providers.g.dart';

// ── isAdminProvider ───────────────────────────────────────────────────────────

/// 讀取 Firebase Auth token claims 中的 `admin` 欄位。
/// 回傳 `true` 表示目前使用者具備管理員身份。
@riverpod
Future<bool> isAdmin(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  // Force refresh so custom claim `admin` matches Firebase after role / setAdminClaim.
  final idTokenResult = await user.getIdTokenResult(true);
  final claims = idTokenResult.claims;
  final isAdminUser = claims?['admin'] == true;
  if (kDebugMode) {
    debugPrint(
      '[ShanYu:Admin] isAdmin check uid=${user.uid} '
      'claimsKeys=${claims?.keys.toList()} '
      'adminRaw=${claims?['admin']} => isAdmin=$isAdminUser',
    );
  }
  return isAdminUser;
}

// ── adminGuard ────────────────────────────────────────────────────────────────

/// 確認目前使用者為管理員，否則拋出 [UnauthorizedException]。
/// 供 CMS Repository 在執行寫入操作前呼叫。
@riverpod
Future<void> adminGuard(Ref ref) async {
  final isAdminUser = await ref.watch(isAdminProvider.future);
  if (!isAdminUser) {
    throw const UnauthorizedException('需要管理員權限才能執行此操作。');
  }
}

// ── UnauthorizedException ─────────────────────────────────────────────────────

class UnauthorizedException implements Exception {
  const UnauthorizedException(this.message);

  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}
