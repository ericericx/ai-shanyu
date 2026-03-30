// lib/features/orders/providers/order_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/order_repository.dart';
import '../models/order_models.dart';

part 'order_providers.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

/// OrderRepository 單例。App 生命週期內保持存活。
@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) {
  return OrderRepository();
}

// ── Order History Provider ────────────────────────────────────────────────────

/// 取得目前登入使用者的訂單歷史。
///
/// 回傳 [AsyncValue<List<OrderModel>>]。
/// 呼叫後端 getOrderHistory Callable Function（取前 20 筆）。
@riverpod
Future<List<OrderModel>> orderHistory(Ref ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrderHistory(limit: 20);
}
