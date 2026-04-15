// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ordersAdminRepositoryHash() =>
    r'ada7cd4978d48f96ae9f9df4cc3644af63611945';

/// See also [ordersAdminRepository].
@ProviderFor(ordersAdminRepository)
final ordersAdminRepositoryProvider = Provider<OrdersAdminRepository>.internal(
  ordersAdminRepository,
  name: r'ordersAdminRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ordersAdminRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrdersAdminRepositoryRef = ProviderRef<OrdersAdminRepository>;
String _$adminOrdersHash() => r'd9fdee1b03102def9dfd4ee97a4560e0380e8092';

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

/// 監聽訂單列表，可按 [status] 篩選（null 表示全部）。
///
/// Copied from [adminOrders].
@ProviderFor(adminOrders)
const adminOrdersProvider = AdminOrdersFamily();

/// 監聽訂單列表，可按 [status] 篩選（null 表示全部）。
///
/// Copied from [adminOrders].
class AdminOrdersFamily extends Family<AsyncValue<List<OrderModel>>> {
  /// 監聽訂單列表，可按 [status] 篩選（null 表示全部）。
  ///
  /// Copied from [adminOrders].
  const AdminOrdersFamily();

  /// 監聽訂單列表，可按 [status] 篩選（null 表示全部）。
  ///
  /// Copied from [adminOrders].
  AdminOrdersProvider call({OrderStatus? status}) {
    return AdminOrdersProvider(status: status);
  }

  @override
  AdminOrdersProvider getProviderOverride(
    covariant AdminOrdersProvider provider,
  ) {
    return call(status: provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'adminOrdersProvider';
}

/// 監聽訂單列表，可按 [status] 篩選（null 表示全部）。
///
/// Copied from [adminOrders].
class AdminOrdersProvider extends AutoDisposeStreamProvider<List<OrderModel>> {
  /// 監聽訂單列表，可按 [status] 篩選（null 表示全部）。
  ///
  /// Copied from [adminOrders].
  AdminOrdersProvider({OrderStatus? status})
    : this._internal(
        (ref) => adminOrders(ref as AdminOrdersRef, status: status),
        from: adminOrdersProvider,
        name: r'adminOrdersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$adminOrdersHash,
        dependencies: AdminOrdersFamily._dependencies,
        allTransitiveDependencies: AdminOrdersFamily._allTransitiveDependencies,
        status: status,
      );

  AdminOrdersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final OrderStatus? status;

  @override
  Override overrideWith(
    Stream<List<OrderModel>> Function(AdminOrdersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdminOrdersProvider._internal(
        (ref) => create(ref as AdminOrdersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<OrderModel>> createElement() {
    return _AdminOrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminOrdersProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdminOrdersRef on AutoDisposeStreamProviderRef<List<OrderModel>> {
  /// The parameter `status` of this provider.
  OrderStatus? get status;
}

class _AdminOrdersProviderElement
    extends AutoDisposeStreamProviderElement<List<OrderModel>>
    with AdminOrdersRef {
  _AdminOrdersProviderElement(super.provider);

  @override
  OrderStatus? get status => (origin as AdminOrdersProvider).status;
}

String _$adminOrderCountHash() => r'bfd2b85b46477ab38d3e3157916c20a876c0394b';

/// 監聽各狀態訂單數量。
///
/// Copied from [adminOrderCount].
@ProviderFor(adminOrderCount)
final adminOrderCountProvider =
    AutoDisposeStreamProvider<Map<OrderStatus, int>>.internal(
      adminOrderCount,
      name: r'adminOrderCountProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminOrderCountHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminOrderCountRef =
    AutoDisposeStreamProviderRef<Map<OrderStatus, int>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
