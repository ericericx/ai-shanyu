// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cms_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cmsRepositoryHash() => r'5678351cce01bb95772df9082cdd54d58af8dbe8';

/// See also [cmsRepository].
@ProviderFor(cmsRepository)
final cmsRepositoryProvider = Provider<CmsRepository>.internal(
  cmsRepository,
  name: r'cmsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cmsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CmsRepositoryRef = ProviderRef<CmsRepository>;
String _$cmsHomepageHash() => r'7c333f54dec6a4b4e6cdd63d0fd13f578d1afbb4';

/// 監聽 Firestore `cms/homepage`，提供首頁 CMS 資料的即時串流。
///
/// - `AsyncData(CmsHomepage)` → 已取得資料
/// - `AsyncData(null)`        → 文件不存在
/// - `AsyncLoading()`         → 初始化中
/// - `AsyncError()`           → 讀取失敗
///
/// Copied from [cmsHomepage].
@ProviderFor(cmsHomepage)
final cmsHomepageProvider = AutoDisposeStreamProvider<CmsHomepage?>.internal(
  cmsHomepage,
  name: r'cmsHomepageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cmsHomepageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CmsHomepageRef = AutoDisposeStreamProviderRef<CmsHomepage?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
