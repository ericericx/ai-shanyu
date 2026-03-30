// lib/features/orders/models/order_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// ── OrderStatus ───────────────────────────────────────────────────────────────

/// 訂單狀態列舉。
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled;

  /// 從字串解析狀態，無法識別時回傳 [pending]。
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  /// 中文顯示名稱。
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return '待確認';
      case OrderStatus.confirmed:
        return '已確認';
      case OrderStatus.processing:
        return '處理中';
      case OrderStatus.shipped:
        return '已出貨';
      case OrderStatus.delivered:
        return '已送達';
      case OrderStatus.cancelled:
        return '已取消';
    }
  }
}

// ── ShippingAddress ───────────────────────────────────────────────────────────

/// 收件地址資料模型。
class ShippingAddress {
  const ShippingAddress({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.postalCode,
  });

  final String name;
  final String phone;
  final String address;
  final String city;
  final String postalCode;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'postalCode': postalCode,
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      city: (map['city'] as String?) ?? '',
      postalCode: (map['postalCode'] as String?) ?? '',
    );
  }
}

// ── OrderItemModel ────────────────────────────────────────────────────────────

/// 訂單中的單一商品項目。
class OrderItemModel {
  const OrderItemModel({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.price,
    required this.quantity,
    required this.isPreorder,
    this.estimatedShipDate,
  });

  final String productId;
  final String variantId;
  final String productName;
  final String variantName;

  /// 單價，單位：新台幣（整數）
  final int price;

  /// 數量
  final int quantity;

  /// 是否為預購商品
  final bool isPreorder;

  /// 預估出貨日（格式：YYYY-MM-DD，預購商品才有）
  final String? estimatedShipDate;

  /// 此項目小計
  int get subtotal => price * quantity;

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: (map['productId'] as String?) ?? '',
      variantId: (map['variantId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      variantName: (map['variantName'] as String?) ?? '',
      price: (map['price'] as int?) ?? 0,
      quantity: (map['quantity'] as int?) ?? 1,
      isPreorder: (map['isPreorder'] as bool?) ?? false,
      estimatedShipDate: map['estimatedShipDate'] as String?,
    );
  }

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
    };
  }
}

// ── OrderModel ────────────────────────────────────────────────────────────────

/// 完整訂單資料模型。
class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.status,
    required this.shippingAddress,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String userId;
  final List<OrderItemModel> items;

  /// 商品小計（不含運費），單位：新台幣
  final int subtotal;

  /// 運費，單位：新台幣
  final int shippingFee;

  /// 總計（含運費），單位：新台幣
  final int total;

  final OrderStatus status;
  final ShippingAddress shippingAddress;

  /// 備註（選填）
  final String? note;

  final DateTime createdAt;

  /// 商品總件數（加總所有 quantity）
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(OrderItemModel.fromMap)
        .toList();

    final addressMap =
        map['shippingAddress'] as Map<String, dynamic>? ?? {};

    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.now();

    return OrderModel(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      items: items,
      subtotal: (map['subtotal'] as int?) ?? 0,
      shippingFee: (map['shippingFee'] as int?) ?? 0,
      total: (map['total'] as int?) ?? 0,
      status: OrderStatus.fromString((map['status'] as String?) ?? 'pending'),
      shippingAddress: ShippingAddress.fromMap(addressMap),
      note: map['note'] as String?,
      createdAt: createdAt,
    );
  }
}
