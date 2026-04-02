// lib/features/home/presentation/widgets/product_timeline.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_timeline_models.dart';
import '../../providers/product_timeline_providers.dart';

// ── 設計常數 ──────────────────────────────────────────────────────────────────

abstract final class _TimelineTokens {
  /// 農產品名稱欄寬度
  static const double labelWidth = 80.0;

  /// 每列農產品的高度
  static const double rowHeight = 44.0;

  /// 月份刻度列高度
  static const double axisHeight = 32.0;

  /// 時間條高度
  static const double barHeight = 12.0;

  /// 時間條圓角
  static const double barRadius = 6.0;

  /// 最小軸寬（確保手機可捲動）
  static const double minAxisWidth = 480.0;

  /// 生長期顏色
  static const Color growingColor = Color(0xFFA5D6A7);

  /// 採收期顏色
  static const Color harvestColor = Color(0xFFFF8A65);

  /// 當前月份線顏色
  static const Color currentMonthColor = Color(0xFFB82020);

  /// 月份刻度文字色
  static const Color axisTextColor = Color(0xFF757575);

  /// 當前月份文字色
  static const Color currentMonthTextColor = Color(0xFFB82020);

  /// 列分隔線色
  static const Color dividerColor = Color(0xFFEEEEEE);

  /// hover 背景
  static const Color hoverColor = Color(0x0AB82020);
}

const List<String> _monthLabels = [
  '1', '2', '3', '4', '5', '6',
  '7', '8', '9', '10', '11', '12',
];

// ── 主元件 ────────────────────────────────────────────────────────────────────

/// 線性農產時程元件。
///
/// 以水平時程軸呈現每個農產品的生長期與採收期。
/// X 軸為 1–12 月，每列農產品顯示連續色條，當前月份以垂直虛線標示。
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

    // MediaQuery 拿到有限螢幕寬（不在 ScrollView 內量，避免 infinity）
    final screenWidth = MediaQuery.sizeOf(context).width;
    final axisWidth = math.max(
      _TimelineTokens.minAxisWidth,
      screenWidth - _TimelineTokens.labelWidth - 48,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Legend(),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _TimelineTokens.labelWidth + axisWidth,
            child: _TimelineBody(
              products: products,
              currentMonth: currentMonth,
              axisWidth: axisWidth,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 時程軸主體 ────────────────────────────────────────────────────────────────

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({
    required this.products,
    required this.currentMonth,
    required this.axisWidth,
  });

  final List<TimelineProduct> products;
  final int currentMonth;
  final double axisWidth;

  @override
  Widget build(BuildContext context) {
    // 當前月份的 X 軸位置（月份中心點）
    final currentMonthX = _TimelineTokens.labelWidth +
        ((currentMonth - 0.5) / 12) * axisWidth;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // X 軸月份刻度
            _MonthAxis(
              axisWidth: axisWidth,
              currentMonth: currentMonth,
            ),
            // 農產品列
            ...products.map((product) => _ProductRow(
                  product: product,
                  currentMonth: currentMonth,
                  axisWidth: axisWidth,
                )),
          ],
        ),
        // 當前月份垂直虛線（疊在所有列上）
        Positioned(
          top: _TimelineTokens.axisHeight,
          bottom: 0,
          left: currentMonthX,
          child: _DashedVerticalLine(
            color: _TimelineTokens.currentMonthColor,
          ),
        ),
      ],
    );
  }
}

// ── X 軸月份刻度 ──────────────────────────────────────────────────────────────

class _MonthAxis extends StatelessWidget {
  const _MonthAxis({
    required this.axisWidth,
    required this.currentMonth,
  });

  final double axisWidth;
  final int currentMonth;

  @override
  Widget build(BuildContext context) {
    final cellWidth = axisWidth / 12;

    return SizedBox(
      height: _TimelineTokens.axisHeight,
      child: Row(
        children: [
          SizedBox(width: _TimelineTokens.labelWidth),
          ...List.generate(12, (i) {
            final month = i + 1;
            final isCurrent = month == currentMonth;
            return SizedBox(
              width: cellWidth,
              child: Center(
                child: Text(
                  _monthLabels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isCurrent ? FontWeight.w800 : FontWeight.w400,
                    color: isCurrent
                        ? _TimelineTokens.currentMonthTextColor
                        : _TimelineTokens.axisTextColor,
                  ),
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
    required this.axisWidth,
  });

  final TimelineProduct product;
  final int currentMonth;
  final double axisWidth;

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go('/products/${widget.product.categoryId}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: _TimelineTokens.rowHeight,
          color: _isHovered ? _TimelineTokens.hoverColor : Colors.transparent,
          child: Row(
            children: [
              // 農產品名稱
              SizedBox(
                width: _TimelineTokens.labelWidth,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 8),
                  child: Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // 時程條
              SizedBox(
                width: widget.axisWidth,
                child: _TimelineBars(
                  product: widget.product,
                  axisWidth: widget.axisWidth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 時程色條 ──────────────────────────────────────────────────────────────────

class _TimelineBars extends StatelessWidget {
  const _TimelineBars({required this.product, required this.axisWidth});

  final TimelineProduct product;
  final double axisWidth;

  /// 將月份範圍轉換為 (left, width) 的百分比 segments。
  /// 跨年情況（start > end）拆為兩段。
  List<({double left, double width})> _segments(int start, int end) {
    if (start <= end) {
      return [
        (
          left: (start - 1) / 12 * axisWidth,
          width: (end - start + 1) / 12 * axisWidth,
        )
      ];
    }
    // 跨年：前段 start→12，後段 1→end
    return [
      (
        left: (start - 1) / 12 * axisWidth,
        width: (12 - start + 1) / 12 * axisWidth,
      ),
      (
        left: 0.0,
        width: end / 12 * axisWidth,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final growingSegs = _segments(
      product.growingStartMonth,
      product.growingEndMonth,
    );
    final harvestSegs = _segments(
      product.harvestStartMonth,
      product.harvestEndMonth,
    );

    return SizedBox(
      width: axisWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 列底部分隔線
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: const Divider(
              height: 1,
              color: _TimelineTokens.dividerColor,
            ),
          ),
          // 生長期色條（淺綠）
          ...growingSegs.map((seg) => Positioned(
                left: seg.left,
                width: seg.width,
                top: (_TimelineTokens.rowHeight - _TimelineTokens.barHeight) / 2,
                height: _TimelineTokens.barHeight,
                child: _Bar(color: _TimelineTokens.growingColor),
              )),
          // 採收期色條（深橘，疊上層）
          ...harvestSegs.map((seg) => Positioned(
                left: seg.left,
                width: seg.width,
                top: (_TimelineTokens.rowHeight - _TimelineTokens.barHeight) / 2,
                height: _TimelineTokens.barHeight,
                child: _Bar(color: _TimelineTokens.harvestColor),
              )),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_TimelineTokens.barRadius),
      ),
    );
  }
}

// ── 當前月份垂直虛線 ──────────────────────────────────────────────────────────

class _DashedVerticalLine extends StatelessWidget {
  const _DashedVerticalLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(color: color),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

// ── 圖例 ──────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: const [
        _LegendItem(color: _TimelineTokens.growingColor, label: '生長期'),
        _LegendItem(color: _TimelineTokens.harvestColor, label: '採收期'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
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
        // 圖例骨架
        Row(
          children: [
            _SkeletonBox(width: 70, height: 10),
            const SizedBox(width: 16),
            _SkeletonBox(width: 70, height: 10),
          ],
        ),
        const SizedBox(height: 12),
        // 軸骨架
        _SkeletonBox(width: double.infinity, height: _TimelineTokens.axisHeight),
        const SizedBox(height: 4),
        // 列骨架
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
