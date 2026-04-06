// lib/features/home/presentation/widgets/product_timeline.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_design_tokens.dart';
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

  /// 生長期色條高度
  static const double growingBarHeight = 6.0;

  /// 採收期色條高度
  static const double harvestBarHeight = 10.0;

  /// 生長期顏色
  static const Color growingColor = Color(0xFF81C784);

  /// 採收期顏色
  static const Color harvestColor = Color(0xFFFF7043);

  /// 當前旬背景
  static const Color currentPeriodBg = Color(0x14B82020);

  /// 當前月份文字色
  static const Color currentMonthTextColor = AppDesignTokens.brandRed;

  /// 月份刻度文字色
  static const Color axisTextColor = AppDesignTokens.textMuted;

  /// 列分隔線
  static const Color dividerColor = Color(0xFFF0F0F0);

  /// hover 背景
  static const Color hoverColor = Color(0x08B82020);
}

const List<String> _monthLabels = [
  '1', '2', '3', '4', '5', '6',
  '7', '8', '9', '10', '11', '12',
];

// ── 主元件 ────────────────────────────────────────────────────────────────────

/// 農產時程元件。
///
/// 12 個月完整顯示，以色條標示生長期（綠）與採收期（橙）。
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
            final totalAxisWidth =
                constraints.maxWidth - _TimelineTokens.labelWidth;
            final periodWidth = totalAxisWidth / PeriodHelper.total;

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
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showPopup(TapDownDetails details) {
    _overlayEntry?.remove();
    final entry = OverlayEntry(
      builder: (_) => _PeriodPopupOverlay(
        position: details.globalPosition,
        product: widget.product,
        onDismiss: _dismissPopup,
      ),
    );
    _overlayEntry = entry;
    Overlay.of(context).insert(entry);
  }

  void _dismissPopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  List<Widget> _buildBars(int start, int end, Color color, double barH) {
    if (start <= 0 || end <= 0) return const [];
    final pw = widget.periodWidth;
    if (start <= end) {
      return [_barSegment(start, end, color, barH, pw)];
    }
    // 跨年：拆成兩段
    return [
      _barSegment(start, PeriodHelper.total, color, barH, pw),
      _barSegment(1, end, color, barH, pw),
    ];
  }

  Widget _barSegment(
      int start, int end, Color color, double barH, double pw) {
    return Positioned(
      left: (start - 1) * pw,
      top: (_TimelineTokens.rowHeight - barH) / 2,
      width: (end - start + 1) * pw,
      height: barH,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(barH / 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pw = widget.periodWidth;
    final axisWidth = pw * PeriodHelper.total;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _showPopup,
        child: Container(
          height: _TimelineTokens.rowHeight,
          decoration: BoxDecoration(
            color: _isHovered
                ? _TimelineTokens.hoverColor
                : Colors.transparent,
            border: const Border(
              bottom: BorderSide(color: _TimelineTokens.dividerColor),
            ),
          ),
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
              // 色條軌道
              SizedBox(
                width: axisWidth,
                height: _TimelineTokens.rowHeight,
                child: Stack(
                  children: [
                    // 當前旬背景
                    Positioned(
                      left: (widget.currentPeriod - 1) * pw,
                      top: 0,
                      width: pw,
                      height: _TimelineTokens.rowHeight,
                      child: Container(
                          color: _TimelineTokens.currentPeriodBg),
                    ),
                    // 生長期色條
                    ..._buildBars(
                      widget.product.growingStartPeriod,
                      widget.product.growingEndPeriod,
                      _TimelineTokens.growingColor,
                      _TimelineTokens.growingBarHeight,
                    ),
                    // 採收期色條
                    ..._buildBars(
                      widget.product.harvestStartPeriod,
                      widget.product.harvestEndPeriod,
                      _TimelineTokens.harvestColor,
                      _TimelineTokens.harvestBarHeight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
          barHeight: _TimelineTokens.growingBarHeight,
          label: '生長期',
        ),
        _LegendItem(
          color: _TimelineTokens.harvestColor,
          barHeight: _TimelineTokens.harvestBarHeight,
          label: '採收期',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.barHeight,
    required this.label,
  });

  final Color color;
  final double barHeight;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(barHeight / 2),
          ),
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
        _SkeletonBox(
            width: double.infinity, height: _TimelineTokens.axisHeight),
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

// ── 旬期資訊 Popup ─────────────────────────────────────────────────────────────

class _PeriodPopupOverlay extends StatelessWidget {
  const _PeriodPopupOverlay({
    required this.position,
    required this.product,
    required this.onDismiss,
  });

  final Offset position;
  final TimelineProduct product;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 點擊任意處關閉
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        // 資訊卡片
        Positioned(
          left: position.dx - 12,
          top: position.dy + 14,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  if (product.growingStartPeriod > 0 ||
                      product.harvestStartPeriod > 0)
                    const SizedBox(height: 8),
                  if (product.growingStartPeriod > 0)
                    _PeriodRow(
                      color: _TimelineTokens.growingColor,
                      label: '生長期',
                      start: product.growingStartPeriod,
                      end: product.growingEndPeriod,
                    ),
                  if (product.growingStartPeriod > 0 &&
                      product.harvestStartPeriod > 0)
                    const SizedBox(height: 4),
                  if (product.harvestStartPeriod > 0)
                    _PeriodRow(
                      color: _TimelineTokens.harvestColor,
                      label: '採收期',
                      start: product.harvestStartPeriod,
                      end: product.harvestEndPeriod,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({
    required this.color,
    required this.label,
    required this.start,
    required this.end,
  });

  final Color color;
  final String label;
  final int start;
  final int end;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label　${PeriodHelper.label(start)} ～ ${PeriodHelper.label(end)}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF424242)),
        ),
      ],
    );
  }
}
