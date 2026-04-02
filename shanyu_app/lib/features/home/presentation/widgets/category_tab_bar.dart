// lib/features/home/presentation/widgets/category_tab_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../products/providers/product_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _TabBarTokens {
  static const brandRed = Color(0xFFB82020);
  static const backgroundColor = Colors.white;
  static const dividerColor = Color(0xFFE0E0E0);
  static const tabHeight = 48.0;
  static const horizontalPadding = 16.0;
  static const tabHorizontalPadding = 16.0;
  static const tabVerticalPadding = 5.0;
  static const tabBorderRadius = 20.0;
  static const tabFontSize = 14.0;
  static const skeletonWidth = 72.0;
  static const skeletonHeight = 32.0;
  static const skeletonRadius = 20.0;
}

// ── CategoryTabBar ────────────────────────────────────────────────────────────

/// 首頁分類頁籤列。
///
/// 從 [categoriesProvider] 動態載入分類，依 sortOrder 排序，
/// 點擊後導向 `/products/{categoryId}`。
/// 載入中顯示 skeleton，無分類時隱藏。
class CategoryTabBar extends ConsumerWidget {
  const CategoryTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const _TabBarSkeleton(),
      error: (e, _) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        final sorted = [...categories]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return _TabBarContent(categories: sorted);
      },
    );
  }
}

// ── 頁籤內容列 ────────────────────────────────────────────────────────────────

class _TabBarContent extends StatelessWidget {
  const _TabBarContent({required this.categories});

  final List<dynamic> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _TabBarTokens.tabHeight,
      decoration: const BoxDecoration(
        color: _TabBarTokens.backgroundColor,
        border: Border(
          bottom: BorderSide(color: _TabBarTokens.dividerColor, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: _TabBarTokens.horizontalPadding,
        ),
        child: Row(
          children: categories
              .map((cat) => _CategoryTab(
                    id: cat.id as String,
                    name: cat.name as String,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── 單一頁籤 ──────────────────────────────────────────────────────────────────

class _CategoryTab extends StatefulWidget {
  const _CategoryTab({required this.id, required this.name});

  final String id;
  final String name;

  @override
  State<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<_CategoryTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go('/products/${widget.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.symmetric(
            horizontal: _TabBarTokens.tabHorizontalPadding,
            vertical: _TabBarTokens.tabVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? _TabBarTokens.brandRed.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(_TabBarTokens.tabBorderRadius),
            border: Border.all(
              color: _isHovered
                  ? _TabBarTokens.brandRed
                  : _TabBarTokens.dividerColor,
              width: 1,
            ),
          ),
          child: Text(
            widget.name,
            style: TextStyle(
              fontSize: _TabBarTokens.tabFontSize,
              fontWeight: FontWeight.w500,
              color: _isHovered
                  ? _TabBarTokens.brandRed
                  : const Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Skeleton 佔位 ─────────────────────────────────────────────────────────────

class _TabBarSkeleton extends StatelessWidget {
  const _TabBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _TabBarTokens.tabHeight,
      decoration: const BoxDecoration(
        color: _TabBarTokens.backgroundColor,
        border: Border(
          bottom: BorderSide(color: _TabBarTokens.dividerColor, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: _TabBarTokens.horizontalPadding,
          vertical: 8,
        ),
        child: Row(
          children: List.generate(
            5,
            (_) => Container(
              width: _TabBarTokens.skeletonWidth,
              height: _TabBarTokens.skeletonHeight,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius:
                    BorderRadius.circular(_TabBarTokens.skeletonRadius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
