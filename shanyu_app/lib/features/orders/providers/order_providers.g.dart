// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$orderRepositoryHash() => r'f9216432da9201e76e6dec2c55d2b5daacafa903';

/// OrderRepository 單例。App 生命週期內保持存活。
///
/// Copied from [orderRepository].
@ProviderFor(orderRepository)
final orderRepositoryProvider = Provider<OrderRepository>.internal(
  orderRepository,
  name: r'orderRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orderRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrderRepositoryRef = ProviderRef<OrderRepository>;
String _$orderHistoryHash() => r'5adf10a9ee5ceb4e4939cc2a6ea4a61b23d7c306';

/// 取得目前登入使用者的訂單歷史。
///
/// 回傳 [AsyncValue<List<OrderModel>>]。
/// 呼叫後端 getOrderHistory Callable Function（取前 20 筆）。
///
/// Copied from [orderHistory].
@ProviderFor(orderHistory)
final orderHistoryProvider =
    AutoDisposeFutureProvider<List<OrderModel>>.internal(
      orderHistory,
      name: r'orderHistoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$orderHistoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrderHistoryRef = AutoDisposeFutureProviderRef<List<OrderModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
