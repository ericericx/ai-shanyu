// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartRepositoryHash() => r'd4dada75301ee1b1faf5da873e84dc5d3188265b';

/// CartRepository 單例。App 生命週期內保持存活。
///
/// Copied from [cartRepository].
@ProviderFor(cartRepository)
final cartRepositoryProvider = Provider<CartRepository>.internal(
  cartRepository,
  name: r'cartRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartRepositoryRef = ProviderRef<CartRepository>;
String _$cartHash() => r'25b846953716842f2a347dd61fd215c14c3504b3';

/// 即時監聽目前登入使用者的購物車。
///
/// - 未登入 → 回傳 `null`（不觸發 Firestore 請求）
/// - 已登入 → 回傳 `Stream<Cart>`，文件不存在時為 [Cart.empty]
///
/// Copied from [cart].
@ProviderFor(cart)
final cartProvider = AutoDisposeStreamProvider<Cart?>.internal(
  cart,
  name: r'cartProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartRef = AutoDisposeStreamProviderRef<Cart?>;
String _$cartItemCountHash() => r'19c90f53532b0480dc2029a2f3b7ccd167f95384';

/// 購物車商品總件數（加總所有 quantity），用於 NavBar badge 顯示。
///
/// 未登入或資料尚未載入時回傳 0。
///
/// Copied from [cartItemCount].
@ProviderFor(cartItemCount)
final cartItemCountProvider = AutoDisposeProvider<int>.internal(
  cartItemCount,
  name: r'cartItemCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cartItemCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartItemCountRef = AutoDisposeProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
