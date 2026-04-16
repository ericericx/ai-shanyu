// lib/features/orders/data/order_repository.dart

import 'package:cloud_functions/cloud_functions.dart';

import '../../cart/models/cart_models.dart';
import '../models/order_models.dart';

/// 訂單 Firebase Callable Functions 資料存取層。
///
/// createOrder — 建立訂單，回傳 orderId
/// getOrderHistory — 取得訂單歷史列表
class OrderRepository {
  OrderRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-east1');

  final FirebaseFunctions _functions;

  // ── 建立訂單 ───────────────────────────────────────────────────────────────

  /// 呼叫後端 `createOrder` Callable Function，成功後回傳訂單 ID。
  ///
  /// 傳入購物車商品清單、收件地址與付款方式，後端負責計算運費與總計。
  Future<String> createOrder({
    required List<CartItem> items,
    required ShippingAddress address,
    required PaymentMethod paymentMethod,
    String? note,
  }) async {
    final callable = _functions.httpsCallable('createOrder');

    final itemsPayload = items
        .map(
          (item) => {
            'productId': item.productId,
            'variantId': item.variantId,
            'productName': item.productName,
            'variantName': item.variantName,
            'price': item.price,
            'quantity': item.quantity,
            'isPreorder': item.isPreorder,
            if (item.estimatedShipDate != null)
              'estimatedShipDate': item.estimatedShipDate,
          },
        )
        .toList();

    final result = await callable.call<Map<String, dynamic>>({
      'items': itemsPayload,
      'shippingAddress': address.toMap(),
      'paymentMethod': paymentMethod.name,
      if (note != null && note.isNotEmpty) 'note': note,
    });

    final orderId = result.data['orderId'] as String?;
    if (orderId == null || orderId.isEmpty) {
      throw Exception('createOrder 回傳的 orderId 為空');
    }

    return orderId;
  }

  // ── 取得訂單歷史 ──────────────────────────────────────────────────────────

  /// 呼叫後端 `getOrderHistory` Callable Function，回傳訂單列表。
  ///
  /// [limit] 每頁筆數，預設 10。
  /// [lastOrderId] 分頁游標，傳入上一頁最後一筆訂單的 ID（選填）。
  Future<List<OrderModel>> getOrderHistory({
    int limit = 10,
    String? lastOrderId,
  }) async {
    final callable = _functions.httpsCallable('getOrderHistory');

    final result = await callable.call<Map<String, dynamic>>({
      'limit': limit,
      if (lastOrderId != null) 'lastOrderId': lastOrderId,
    });

    final rawOrders = result.data['orders'] as List<dynamic>? ?? [];

    return rawOrders
        .whereType<Map<String, dynamic>>()
        .map((map) {
          final id = (map['id'] as String?) ?? '';
          return OrderModel.fromMap(id, map);
        })
        .toList();
  }
}
