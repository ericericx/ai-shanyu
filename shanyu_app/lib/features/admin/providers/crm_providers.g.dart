// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crm_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$crmRepositoryHash() => r'f5c19079b42c3bae6eb377e3ead5a542c001423c';

/// See also [crmRepository].
@ProviderFor(crmRepository)
final crmRepositoryProvider = Provider<CrmRepository>.internal(
  crmRepository,
  name: r'crmRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$crmRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CrmRepositoryRef = ProviderRef<CrmRepository>;
String _$topProductsHash() => r'cc113a258ffca6b63910852e573e31a92b52c226';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [topProducts].
@ProviderFor(topProducts)
const topProductsProvider = TopProductsFamily();

/// See also [topProducts].
class TopProductsFamily extends Family<AsyncValue<List<PopularProduct>>> {
  /// See also [topProducts].
  const TopProductsFamily();

  /// See also [topProducts].
  TopProductsProvider call({int limit = 5}) {
    return TopProductsProvider(limit: limit);
  }

  @override
  TopProductsProvider getProviderOverride(
    covariant TopProductsProvider provider,
  ) {
    return call(limit: provider.limit);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'topProductsProvider';
}

/// See also [topProducts].
class TopProductsProvider
    extends AutoDisposeFutureProvider<List<PopularProduct>> {
  /// See also [topProducts].
  TopProductsProvider({int limit = 5})
    : this._internal(
        (ref) => topProducts(ref as TopProductsRef, limit: limit),
        from: topProductsProvider,
        name: r'topProductsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$topProductsHash,
        dependencies: TopProductsFamily._dependencies,
        allTransitiveDependencies: TopProductsFamily._allTransitiveDependencies,
        limit: limit,
      );

  TopProductsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.limit,
  }) : super.internal();

  final int limit;

  @override
  Override overrideWith(
    FutureOr<List<PopularProduct>> Function(TopProductsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TopProductsProvider._internal(
        (ref) => create(ref as TopProductsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        limit: limit,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PopularProduct>> createElement() {
    return _TopProductsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TopProductsProvider && other.limit == limit;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, limit.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TopProductsRef on AutoDisposeFutureProviderRef<List<PopularProduct>> {
  /// The parameter `limit` of this provider.
  int get limit;
}

class _TopProductsProviderElement
    extends AutoDisposeFutureProviderElement<List<PopularProduct>>
    with TopProductsRef {
  _TopProductsProviderElement(super.provider);

  @override
  int get limit => (origin as TopProductsProvider).limit;
}

String _$crmViewsNotifierHash() => r'7318680c37ab1d9674375a01783cb5c337d466b2';

/// 瀏覽記錄分頁 Notifier。
///
/// Copied from [CrmViewsNotifier].
@ProviderFor(CrmViewsNotifier)
final crmViewsNotifierProvider =
    AutoDisposeNotifierProvider<CrmViewsNotifier, CrmViewsState>.internal(
      CrmViewsNotifier.new,
      name: r'crmViewsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$crmViewsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CrmViewsNotifier = AutoDisposeNotifier<CrmViewsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
