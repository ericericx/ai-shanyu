// lib/features/home/presentation/widgets/product_timeline.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_timeline_models.dart';
import '../../providers/product_timeline_providers.dart';

// ── 設計常數 ──────────────────────────────────────────────────────────────────

abstract final class _TimelineTokens {
  /// 每個月份欄位的寬度
  static const double cellWidth = 48.0;

  /// 商品列的高度
  static const double rowHeight = 40.0;

  /// 商品名稱欄寬度
  static const double labelWidth = 100.0;

  /// 月份標頭的高度
  static const double headerHeight = 36.0;

  /// 時間條的垂直邊距
  static const double barVerticalPadding = 10.0;

  /// 時間條的圓角半徑
  static const double barRadius = 4.0;

  /// 生長期顏色
  static const Color growingColor = Color(0xFFC8E6C9);

  /// 採收期顏色
  static const Color harvestColor = Color(0xFFFF8A65);

  /// 當前月份 highlight 顏色
  static const Color currentMonthColor = Color(0xFF1565C0);

  /// 當前月份底線 / 三角顏色（淡藍）
  static const Color currentMonthIndicator = Color(0xFF1976D2);

  /// 標頭背景色
  static const Color headerBg = Color(0xFFFAFAFA);

  /// 偶數列背景色
  static const Color rowEvenBg = Color(0xFFFFFFFF);

  /// 奇數列背景色
  static const Color rowOddBg = Color(0xFFF5F5F5);

  /// 表格外框與分隔線顏色
  static const Color dividerColor = Color(0xFFE0E0E0);
}

// ── 月份名稱輔助 ──────────────────────────────────────────────────────────────

const List<String> _monthLabels = [
  '1月', '2月', '3月', '4月', '5月', '6月',
  '7月', '8月', '9月', '10月', '11月', '12月',
];

// ── 主元件 ────────────────────────────────────────────────────────────────────

/// 季節流水線元件。
///
/// 顯示 12 個月份的橫向時間軸，每列代表一種農產品，
/// 以色塊標示生長期（淺綠）與採收期（深橘），並 highlight 當前月份。
/// 手機版可左右捲動，點擊商品列導向對應分類頁。
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

// ── 資料載入完成後的內容 ───────────────────────────────────────────────────────

class _TimelineContent extends StatelessWidget {
  const _TimelineContent({required this.products});

  final List<TimelineProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _TimelineEmpty();
    }

    final currentMonth = DateTime.now().month; // 1–12

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 圖例列
        _TimelineLegend(),
        const SizedBox(height: 8),
        // 時間軸主體（含固定商品名稱欄 + 可捲動月份欄）
        _TimelineTable(products: products, currentMonth: currentMonth),
      ],
    );
  }
}

// ── 圖例 ──────────────────────────────────────────────────────────────────────

class _TimelineLegend extends StatelessWidget {
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ── 時間軸主體 ────────────────────────────────────────────────────────────────

class _TimelineTable extends StatelessWidget {
  const _TimelineTable({
    required this.products,
    required this.currentMonth,
  });

  final List<TimelineProduct> products;
  final int currentMonth;

  @override
  Widget build(BuildContext context) {
    // 總寬 = 商品名稱欄 + 12 個月份欄
    final totalGridWidth =
        _TimelineTokens.labelWidth + _TimelineTokens.cellWidth * 12;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _TimelineTokens.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalGridWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 月份標頭
              _MonthHeader(currentMonth: currentMonth),
              const Divider(height: 1, color: _TimelineTokens.dividerColor),
              // 商品列
              ...List.generate(products.length, (index) {
                return _ProductRow(
                  product: products[index],
                  currentMonth: currentMonth,
                  isEven: index.isEven,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 月份標頭 ──────────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.currentMonth});

  final int currentMonth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: _TimelineTokens.headerHeight,
      color: _TimelineTokens.headerBg,
      child: Row(
        children: [
          // 商品名稱欄的空白佔位
          SizedBox(
            width: _TimelineTokens.labelWidth,
            child: Center(
              child: Text(
                '農產品',
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // 12 個月份
          ...List.generate(12, (index) {
            final month = index + 1;
            final isCurrent = month == currentMonth;
            return SizedBox(
              width: _TimelineTokens.cellWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _monthLabels[index],
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight:
                          isCurrent ? FontWeight.w800 : FontWeight.w500,
                      color: isCurrent
                          ? _TimelineTokens.currentMonthColor
                          : Colors.grey[700],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      width: 20,
                      height: 2,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: _TimelineTokens.currentMonthIndicator,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── 商品列 ────────────────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.currentMonth,
    required this.isEven,
  });

  final TimelineProduct product;
  final int currentMonth;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/products/${product.categoryId}'),
      hoverColor: Colors.blue.withValues(alpha: 0.04),
      child: Container(
        height: _TimelineTokens.rowHeight,
        color: isEven ? _TimelineTokens.rowEvenBg : _TimelineTokens.rowOddBg,
        child: Row(
          children: [
            // 商品名稱
            SizedBox(
              width: _TimelineTokens.labelWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  product.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // 12 個月份色塊
            ...List.generate(12, (index) {
              final month = index + 1;
              return _MonthCell(
                month: month,
                product: product,
                currentMonth: currentMonth,
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── 單一月份儲存格 ────────────────────────────────────────────────────────────

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.month,
    required this.product,
    required this.currentMonth,
  });

  final int month;
  final TimelineProduct product;
  final int currentMonth;

  bool _inRange(int start, int end, int month) {
    if (start <= end) {
      return month >= start && month <= end;
    }
    // 跨年情況（例如 10月 ~ 2月）
    return month >= start || month <= end;
  }

  @override
  Widget build(BuildContext context) {
    final isHarvest = _inRange(
      product.harvestStartMonth,
      product.harvestEndMonth,
      month,
    );
    final isGrowing = !isHarvest &&
        _inRange(
          product.growingStartMonth,
          product.growingEndMonth,
          month,
        );
    final isCurrent = month == currentMonth;

    Color? barColor;
    if (isHarvest) {
      barColor = _TimelineTokens.harvestColor;
    } else if (isGrowing) {
      barColor = _TimelineTokens.growingColor;
    }

    return SizedBox(
      width: _TimelineTokens.cellWidth,
      child: Stack(
        children: [
          // 當前月份縱向高亮底色
          if (isCurrent)
            Positioned.fill(
              child: Container(
                color: _TimelineTokens.currentMonthColor.withValues(alpha: 0.06),
              ),
            ),
          // 生長期 / 採收期色條
          if (barColor != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 3,
                vertical: _TimelineTokens.barVerticalPadding,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius:
                      BorderRadius.circular(_TimelineTokens.barRadius),
                ),
              ),
            ),
          // 當前月份頂部三角指示器
          if (isCurrent)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: CustomPaint(
                  size: const Size(8, 5),
                  painter: _TrianglePainter(
                    color: _TimelineTokens.currentMonthIndicator,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 三角形指示器 Painter ──────────────────────────────────────────────────────

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── 載入中骨架 ────────────────────────────────────────────────────────────────

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
            _SkeletonBox(width: 70, height: 16, radius: 4),
            const SizedBox(width: 16),
            _SkeletonBox(width: 70, height: 16, radius: 4),
          ],
        ),
        const SizedBox(height: 12),
        // 表格骨架
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _TimelineTokens.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _SkeletonBox(
                width: double.infinity,
                height: _TimelineTokens.headerHeight,
                radius: 0,
              ),
              const Divider(height: 1, color: _TimelineTokens.dividerColor),
              ...List.generate(
                5,
                (_) => Column(
                  children: [
                    _SkeletonBox(
                      width: double.infinity,
                      height: _TimelineTokens.rowHeight,
                      radius: 0,
                    ),
                    const Divider(
                      height: 1,
                      color: _TimelineTokens.dividerColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(radius),
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
      child: Text(
        '目前無農產品時程資料',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.grey[600]),
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '載入失敗：$message',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
