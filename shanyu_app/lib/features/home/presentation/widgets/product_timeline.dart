// lib/features/home/presentation/widgets/product_timeline.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_timeline_models.dart';
import '../../providers/product_timeline_providers.dart';

// ── 設計常數 ──────────────────────────────────────────────────────────────────

abstract final class _TimelineTokens {
  /// 農產品名稱欄固定寬度
  static const double labelWidth = 72.0;

  /// 每列高度
  static const double rowHeight = 44.0;

  /// 月份刻度列高度
  static const double axisHeight = 32.0;

  /// 採收期圓點半徑
  static const double harvestDotRadius = 7.0;

  /// 生長期圓點半徑
  static const double growingDotRadius = 4.5;

  /// 生長期顏色
  static const Color growingColor = Color(0xFF81C784);

  /// 採收期顏色
  static const Color harvestColor = Color(0xFFFF7043);

  /// 當前旬背景
  static const Color currentPeriodBg = Color(0x14B82020);

  /// 當前月份文字色
  static const Color currentMonthTextColor = Color(0xFFB82020);

  /// 月份刻度文字色
  static const Color axisTextColor = Color(0xFF9E9E9E);

  /// 列分隔線
  static const Color dividerColor = Color(0xFFF0F0F0);

  /// hover 背景
  static const Color hoverColor = Color(0x08B82020);
}

const List<String> _monthLabels = [
  '1', '2', '3', '4', '5', '6',
  '7', '8', '9', '10', '11', '12',
];

// ── 旬期狀態 ──────────────────────────────────────────────────────────────────

enum _PeriodState { none, growing, harvest }

// ── 主元件 ────────────────────────────────────────────────────────────────────

/// 農產時程元件。
///
/// 12 個月完整顯示，每月細分上/中/下旬（共 36 旬）。
/// 生長期以小綠點，採收期以大橙點標示。
class ProductTimeline extends ConsumerWidget {
  const ProductTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(productTimelineProvider);

    return timelineAsync.when(
      loading: () => const _TimelineSkeleton(),
      error: (error, _) => _TimelineError(message: error.toString()),
      data: (products) => _TimelineContent(products: products),
    );
  }
}

// ── 內容 ──────────────────────────────────────────────────────────────────────

class _TimelineContent extends StatelessWidget {
  const _TimelineContent({required this.products});

  final List<TimelineProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const _TimelineEmpty();

    final now = DateTime.now();
    // 當前旬 period（1–36）
    final currentPeriod = PeriodHelper.toPeriod(
      now.month,
      now.day <= 10 ? 1 : now.day <= 20 ? 2 : 3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Legend(),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // 每旬格寬 = (可用寬 - 名稱欄) / 36
            final totalAxisWidth =
                constraints.maxWidth - _TimelineTokens.labelWidth;
            final periodWidth = totalAxisWidth / 36;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MonthAxis(
                  totalAxisWidth: totalAxisWidth,
                  currentPeriod: currentPeriod,
                ),
                ...products.map((p) => _ProductRow(
                      product: p,
                      currentPeriod: currentPeriod,
                      periodWidth: periodWidth,
                    )),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── 月份刻度列 ────────────────────────────────────────────────────────────────

class _MonthAxis extends StatelessWidget {
  const _MonthAxis({
    required this.totalAxisWidth,
    required this.currentPeriod,
  });

  final double totalAxisWidth;
  final int currentPeriod;

  @override
  Widget build(BuildContext context) {
    final monthWidth = totalAxisWidth / 12;
    final currentMonth = PeriodHelper.month(currentPeriod);

    return SizedBox(
      height: _TimelineTokens.axisHeight,
      child: Row(
        children: [
          SizedBox(width: _TimelineTokens.labelWidth),
          ...List.generate(12, (i) {
            final month = i + 1;
            final isCurrent = month == currentMonth;
            return Container(
              width: monthWidth,
              alignment: Alignment.center,
              decoration: isCurrent
                  ? const BoxDecoration(
                      color: _TimelineTokens.currentPeriodBg,
                      border: Border(
                        bottom: BorderSide(
                          color: _TimelineTokens.currentMonthTextColor,
                          width: 2,
                        ),
                      ),
                    )
                  : null,
              child: Text(
                _monthLabels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent
                      ? _TimelineTokens.currentMonthTextColor
                      : _TimelineTokens.axisTextColor,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── 農產品列 ──────────────────────────────────────────────────────────────────

class _ProductRow extends StatefulWidget {
  const _ProductRow({
    required this.product,
    required this.currentPeriod,
    required this.periodWidth,
  });

  final TimelineProduct product;
  final int currentPeriod;
  final double periodWidth;

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _isHovered = false;

  _PeriodState _stateFor(int period) {
    if (PeriodHelper.inRange(
      widget.product.harvestStartPeriod,
      widget.product.harvestEndPeriod,
      period,
    )) return _PeriodState.harvest;

    if (PeriodHelper.inRange(
      widget.product.growingStartPeriod,
      widget.product.growingEndPeriod,
      period,
    )) return _PeriodState.growing;

    return _PeriodState.none;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go('/products/${widget.product.categoryId}'),
        child: Container(
          height: _TimelineTokens.rowHeight,
          color:
              _isHovered ? _TimelineTokens.hoverColor : Colors.transparent,
          child: Row(
            children: [
              // 名稱
              SizedBox(
                width: _TimelineTokens.labelWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // 36 旬格
              ...List.generate(PeriodHelper.total, (i) {
                final period = i + 1;
                final state = _stateFor(period);
                final isCurrent = period == widget.currentPeriod;

                return Container(
                  width: widget.periodWidth,
                  height: _TimelineTokens.rowHeight,
                  color: isCurrent
                      ? _TimelineTokens.currentPeriodBg
                      : Colors.transparent,
                  alignment: Alignment.center,
                  child: _PeriodDot(state: state),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 旬期圓點 ──────────────────────────────────────────────────────────────────

class _PeriodDot extends StatelessWidget {
  const _PeriodDot({required this.state});

  final _PeriodState state;

  @override
  Widget build(BuildContext context) {
    if (state == _PeriodState.none) {
      return Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
          color: Color(0xFFE0E0E0),
          shape: BoxShape.circle,
        ),
      );
    }

    final isHarvest = state == _PeriodState.harvest;
    final r = isHarvest
        ? _TimelineTokens.harvestDotRadius
        : _TimelineTokens.growingDotRadius;
    final color = isHarvest
        ? _TimelineTokens.harvestColor
        : _TimelineTokens.growingColor;

    return Container(
      width: r * 2,
      height: r * 2,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── 圖例 ──────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: const [
        _LegendItem(
          color: _TimelineTokens.growingColor,
          radius: _TimelineTokens.growingDotRadius,
          label: '生長期',
        ),
        _LegendItem(
          color: _TimelineTokens.harvestColor,
          radius: _TimelineTokens.harvestDotRadius,
          label: '採收期',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.radius,
    required this.label,
  });

  final Color color;
  final double radius;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
        ),
      ],
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _TimelineSkeleton extends StatelessWidget {
  const _TimelineSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _SkeletonBox(width: 60, height: 12),
          const SizedBox(width: 16),
          _SkeletonBox(width: 60, height: 12),
        ]),
        const SizedBox(height: 12),
        _SkeletonBox(width: double.infinity, height: _TimelineTokens.axisHeight),
        const SizedBox(height: 4),
        ...List.generate(
          5,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _SkeletonBox(
              width: double.infinity,
              height: _TimelineTokens.rowHeight,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── 空狀態 ────────────────────────────────────────────────────────────────────

class _TimelineEmpty extends StatelessWidget {
  const _TimelineEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: const Text(
        '目前無農產品時程資料',
        style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
      ),
    );
  }
}

// ── 錯誤狀態 ──────────────────────────────────────────────────────────────────

class _TimelineError extends StatelessWidget {
  const _TimelineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '載入失敗：$message',
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
