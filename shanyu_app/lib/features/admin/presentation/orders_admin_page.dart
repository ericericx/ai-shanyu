// lib/features/admin/presentation/orders_admin_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_design_tokens.dart';
import '../../../shared/utils/price_format.dart';
import '../../orders/models/order_models.dart';
import '../data/orders_admin_repository.dart';
import '../providers/orders_admin_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _Tokens {
  static const surface = AppDesignTokens.surfaceAlt;
  static const brandRed = AppDesignTokens.brandRed;
  static const textPrimary = AppDesignTokens.textPrimary;
  static const textSecondary = AppDesignTokens.textSecondary;
  static const divider = AppDesignTokens.divider;
  static const cardBg = Colors.white;

  static const cardRadius = 8.0;
  static const pagePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);
}

// ── 狀態顏色對應 ──────────────────────────────────────────────────────────────

Color _statusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Colors.orange;
    case OrderStatus.confirmed:
      return Colors.blue;
    case OrderStatus.processing:
      return Colors.purple;
    case OrderStatus.shipped:
      return Colors.green;
    case OrderStatus.delivered:
      return Colors.grey;
    case OrderStatus.cancelled:
      return Colors.red;
  }
}

// ── 日期格式 ──────────────────────────────────────────────────────────────────

final _dateFormat = DateFormat('yyyy/MM/dd HH:mm');

// ── 頁面狀態 Provider ─────────────────────────────────────────────────────────

/// 目前選取的狀態篩選（null = 全部）
final _selectedStatusFilterProvider =
    StateProvider.autoDispose<OrderStatus?>((ref) => null);

// ── OrdersAdminPage ───────────────────────────────────────────────────────────

/// 訂單管理後台頁面（路由：`/admin/orders`）。
class OrdersAdminPage extends ConsumerWidget {
  const OrdersAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(_selectedStatusFilterProvider);
    final ordersAsync =
        ref.watch(adminOrdersProvider(status: selectedStatus));
    final countAsync = ref.watch(adminOrderCountProvider);

    return Scaffold(
      backgroundColor: _Tokens.surface,
      appBar: AppBar(
        title: const Text('訂單管理'),
        backgroundColor: Colors.white,
        foregroundColor: _Tokens.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _Tokens.divider),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 狀態篩選列 ────────────────────────────────────────────────────
          _StatusFilterBar(
            selectedStatus: selectedStatus,
            countAsync: countAsync,
          ),
          const Divider(height: 1, thickness: 1, color: _Tokens.divider),
          // ── 訂單列表 ──────────────────────────────────────────────────────
          Expanded(
            child: ordersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  '載入失敗：$err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Text(
                      '目前沒有訂單',
                      style: TextStyle(
                        color: _Tokens.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: _Tokens.pagePadding
                      .copyWith(bottom: 32),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderCard(
                      order: order,
                      onTap: () =>
                          _showOrderDetail(context, ref, order),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetail(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _OrderDetailDialog(
        order: order,
        repository: ref.read(ordersAdminRepositoryProvider),
      ),
    );
  }
}

// ── _StatusFilterBar ──────────────────────────────────────────────────────────

class _StatusFilterBar extends ConsumerWidget {
  const _StatusFilterBar({
    required this.selectedStatus,
    required this.countAsync,
  });

  final OrderStatus? selectedStatus;
  final AsyncValue<Map<OrderStatus, int>> countAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = countAsync.valueOrNull ?? {};

    // 計算全部訂單數量
    final totalCount = counts.values.fold(0, (a, b) => a + b);

    return Container(
      color: Colors.white,
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        children: [
          // 「全部」chip
          _FilterChip(
            label: '全部',
            count: totalCount,
            isSelected: selectedStatus == null,
            color: _Tokens.brandRed,
            onTap: () => ref
                .read(_selectedStatusFilterProvider.notifier)
                .state = null,
          ),
          const SizedBox(width: 8),
          // 各狀態 chips
          ...OrderStatus.values.map((status) {
            final count = counts[status] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: status.label,
                count: count,
                isSelected: selectedStatus == status,
                color: _statusColor(status),
                onTap: () => ref
                    .read(_selectedStatusFilterProvider.notifier)
                    .state = status,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── _FilterChip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          count > 0 ? '$label ($count)' : label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ── _OrderCard ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length >= 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    return Material(
      color: _Tokens.cardBg,
      borderRadius: BorderRadius.circular(_Tokens.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFFFFF5F5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: _Tokens.divider),
            borderRadius: BorderRadius.circular(_Tokens.cardRadius),
          ),
          child: Row(
            children: [
              // ── 左側：訂單編號 + 客戶 + 商品數 ──────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#$shortId',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _Tokens.textPrimary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.shippingAddress.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _Tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '共 ${order.itemCount} 件・${_dateFormat.format(order.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _Tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // ── 右側：金額 ────────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPrice(order.total),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _Tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: _Tokens.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _StatusBadge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// _OrderDetailDialog — 訂單詳情 Dialog
// ════════════════════════════════════════════════════════════════════════════════

class _OrderDetailDialog extends StatefulWidget {
  const _OrderDetailDialog({
    required this.order,
    required this.repository,
  });

  final OrderModel order;
  final OrdersAdminRepository repository;

  @override
  State<_OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<_OrderDetailDialog> {
  bool _isUpdating = false;
  late OrderStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  // ── 狀態轉換規則 ──────────────────────────────────────────────────────────────

  /// 取得下一步可用的動作清單：[(label, nextStatus, isDestructive)]
  List<({String label, OrderStatus nextStatus, bool isDestructive})>
      get _availableActions {
    switch (_currentStatus) {
      case OrderStatus.pending:
        return [
          (label: '確認訂單', nextStatus: OrderStatus.confirmed, isDestructive: false),
          (label: '取消訂單', nextStatus: OrderStatus.cancelled, isDestructive: true),
        ];
      case OrderStatus.confirmed:
        return [
          (label: '開始處理', nextStatus: OrderStatus.processing, isDestructive: false),
          (label: '取消訂單', nextStatus: OrderStatus.cancelled, isDestructive: true),
        ];
      case OrderStatus.processing:
        return [
          (label: '已出貨', nextStatus: OrderStatus.shipped, isDestructive: false),
          (label: '取消訂單', nextStatus: OrderStatus.cancelled, isDestructive: true),
        ];
      case OrderStatus.shipped:
        return [
          (label: '已送達', nextStatus: OrderStatus.delivered, isDestructive: false),
        ];
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return [];
    }
  }

  // ── 執行狀態更新 ──────────────────────────────────────────────────────────────

  Future<void> _handleStatusUpdate(OrderStatus nextStatus) async {
    // 取消訂單需要二次確認
    if (nextStatus == OrderStatus.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('取消訂單'),
          content: const Text('確定要取消此訂單嗎？取消後無法恢復。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('返回'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('確認取消'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    } else {
      // 一般狀態更新也需要確認
      final action = _availableActions
          .firstWhere((a) => a.nextStatus == nextStatus);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('確認操作'),
          content: Text('確定要將訂單狀態更新為「${nextStatus.label}」嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: _Tokens.brandRed,
              ),
              child: Text(action.label),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;
    setState(() => _isUpdating = true);

    try {
      await widget.repository.updateOrderStatus(
        widget.order.id,
        nextStatus,
      );
      if (mounted) {
        setState(() {
          _currentStatus = nextStatus;
          _isUpdating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shortId = order.id.length >= 8
        ? order.id.substring(order.id.length - 8).toUpperCase()
        : order.id.toUpperCase();

    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: isDesktop
          ? const EdgeInsets.symmetric(horizontal: 80, vertical: 40)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 標題列 ──────────────────────────────────────────────────────
            _DialogHeader(
              shortId: shortId,
              status: _currentStatus,
              createdAt: order.createdAt,
            ),
            // ── 捲動內容 ─────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 備註
                    if (order.note != null && order.note!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NoteSection(note: order.note!),
                    ],
                    const SizedBox(height: 16),
                    const Divider(thickness: 1),

                    // 商品明細
                    const SizedBox(height: 12),
                    _SectionTitle(title: '商品明細'),
                    const SizedBox(height: 8),
                    ...order.items.map(
                      (item) => _OrderItemRow(item: item),
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1),

                    // 收件資訊
                    const SizedBox(height: 12),
                    _SectionTitle(title: '收件資訊'),
                    const SizedBox(height: 8),
                    _ShippingSection(address: order.shippingAddress),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1),

                    // 金額摘要
                    const SizedBox(height: 12),
                    _SectionTitle(title: '金額摘要'),
                    const SizedBox(height: 8),
                    _AmountSection(order: order),
                    const SizedBox(height: 16),

                    // 狀態操作區
                    if (_availableActions.isNotEmpty) ...[
                      const Divider(thickness: 1),
                      const SizedBox(height: 16),
                      _ActionSection(
                        actions: _availableActions,
                        isUpdating: _isUpdating,
                        onAction: _handleStatusUpdate,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _DialogHeader ─────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.shortId,
    required this.status,
    required this.createdAt,
  });

  final String shortId;
  final OrderStatus status;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _Tokens.divider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '訂單 #$shortId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StatusBadge(status: status),
                    const SizedBox(width: 8),
                    Text(
                      _dateFormat.format(createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _Tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: '關閉',
          ),
        ],
      ),
    );
  }
}

// ── _NoteSection ──────────────────────────────────────────────────────────────

class _NoteSection extends StatelessWidget {
  const _NoteSection({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '備註：$note',
              style: TextStyle(
                fontSize: 13,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _SectionTitle ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _Tokens.brandRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _Tokens.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── _OrderItemRow ─────────────────────────────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品名稱 + 規格
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _Tokens.textPrimary,
                            ),
                          ),
                        ),
                        if (item.isPreorder) ...[
                          const SizedBox(width: 6),
                          _PreorderBadge(),
                        ],
                      ],
                    ),
                    if (item.variantName.isNotEmpty)
                      Text(
                        item.variantName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _Tokens.textSecondary,
                        ),
                      ),
                    if (item.isPreorder &&
                        item.estimatedShipDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '預估出貨：${item.estimatedShipDate}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // 單價 × 數量 = 小計
              Text(
                '${formatPrice(item.price)} × ${item.quantity}',
                style: const TextStyle(
                  fontSize: 13,
                  color: _Tokens.textSecondary,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '= ${formatPrice(item.subtotal)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _Tokens.textPrimary,
              ),
            ),
          ),
          const Divider(height: 12, color: _Tokens.divider),
        ],
      ),
    );
  }
}

// ── _PreorderBadge ────────────────────────────────────────────────────────────

class _PreorderBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Text(
        '預購',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.orange.shade700,
        ),
      ),
    );
  }
}

// ── _ShippingSection ──────────────────────────────────────────────────────────

class _ShippingSection extends StatelessWidget {
  const _ShippingSection({required this.address});

  final ShippingAddress address;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(label: '姓名', value: address.name),
        _InfoRow(label: '電話', value: address.phone),
        _InfoRow(
          label: '地址',
          value:
              '${address.postalCode} ${address.city} ${address.address}',
        ),
      ],
    );
  }
}

// ── _InfoRow ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _Tokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: _Tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _AmountSection ────────────────────────────────────────────────────────────

class _AmountSection extends StatelessWidget {
  const _AmountSection({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AmountRow(label: '商品小計', value: formatPrice(order.subtotal)),
        _AmountRow(label: '運費', value: formatPrice(order.shippingFee)),
        const Divider(height: 12, color: _Tokens.divider),
        _AmountRow(
          label: '總計',
          value: formatPrice(order.total),
          isBold: true,
        ),
      ],
    );
  }
}

// ── _AmountRow ────────────────────────────────────────────────────────────────

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight:
                  isBold ? FontWeight.w700 : FontWeight.normal,
              color: _Tokens.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight:
                  isBold ? FontWeight.w700 : FontWeight.normal,
              color: _Tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _ActionSection ────────────────────────────────────────────────────────────

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.actions,
    required this.isUpdating,
    required this.onAction,
  });

  final List<({String label, OrderStatus nextStatus, bool isDestructive})>
      actions;
  final bool isUpdating;
  final Future<void> Function(OrderStatus) onAction;

  @override
  Widget build(BuildContext context) {
    if (isUpdating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) {
        if (action.isDestructive) {
          return OutlinedButton(
            onPressed: () => onAction(action.nextStatus),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: Text(action.label),
          );
        }
        return FilledButton(
          onPressed: () => onAction(action.nextStatus),
          style: FilledButton.styleFrom(
            backgroundColor: _Tokens.brandRed,
          ),
          child: Text(action.label),
        );
      }).toList(),
    );
  }
}
