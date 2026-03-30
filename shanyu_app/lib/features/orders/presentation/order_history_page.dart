// lib/features/orders/presentation/order_history_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/app_nav_bar.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/order_models.dart';
import '../providers/order_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _HistoryTokens {
  static const surface = Color(0xFFFAF7F4);
  static const cardBackground = Colors.white;
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const brandBrown = Color(0xFF5C4033);
  static const dividerColor = Color(0xFFE8E0DA);
  static const sectionHeaderBg = Color(0xFFF3EDE8);
  static const errorColor = Color(0xFFB71C1C);

  // 訂單狀態顏色
  static const statusPending = Color(0xFF9E9E9E);
  static const statusConfirmed = Color(0xFF1976D2);
  static const statusProcessing = Color(0xFF7B1FA2);
  static const statusShipped = Color(0xFFE65100);
  static const statusDelivered = Color(0xFF2E7D32);
  static const statusCancelled = Color(0xFFC62828);

  static const pagePadding = 16.0;
  static const desktopMaxWidth = 860.0;
  static const cardRadius = 12.0;
  static const badgeRadius = 6.0;

  static const mobileBreakpoint = 600.0;
}

// ── OrderHistoryPage ──────────────────────────────────────────────────────────

/// 訂單歷史頁（路由 `/orders`）。
///
/// 狀態分支：
/// - 未登入 → 顯示「請先登入」
/// - 載入中 → CircularProgressIndicator
/// - 錯誤 → 錯誤訊息
/// - 空列表 → 「尚無訂單」
/// - 有資料 → 訂單卡片列表
class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _HistoryTokens.surface,
      appBar: const AppNavBar(),
      body: const _OrderHistoryBody(),
    );
  }
}

// ── 頁面主體 ──────────────────────────────────────────────────────────────────

class _OrderHistoryBody extends ConsumerWidget {
  const _OrderHistoryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const _UnauthenticatedView();
    }

    final ordersAsync = ref.watch(orderHistoryProvider);

    return ordersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _HistoryTokens.brandBrown),
      ),
      error: (err, _) => _ErrorView(message: err.toString()),
      data: (orders) {
        if (orders.isEmpty) {
          return const _EmptyOrdersView();
        }

        final screenWidth = MediaQuery.sizeOf(context).width;
        final isDesktop = screenWidth >= _HistoryTokens.mobileBreakpoint;

        Widget list = ListView.separated(
          padding: const EdgeInsets.only(
            left: _HistoryTokens.pagePadding,
            right: _HistoryTokens.pagePadding,
            top: _HistoryTokens.pagePadding,
            bottom: 32,
          ),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _OrderCard(order: orders[index]),
        );

        if (isDesktop) {
          list = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _HistoryTokens.desktopMaxWidth,
              ),
              child: list,
            ),
          );
        }

        return list;
      },
    );
  }
}

// ── 訂單卡片 ──────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy/MM/dd HH:mm');
    final formattedDate = dateFormatter.format(order.createdAt.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: _HistoryTokens.cardBackground,
        borderRadius: BorderRadius.circular(_HistoryTokens.cardRadius),
        border: Border.all(color: _HistoryTokens.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 標題列：訂單編號 + 狀態 badge ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '訂單編號',
                        style: TextStyle(
                          color: _HistoryTokens.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.id,
                        style: const TextStyle(
                          color: _HistoryTokens.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: order.status),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: _HistoryTokens.dividerColor, height: 1),
            const SizedBox(height: 12),

            // ── 訂單資訊列 ──
            Row(
              children: [
                // 日期
                Expanded(
                  child: _InfoItem(
                    label: '訂購日期',
                    value: formattedDate,
                  ),
                ),
                // 商品數量
                Expanded(
                  child: _InfoItem(
                    label: '商品件數',
                    value: '${order.itemCount} 件',
                  ),
                ),
                // 總計
                Expanded(
                  child: _InfoItem(
                    label: '訂單總計',
                    value: 'NT\$ ${order.total}',
                    valueColor: _HistoryTokens.brandBrown,
                    valueBold: true,
                  ),
                ),
              ],
            ),

            // ── 商品名稱摘要 ──
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _buildItemSummary(order.items),
                style: const TextStyle(
                  color: _HistoryTokens.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildItemSummary(List<OrderItemModel> items) {
    if (items.isEmpty) return '';
    final names = items.map((i) => i.productName).toList();
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]}、${names[1]}';
    return '${names[0]}、${names[1]} 等 ${names.length} 件商品';
  }
}

// ── 狀態 Badge ────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  static Color _colorFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _HistoryTokens.statusPending;
      case OrderStatus.confirmed:
        return _HistoryTokens.statusConfirmed;
      case OrderStatus.processing:
        return _HistoryTokens.statusProcessing;
      case OrderStatus.shipped:
        return _HistoryTokens.statusShipped;
      case OrderStatus.delivered:
        return _HistoryTokens.statusDelivered;
      case OrderStatus.cancelled:
        return _HistoryTokens.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(_HistoryTokens.badgeRadius),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── 資訊項目 ──────────────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _HistoryTokens.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _HistoryTokens.textPrimary,
            fontSize: 13,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── 未登入視圖 ────────────────────────────────────────────────────────────────

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_HistoryTokens.pagePadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              color: _HistoryTokens.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              '請先登入',
              style: TextStyle(
                color: _HistoryTokens.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '登入後即可查看訂單紀錄',
              style: TextStyle(
                color: _HistoryTokens.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => context.go('/login'),
              style: FilledButton.styleFrom(
                backgroundColor: _HistoryTokens.brandBrown,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_HistoryTokens.cardRadius),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('前往登入'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 空訂單視圖 ────────────────────────────────────────────────────────────────

class _EmptyOrdersView extends StatelessWidget {
  const _EmptyOrdersView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_HistoryTokens.pagePadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              color: _HistoryTokens.textSecondary,
              size: 72,
            ),
            const SizedBox(height: 20),
            const Text(
              '尚無訂單',
              style: TextStyle(
                color: _HistoryTokens.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '您目前還沒有任何訂單紀錄',
              style: TextStyle(
                color: _HistoryTokens.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _HistoryTokens.brandBrown,
                side: const BorderSide(color: _HistoryTokens.brandBrown),
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_HistoryTokens.cardRadius),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('前往購物'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 錯誤視圖 ──────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_HistoryTokens.pagePadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: _HistoryTokens.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '載入訂單時發生錯誤',
              style: TextStyle(
                color: _HistoryTokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: _HistoryTokens.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
