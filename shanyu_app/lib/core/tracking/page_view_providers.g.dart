// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_view_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pageViewTrackerHash() => r'91136cfc143884ebe75a15ba5ac17acbe6d61522';

/// 全站頁面瀏覽追蹤器 Provider。
///
/// keepAlive：整個 App 生命週期共用同一個 tracker 實例，
/// 確保 sessionId 與 userId 狀態持續有效。
///
/// Copied from [pageViewTracker].
@ProviderFor(pageViewTracker)
final pageViewTrackerProvider = Provider<PageViewTracker>.internal(
  pageViewTracker,
  name: r'pageViewTrackerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pageViewTrackerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PageViewTrackerRef = ProviderRef<PageViewTracker>;
String _$pageViewTrackerObserverHash() =>
    r'c48c671278fbc4a9f814846276638c5840494f24';

/// GoRouter observers 所需的 NavigatorObserver Provider。
///
/// keepAlive：與 appRouterProvider 同生命週期，
/// 確保 observer 實例不被意外 dispose。
///
/// Copied from [pageViewTrackerObserver].
@ProviderFor(pageViewTrackerObserver)
final pageViewTrackerObserverProvider =
    Provider<PageViewTrackerObserver>.internal(
      pageViewTrackerObserver,
      name: r'pageViewTrackerObserverProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pageViewTrackerObserverHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PageViewTrackerObserverRef = ProviderRef<PageViewTrackerObserver>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
