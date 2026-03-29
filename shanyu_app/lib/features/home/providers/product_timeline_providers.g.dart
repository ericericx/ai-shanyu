// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_timeline_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productTimelineRepositoryHash() =>
    r'003bbaabae6a95642dc127a0defebebdaec535af';

/// ProductTimelineRepository 單例。
///
/// Copied from [productTimelineRepository].
@ProviderFor(productTimelineRepository)
final productTimelineRepositoryProvider =
    Provider<ProductTimelineRepository>.internal(
      productTimelineRepository,
      name: r'productTimelineRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$productTimelineRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProductTimelineRepositoryRef = ProviderRef<ProductTimelineRepository>;
String _$productTimelineHash() => r'326f5418447ed563aceea7f96668e6728ebcceef';

/// 監聽所有 active 商品的 Stream，供 ProductTimeline 元件消費。
///
/// Copied from [productTimeline].
@ProviderFor(productTimeline)
final productTimelineProvider =
    AutoDisposeStreamProvider<List<TimelineProduct>>.internal(
      productTimeline,
      name: r'productTimelineProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$productTimelineHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProductTimelineRef =
    AutoDisposeStreamProviderRef<List<TimelineProduct>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
