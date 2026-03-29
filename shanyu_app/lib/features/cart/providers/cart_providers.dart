// lib/features/cart/providers/cart_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/cart_repository.dart';
import '../models/cart_models.dart';

part 'cart_providers.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

/// CartRepository 單例。App 生命週期內保持存活。
@Riverpod(keepAlive: true)
CartRepository cartRepository(Ref ref) {
  return CartRepository();
}

// ── Cart Stream Provider ──────────────────────────────────────────────────────

/// 即時監聽目前登入使用者的購物車。
///
/// - 未登入 → 回傳 `null`（不觸發 Firestore 請求）
/// - 已登入 → 回傳 `Stream<Cart>`，文件不存在時為 [Cart.empty]
@riverpod
Stream<Cart?> cart(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(cartRepositoryProvider).watchCart(user.uid);
}

// ── Cart Item Count Provider ──────────────────────────────────────────────────

/// 購物車商品總件數（加總所有 quantity），用於 NavBar badge 顯示。
///
/// 未登入或資料尚未載入時回傳 0。
@riverpod
int cartItemCount(Ref ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.valueOrNull?.itemCount ?? 0;
}
