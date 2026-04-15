// lib/features/admin/data/orders_admin_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../orders/models/order_models.dart';

// ── OrdersAdminRepository ─────────────────────────────────────────────────────

/// 訂單管理員資料層。
///
/// 提供後台管理員讀取、監聽與更新訂單的操作。
class OrdersAdminRepository {
  OrdersAdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _kOrders = 'orders';

  // ── 訂單列表 ──────────────────────────────────────────────────────────────────

  /// 監聽訂單列表，可依 [status] 篩選，按 createdAt 降序排列。
  /// [limit] 預設 20 筆。
  Stream<List<OrderModel>> watchOrders({
    OrderStatus? status,
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_kOrders)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // ── 訂單數量 ───────────────────────────────────────────────────────────────────

  /// 監聽各狀態訂單數量，回傳 `Map<OrderStatus, int>`。
  Stream<Map<OrderStatus, int>> watchOrderCount() {
    return _firestore
        .collection(_kOrders)
        .snapshots()
        .map((snap) {
      final countMap = <OrderStatus, int>{
        for (final s in OrderStatus.values) s: 0,
      };
      for (final doc in snap.docs) {
        final rawStatus = (doc.data()['status'] as String?) ?? 'pending';
        final status = OrderStatus.fromString(rawStatus);
        countMap[status] = (countMap[status] ?? 0) + 1;
      }
      return countMap;
    });
  }

  // ── 狀態更新 ───────────────────────────────────────────────────────────────────

  /// 更新指定訂單的狀態，同步寫入 updatedAt 時間戳記。
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    await _firestore.collection(_kOrders).doc(orderId).update({
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
