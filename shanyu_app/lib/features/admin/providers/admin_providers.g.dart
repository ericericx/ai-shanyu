// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isAdminHash() => r'1583c27e88c7ca32c95dc7af6e5c93d2a3928354';

/// 讀取 Firebase Auth token claims 中的 `admin` 欄位。
/// 回傳 `true` 表示目前使用者具備管理員身份。
///
/// Copied from [isAdmin].
@ProviderFor(isAdmin)
final isAdminProvider = AutoDisposeFutureProvider<bool>.internal(
  isAdmin,
  name: r'isAdminProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAdminHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAdminRef = AutoDisposeFutureProviderRef<bool>;
String _$adminGuardHash() => r'd27f803a479e03adf6051be231cd6395e42ea60a';

/// 確認目前使用者為管理員，否則拋出 [UnauthorizedException]。
/// 供 CMS Repository 在執行寫入操作前呼叫。
///
/// Copied from [adminGuard].
@ProviderFor(adminGuard)
final adminGuardProvider = AutoDisposeFutureProvider<void>.internal(
  adminGuard,
  name: r'adminGuardProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminGuardHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminGuardRef = AutoDisposeFutureProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
