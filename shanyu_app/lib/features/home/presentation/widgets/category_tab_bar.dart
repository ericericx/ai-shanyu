// lib/features/home/presentation/widgets/category_tab_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../products/providers/product_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _Tokens {
  static const brandRed = Color(0xFFB82020);
  static const surface = Color(0xFFFAF7F4);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const dividerColor = Color(0xFFE0E0E0);
  static const sectionPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 24);
  static const gridSpacing = 12.0;
  static const itemHeight = 56.0;
  static const itemBorderRadius = 10.0;
  static const itemFontSize = 16.0;
  static const maxWidth = 1200.0;
}

// ── CategoryTabBar ────────────────────────────────────────────────────────────

class CategoryTabBar extends ConsumerWidget {
  const CategoryTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const _CategorySection(child: _SkeletonGrid()),
      error: (e, _) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        final sorted = [...categories]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return _CategorySection(child: _CategoryGrid(categories: sorted));
      },
    );
  }
}

// ── Section 外框（標題 + 內容） ───────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _Tokens.maxWidth),
          child: Padding(
            padding: _Tokens.sectionPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 區塊標題
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _Tokens.brandRed,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '農產分類',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 分類格狀列表 ──────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<dynamic> categories;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: _Tokens.gridSpacing,
        mainAxisSpacing: _Tokens.gridSpacing,
        mainAxisExtent: _Tokens.itemHeight,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) => _CategoryItem(
        id: categories[i].id as String,
        name: categories[i].name as String,
      ),
    );
  }
}

// ── 單一分類按鈕 ──────────────────────────────────────────────────────────────

class _CategoryItem extends StatefulWidget {
  const _CategoryItem({required this.id, required this.name});

  final String id;
  final String name;

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered
                ? _Tokens.brandRed.withValues(alpha: 0.06)
                : _Tokens.surface,
            borderRadius: BorderRadius.circular(_Tokens.itemBorderRadius),
            border: Border.all(
              color: _isHovered ? _Tokens.brandRed : _Tokens.dividerColor,
              width: 1.5,
            ),
          ),
          child: Text(
            widget.name,
            style: TextStyle(
              fontSize: _Tokens.itemFontSize,
              fontWeight: FontWeight.w600,
              color: _isHovered ? _Tokens.brandRed : _Tokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: _Tokens.gridSpacing,
        mainAxisSpacing: _Tokens.gridSpacing,
        mainAxisExtent: _Tokens.itemHeight,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(_Tokens.itemBorderRadius),
        ),
      ),
    );
  }
}
