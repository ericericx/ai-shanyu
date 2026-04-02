// lib/features/home/presentation/widgets/product_timeline.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_timeline_models.dart';
import '../../providers/product_timeline_providers.dart';

// ── 設計常數 ──────────────────────────────────────────────────────────────────

abstract final class _TimelineTokens {
  /// 農產品名稱欄寬度（固定）
  static const double labelWidth = 72.0;

  /// 每列農產品的高度
  static const double rowHeight = 48.0;

  /// 月份刻度列高度
  static const double axisHeight = 28.0;

  /// 採收期圓點半徑
  static const double harvestDotRadius = 10.0;

  /// 生長期圓點半徑（稍小）
  static const double growingDotRadius = 6.0;

  /// 生長期顏色
  static const Color growingColor = Color(0xFF81C784);

  /// 採收期顏色
  static const Color harvestColor = Color(0xFFFF7043);

  /// 當前月份背景色
  static const Color currentMonthBg = Color(0x14B82020);

  /// 當前月份文字色
  static const Color currentMonthTextColor = Color(0xFFB82020);

  /// 月份刻度文字色
  static const Color axisTextColor = Color(0xFF9E9E9E);

  /// 列分隔線色
  static const Color dividerColor = Color(0xFFF0F0F0);

  /// hover 背景
  static const Color hoverColor = Color(0x08B82020);
}

const List<String> _monthLabels = [
  '1', '2', '3', '4', '5', '6',
  '7', '8', '9', '10', '11', '12',
];

// ── 月份狀態 ──────────────────────────────────────────────────────────────────

enum _MonthState { none, growing, harvest }

// ── 主元件 ────────────────────────────────────────────────────────────────────

/// 農產時程元件。
///
/// 12 個月完整顯示於畫面內（無橫向捲動）。
/// 生長期以小綠點標示，採收期以大橙點標示，當前月份欄位背景高亮。
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

    final currentMonth = DateTime.now().month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Legend(),
        const SizedBox(height: 12),
        // LayoutBuilder 安全：此 Column 的父層有有限寬度
        LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth =
                (constraints.maxWidth - _TimelineTokens.labelWidth) / 12;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MonthAxis(
                  cellWidth: cellWidth,
                  currentMonth: currentMonth,
                ),
                ...products.map((product) => _ProductRow(
                      product: product,
                      currentMonth: currentMonth,
                      cellWidth: cellWidth,
                    )),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── 月份刻度 ──────────────────────────────────────────────────────────────────

class _MonthAxis extends StatelessWidget {
  const _MonthAxis({
    required this.cellWidth,
    required this.currentMonth,
  });

  final double cellWidth;
  final int currentMonth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _TimelineTokens.axisHeight,
      child: Row(
        children: [
          SizedBox(width: _TimelineTokens.labelWidth),
          ...List.generate(12, (i) {
            final month = i + 1;
            final isCurrent = month == currentMonth;
            return Container(
              width: cellWidth,
              alignment: Alignment.center,
              decoration: isCurrent
                  ? const BoxDecoration(
                      color: _TimelineTokens.currentMonthBg,
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
    required this.currentMonth,
    required this.cellWidth,
  });

  final TimelineProduct product;
  final int currentMonth;
  final double cellWidth;

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _isHovered = false;

  bool _inRange(int start, int end, int month) {
    if (start == 0 || end == 0) return false; // 未設定
    if (start <= end) return month >= start && month <= end;
    return month >= start || month <= end; // 跨年
  }

  _MonthState _stateFor(int month) {
    final isHarvest = _inRange(
      widget.product.harvestStartMonth,
      widget.product.harvestEndMonth,
      month,
    );
    if (isHarvest) return _MonthState.harvest;

    final isGrowing = _inRange(
      widget.product.growingStartMonth,
      widget.product.growingEndMonth,
      month,
    );
    if (isGrowing) return _MonthState.growing;

    return _MonthState.none;
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
          color: _isHovered ? _TimelineTokens.hoverColor : Colors.transparent,
          child: Row(
            children: [
              // 農產品名稱
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
              // 12 個月份圓點
              ...List.generate(12, (i) {
                final month = i + 1;
                final state = _stateFor(month);
                final isCurrent = month == widget.currentMonth;

                return Container(
                  width: widget.cellWidth,
                  height: _TimelineTokens.rowHeight,
                  color: isCurrent
                      ? _TimelineTokens.currentMonthBg
                      : Colors.transparent,
                  alignment: Alignment.center,
                  child: _MonthDot(state: state),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 月份圓點 ──────────────────────────────────────────────────────────────────

class _MonthDot extends StatelessWidget {
  const _MonthDot({required this.state});

  final _MonthState state;

  @override
  Widget build(BuildContext context) {
    if (state == _MonthState.none) {
      // 空月：細點線佔位
      return Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          shape: BoxShape.circle,
        ),
      );
    }

    final isHarvest = state == _MonthState.harvest;
    final radius =
        isHarvest ? _TimelineTokens.harvestDotRadius : _TimelineTokens.growingDotRadius;
    final color = isHarvest ? _TimelineTokens.harvestColor : _TimelineTokens.growingColor;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
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
