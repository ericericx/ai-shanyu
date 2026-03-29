// lib/features/cart/models/cart_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// ── CartItem ──────────────────────────────────────────────────────────────────

/// 購物車中的單一商品項目。
/// 對應 Firestore `carts/{userId}/items[]` 陣列元素。
class CartItem {
  CartItem({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.price,
    required this.quantity,
    required this.isPreorder,
    required this.imageUrl,
    this.estimatedShipDate,
  });

  final String productId;
  final String variantId;
  final String productName;
  final String variantName;

  /// 單價，單位：新台幣（整數）
  final int price;

  /// 數量（可變，允許加減操作）
  int quantity;

  /// 是否為預購商品
  final bool isPreorder;

  /// 預估出貨日（格式：YYYY-MM-DD，預購商品才有）
  final String? estimatedShipDate;

  /// 商品縮圖 URL
  final String imageUrl;

  /// 此項目小計
  int get subtotal => price * quantity;

  /// 從 Firestore Map 解析。
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: (map['productId'] as String?) ?? '',
      variantId: (map['variantId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      variantName: (map['variantName'] as String?) ?? '',
      price: (map['price'] as int?) ?? 0,
      quantity: (map['quantity'] as int?) ?? 1,
      isPreorder: (map['isPreorder'] as bool?) ?? false,
      estimatedShipDate: map['estimatedShipDate'] as String?,
      imageUrl: (map['imageUrl'] as String?) ?? '',
    );
  }

  /// 轉換為 Firestore Map。
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'variantId': variantId,
      'productName': productName,
      'variantName': variantName,
      'price': price,
      'quantity': quantity,
      'isPreorder': isPreorder,
      if (estimatedShipDate != null) 'estimatedShipDate': estimatedShipDate,
      'imageUrl': imageUrl,
    };
  }

  /// 複製並覆寫部分欄位。
  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      variantId: variantId,
      productName: productName,
      variantName: variantName,
      price: price,
      quantity: quantity ?? this.quantity,
      isPreorder: isPreorder,
      estimatedShipDate: estimatedShipDate,
      imageUrl: imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          variantId == other.variantId;

  @override
  int get hashCode => variantId.hashCode;
}

// ── Cart ──────────────────────────────────────────────────────────────────────

/// 購物車資料模型。
/// 對應 Firestore `carts/{userId}` 文件。
class Cart {
  const Cart({
    required this.items,
    this.updatedAt,
  });

  final List<CartItem> items;
  final DateTime? updatedAt;

  /// 所有商品的總金額。
  int get totalPrice => items.fold(0, (sum, item) => sum + item.subtotal);

  /// 所有商品的總件數（加總 quantity）。
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// 一般商品子列表。
  List<CartItem> get regularItems =>
      items.where((item) => !item.isPreorder).toList();

  /// 預購商品子列表。
  List<CartItem> get preorderItems =>
      items.where((item) => item.isPreorder).toList();

  /// 是否為空購物車。
  bool get isEmpty => items.isEmpty;

  /// 從 Firestore DocumentSnapshot 解析。
  factory Cart.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(CartItem.fromMap)
        .toList();
    final updatedAtTs = data['updatedAt'];
    return Cart(
      items: items,
      updatedAt: updatedAtTs is Timestamp ? updatedAtTs.toDate() : null,
    );
  }

  /// 空購物車常數。
  static const empty = Cart(items: []);
}
