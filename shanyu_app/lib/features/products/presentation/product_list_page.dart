// lib/features/products/presentation/product_list_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_nav_bar.dart';
import '../models/category_model.dart';
import '../models/product_models.dart';
import '../providers/product_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _ProductListTokens {
  static const surface = Color(0xFFFAF7F4);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const brandBrown = Color(0xFF5C4033);
  static const preorderBadgeBg = Color(0xFFFF8A65);
  static const preorderBadgeText = Colors.white;
  static const skeletonColor = Color(0xFFE0E0E0);
  static const cardRadius = 12.0;
  static const pagePadding = 16.0;
  static const cardSpacing = 12.0;
  static const contentMaxWidth = 1200.0;

  // 響應式斷點
  static const mobileBreakpoint = 600.0;
  static const tabletBreakpoint = 1024.0;
}

// ── ProductListPage ───────────────────────────────────────────────────────────

/// 商品分類列表頁（路由 `/products/:categoryId`）。
///
/// - 手機版 2 欄 Grid，桌機版 3–4 欄
/// - 載入中顯示 shimmer placeholder
/// - 點擊商品導向 `/products/:categoryId/:productId`
class ProductListPage extends ConsumerWidget {
  const ProductListPage({
    super.key,
    required this.categoryId,
  });

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >=
        _ProductListTokens.mobileBreakpoint;

    return Scaffold(
      backgroundColor: _ProductListTokens.surface,
      appBar: const AppNavBar(),
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左側分類側欄
                _CategorySidebar(currentCategoryId: categoryId),
                const VerticalDivider(width: 1),
                // 右側農產內容
                Expanded(
                  child: _ProductListContent(categoryId: categoryId),
                ),
              ],
            )
          : Column(
              children: [
                // 手機版：頂部水平分類列
                _CategoryHorizontalBar(currentCategoryId: categoryId),
                Expanded(
                  child: _ProductListContent(categoryId: categoryId),
                ),
              ],
            ),
    );
  }
}

// ── 分類側欄（桌面版） ───────────────────────────────────────────────────────

class _CategorySidebar extends ConsumerWidget {
  const _CategorySidebar({required this.currentCategoryId});

  final String currentCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SizedBox(
      width: 200,
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (categories) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = cat.id == currentCategoryId;
            return _SidebarItem(
              name: cat.name,
              isSelected: isSelected,
              onTap: () => context.go('/products/${cat.id}'),
            );
          },
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? _ProductListTokens.brandBrown.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        title: Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected
                ? _ProductListTokens.brandBrown
                : _ProductListTokens.textSecondary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// ── 分類水平列（手機版） ─────────────────────────────────────────────────────

class _CategoryHorizontalBar extends ConsumerWidget {
  const _CategoryHorizontalBar({required this.currentCategoryId});

  final String currentCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      height: 48,
      color: Colors.white,
      child: categoriesAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (categories) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = cat.id == currentCategoryId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat.name),
                selected: isSelected,
                onSelected: (_) => context.go('/products/${cat.id}'),
                selectedColor:
                    _ProductListTokens.brandBrown.withValues(alpha: 0.12),
                checkmarkColor: _ProductListTokens.brandBrown,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? _ProductListTokens.brandBrown
                      : _ProductListTokens.textSecondary,
                ),
                side: BorderSide(
                  color: isSelected
                      ? _ProductListTokens.brandBrown
                      : const Color(0xFFE0E0E0),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── 農產內容區 ───────────────────────────────────────────────────────────────

class _ProductListContent extends ConsumerWidget {
  const _ProductListContent({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryByIdProvider(categoryId));
    final productsAsync = ref.watch(productsByCategoryProvider(categoryId));

    return CustomScrollView(
      slivers: [
        // 分類 Hero 區
        SliverToBoxAdapter(
          child: _CategoryHero(
            category: categoryAsync.valueOrNull,
            isLoading: categoryAsync.isLoading,
          ),
        ),

        // 農產 Grid
        productsAsync.when(
          loading: () => _ProductGridSkeleton(categoryId: categoryId),
          error: (error, _) => SliverToBoxAdapter(
            child: _ProductListError(message: error.toString()),
          ),
          data: (products) => products.isEmpty
              ? const SliverToBoxAdapter(child: _ProductListEmpty())
              : _ProductGrid(
                  products: products,
                  categoryId: categoryId,
                ),
        ),

        // 底部間距
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

// ── 分類 Hero 區 ─────────────────────────────────────────────────────────────

class _CategoryHero extends StatelessWidget {
  const _CategoryHero({
    required this.category,
    required this.isLoading,
  });

  final CategoryModel? category;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 200,
        color: _ProductListTokens.skeletonColor,
      );
    }

    final hasCover = category != null && category!.coverImageUrl.isNotEmpty;
    final hasDesc = category != null && category!.description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 封面圖 + 標題疊層
        if (hasCover)
          Stack(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: category!.coverImageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: _ProductListTokens.surface,
                  ),
                ),
              ),
              // 底部漸層遮罩
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
              ),
              // 標題文字
              Positioned(
                bottom: 16,
                left: _ProductListTokens.pagePadding,
                right: _ProductListTokens.pagePadding,
                child: Text(
                  category?.name ?? '農產列表',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                    shadows: [
                      Shadow(color: Color(0x66000000), blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ],
          )
        else
          // 無封面圖：純文字標題
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _ProductListTokens.pagePadding, 24,
              _ProductListTokens.pagePadding, 0,
            ),
            child: Text(
              category?.name ?? '農產列表',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _ProductListTokens.textPrimary,
                height: 1.3,
              ),
            ),
          ),

        // 分類描述
        if (hasDesc)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _ProductListTokens.pagePadding, 12,
              _ProductListTokens.pagePadding, 16,
            ),
            child: _ExpandableText(
              text: category!.description,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 15,
                color: _ProductListTokens.textSecondary,
                height: 1.6,
              ),
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }
}

// ── 商品 Grid ─────────────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.categoryId,
  });

  final List<ProductModel> products;
  final String categoryId;

  int _columnCount(double width) {
    if (width >= _ProductListTokens.tabletBreakpoint) return 4;
    if (width >= _ProductListTokens.mobileBreakpoint) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.crossAxisExtent);
        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: _ProductListTokens.pagePadding,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: _ProductListTokens.cardSpacing,
              crossAxisSpacing: _ProductListTokens.cardSpacing,
              childAspectRatio: 0.6,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _ProductCard(
                product: products[index],
                categoryId: categoryId,
              );
            },
          ),
        );
      },
    );
  }
}

// ── 商品卡片 ──────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryId,
  });

  final ProductModel product;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.go('/products/$categoryId/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ProductListTokens.cardRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 封面圖
            Expanded(
              flex: 5,
              child: _ProductCoverImage(
                imageUrl: product.coverImageUrl,
                productName: product.name,
              ),
            ),

            // 資訊區
            Expanded(
              flex: 3,
              child: _ProductCardInfo(product: product),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCoverImage extends StatelessWidget {
  const _ProductCoverImage({
    required this.imageUrl,
    required this.productName,
  });

  final String imageUrl;
  final String productName;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(_ProductListTokens.cardRadius),
      ),
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: _ProductListTokens.skeletonColor,
              ),
              errorWidget: (context, url, error) => _ImagePlaceholder(
                label: productName,
              ),
            )
          : _ImagePlaceholder(label: productName),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F0EC),
      child: Center(
        child: Text(
          label.isNotEmpty ? label[0] : '?',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: _ProductListTokens.brandBrown,
          ),
        ),
      ),
    );
  }
}

class _ProductCardInfo extends StatelessWidget {
  const _ProductCardInfo({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標籤列
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (product.isPreorder)
                _Badge(
                  label: '預購',
                  color: _ProductListTokens.preorderBadgeText,
                  bgColor: _ProductListTokens.preorderBadgeBg,
                ),
              if (product.minPrice != null)
                _Badge(
                  label: 'NT\$ ${product.minPrice} 起',
                  color: _ProductListTokens.brandBrown,
                  bgColor: const Color(0xFFF5F0EC),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // 農產名稱
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _ProductListTokens.textPrimary,
              height: 1.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // 農產描述
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              product.description,
              style: const TextStyle(
                fontSize: 12,
                color: _ProductListTokens.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Spacer(),

          // 最低價格（無 minPrice 時）
          if (product.minPrice == null)
            Text(
              '洽詢價格',
              style: TextStyle(
                fontSize: 12,
                color: _ProductListTokens.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── 載入中骨架 ────────────────────────────────────────────────────────────────

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton({required this.categoryId});

  final String categoryId;

  int _columnCount(double width) {
    if (width >= _ProductListTokens.tabletBreakpoint) return 4;
    if (width >= _ProductListTokens.mobileBreakpoint) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.crossAxisExtent);
        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: _ProductListTokens.pagePadding,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: _ProductListTokens.cardSpacing,
              crossAxisSpacing: _ProductListTokens.cardSpacing,
              childAspectRatio: 0.6,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => const _SkeletonCard(),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ProductListTokens.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 圖片骨架
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_ProductListTokens.cardRadius),
              ),
              child: Container(color: _ProductListTokens.skeletonColor),
            ),
          ),
          // 文字骨架
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _ProductListTokens.skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _ProductListTokens.skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _ProductListTokens.skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 空狀態 ────────────────────────────────────────────────────────────────────

class _ProductListEmpty extends StatelessWidget {
  const _ProductListEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            '此分類目前無農產',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 錯誤狀態 ──────────────────────────────────────────────────────────────────

class _ProductListError extends StatelessWidget {
  const _ProductListError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '載入失敗：$message',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 可展開文字 ───────────────────────────────────────────────────────────────

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({
    required this.text,
    required this.style,
    this.maxLines = 3,
  });

  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;
  bool _hasOverflow = false;
  final _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void didUpdateWidget(covariant _ExpandableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
    }
  }

  void _checkOverflow() {
    if (!mounted) return;
    final renderBox =
        _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: renderBox.size.width);

    final overflow = textPainter.didExceedMaxLines;
    if (overflow != _hasOverflow && mounted) {
      setState(() => _hasOverflow = overflow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          key: _textKey,
          style: widget.style,
          maxLines: _expanded ? null : widget.maxLines,
          overflow: _expanded ? null : TextOverflow.ellipsis,
        ),
        if (_hasOverflow)
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 22,
                  color: _ProductListTokens.brandBrown,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
