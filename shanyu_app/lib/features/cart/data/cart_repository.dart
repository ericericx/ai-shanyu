// lib/features/cart/data/cart_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_models.dart';

/// 購物車 Firestore 資料存取層。
///
/// 對應集合：`carts/{userId}`
/// 所有操作均以 `variantId` 作為商品識別鍵。
class CartRepository {
  CartRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _cartRef(String userId) =>
      _firestore.collection('carts').doc(userId);

  // ── 即時監聽 ──────────────────────────────────────────────────────────────

  /// 即時監聽指定使用者的購物車。
  /// 文件不存在時回傳 [Cart.empty]。
  Stream<Cart> watchCart(String userId) {
    return _cartRef(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return Cart.empty;
      return Cart.fromFirestore(snapshot);
    });
  }

  // ── 寫入操作 ──────────────────────────────────────────────────────────────

  /// 加入商品，若 variantId 已存在則累加數量。
  Future<void> addItem(String userId, CartItem item) async {
    final ref = _cartRef(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        // 購物車尚不存在，直接建立
        transaction.set(ref, {
          'items': [item.toMap()],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final cart = Cart.fromFirestore(snapshot);
      final existingIndex =
          cart.items.indexWhere((i) => i.variantId == item.variantId);

      List<Map<String, dynamic>> updatedItems;
      if (existingIndex >= 0) {
        // 已存在 → 累加數量
        final existing = cart.items[existingIndex];
        final updated = existing.copyWith(
          quantity: existing.quantity + item.quantity,
        );
        updatedItems = [
          for (int i = 0; i < cart.items.length; i++)
            i == existingIndex ? updated.toMap() : cart.items[i].toMap(),
        ];
      } else {
        // 不存在 → 新增
        updatedItems = [...cart.items.map((i) => i.toMap()), item.toMap()];
      }

      transaction.update(ref, {
        'items': updatedItems,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 更新指定 variantId 的數量。數量 <= 0 時自動移除該項目。
  Future<void> updateQuantity(
    String userId,
    String variantId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      await removeItem(userId, variantId);
      return;
    }

    final ref = _cartRef(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final cart = Cart.fromFirestore(snapshot);
      final updatedItems = cart.items.map((item) {
        if (item.variantId == variantId) {
          return item.copyWith(quantity: quantity).toMap();
        }
        return item.toMap();
      }).toList();

      transaction.update(ref, {
        'items': updatedItems,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 從購物車中移除指定 variantId 的商品。
  Future<void> removeItem(String userId, String variantId) async {
    final ref = _cartRef(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final cart = Cart.fromFirestore(snapshot);
      final updatedItems = cart.items
          .where((item) => item.variantId != variantId)
          .map((item) => item.toMap())
          .toList();

      transaction.update(ref, {
        'items': updatedItems,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 清空整個購物車（保留文件，items 設為空陣列）。
  Future<void> clearCart(String userId) async {
    await _cartRef(userId).set({
      'items': <Map<String, dynamic>>[],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
