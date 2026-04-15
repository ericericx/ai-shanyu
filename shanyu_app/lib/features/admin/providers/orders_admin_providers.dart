// lib/features/admin/providers/orders_admin_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../orders/models/order_models.dart';
import '../data/orders_admin_repository.dart';

part 'orders_admin_providers.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
OrdersAdminRepository ordersAdminRepository(Ref ref) =>
    OrdersAdminRepository();

// ── 訂單列表 StreamProvider ────────────────────────────────────────────────────

/// 監聽訂單列表，可按 [status] 篩選（null 表示全部）。
@riverpod
Stream<List<OrderModel>> adminOrders(Ref ref, {OrderStatus? status}) {
  return ref
      .watch(ordersAdminRepositoryProvider)
      .watchOrders(status: status);
}

// ── 訂單數量 StreamProvider ────────────────────────────────────────────────────

/// 監聽各狀態訂單數量。
@riverpod
Stream<Map<OrderStatus, int>> adminOrderCount(Ref ref) {
  return ref.watch(ordersAdminRepositoryProvider).watchOrderCount();
}
