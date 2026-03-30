// lib/features/products/presentation/product_list_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_nav_bar.dart';
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
    return Scaffold(
      backgroundColor: _ProductListTokens.surface,
      appBar: const AppNavBar(),
      body: _ProductListBody(categoryId: categoryId),
    );
  }
}

// ── 頁面主體 ──────────────────────────────────────────────────────────────────

class _ProductListBody extends ConsumerWidget {
  const _ProductListBody({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryByIdProvider(categoryId));
    final productsAsync = ref.watch(productsByCategoryProvider(categoryId));

    final categoryName = categoryAsync.valueOrNull?.name;

    return CustomScrollView(
      slivers: [
        // 分類標題區
        SliverToBoxAdapter(
          child: _CategoryHeader(
            categoryName: categoryName,
            isLoading: categoryAsync.isLoading,
          ),
        ),

        // 商品 Grid
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

// ── 分類標題區 ────────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.categoryName,
    required this.isLoading,
  });

  final String? categoryName;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _ProductListTokens.pagePadding,
        24,
        _ProductListTokens.pagePadding,
        16,
      ),
      child: isLoading
          ? Container(
              width: 120,
              height: 28,
              decoration: BoxDecoration(
                color: _ProductListTokens.skeletonColor,
                borderRadius: BorderRadius.circular(6),
              ),
            )
          : Text(
              categoryName ?? '商品列表',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _ProductListTokens.textPrimary,
                height: 1.3,
              ),
            ),
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
              childAspectRatio: 0.72,
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
          // 預購標籤
          if (product.isPreorder) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _ProductListTokens.preorderBadgeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '預購',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _ProductListTokens.preorderBadgeText,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // 商品名稱
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _ProductListTokens.textPrimary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // 最低價格
          if (product.minPrice != null)
            Text(
              'NT\$ ${product.minPrice}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ProductListTokens.brandBrown,
              ),
            )
          else
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
              childAspectRatio: 0.72,
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
            '此分類目前無商品',
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
