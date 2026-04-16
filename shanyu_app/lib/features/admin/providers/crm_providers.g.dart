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

String _$overviewStatsHash() => r'1f4de5e75e1cf71ee59a42e5377a6a8395ace0e4';

/// See also [overviewStats].
@ProviderFor(overviewStats)
final overviewStatsProvider = AutoDisposeFutureProvider<OverviewStats>.internal(
  overviewStats,
  name: r'overviewStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$overviewStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OverviewStatsRef = AutoDisposeFutureProviderRef<OverviewStats>;
String _$topPagesHash() => r'e17c5c08051ac0a1b8b235328f6a05757148385c';

/// See also [topPages].
@ProviderFor(topPages)
const topPagesProvider = TopPagesFamily();

/// See also [topPages].
class TopPagesFamily extends Family<AsyncValue<List<PopularPage>>> {
  /// See also [topPages].
  const TopPagesFamily();

  /// See also [topPages].
  TopPagesProvider call({required DateTime since}) {
    return TopPagesProvider(since: since);
  }

  @override
  TopPagesProvider getProviderOverride(covariant TopPagesProvider provider) {
    return call(since: provider.since);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'topPagesProvider';
}

/// See also [topPages].
class TopPagesProvider extends AutoDisposeFutureProvider<List<PopularPage>> {
  /// See also [topPages].
  TopPagesProvider({required DateTime since})
    : this._internal(
        (ref) => topPages(ref as TopPagesRef, since: since),
        from: topPagesProvider,
        name: r'topPagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$topPagesHash,
        dependencies: TopPagesFamily._dependencies,
        allTransitiveDependencies: TopPagesFamily._allTransitiveDependencies,
        since: since,
      );

  TopPagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.since,
  }) : super.internal();

  final DateTime since;

  @override
  Override overrideWith(
    FutureOr<List<PopularPage>> Function(TopPagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TopPagesProvider._internal(
        (ref) => create(ref as TopPagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        since: since,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PopularPage>> createElement() {
    return _TopPagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TopPagesProvider && other.since == since;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, since.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TopPagesRef on AutoDisposeFutureProviderRef<List<PopularPage>> {
  /// The parameter `since` of this provider.
  DateTime get since;
}

class _TopPagesProviderElement
    extends AutoDisposeFutureProviderElement<List<PopularPage>>
    with TopPagesRef {
  _TopPagesProviderElement(super.provider);

  @override
  DateTime get since => (origin as TopPagesProvider).since;
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
