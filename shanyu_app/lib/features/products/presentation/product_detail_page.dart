// lib/features/products/presentation/product_detail_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../cart/data/cart_repository.dart';
import '../../cart/models/cart_models.dart';
import '../../cart/providers/cart_providers.dart';
import '../../../shared/widgets/app_nav_bar.dart';
import '../data/product_view_tracker.dart';
import '../models/product_detail_model.dart';
import '../providers/product_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _DetailTokens {
  static const surface = Color(0xFFFAF8F5);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const brandBrown = Color(0xFF5C4033);
  static const brandBrownLight = Color(0xFF8D6E63);
  static const preorderBadgeBg = Color(0xFFFF8A65);
  static const divider = Color(0xFFEFEBE9);
  static const skeletonColor = Color(0xFFE8E0D8);
  static const disabledBg = Color(0xFFBDBDBD);

  static const pagePadding = 20.0;
  static const sectionGap = 24.0;
  static const contentMaxWidth = 800.0;

  // 縮圖列
  static const thumbnailSize = 64.0;
  static const thumbnailRadius = 8.0;
  static const thumbnailGap = 8.0;

  // 變體 Chip
  static const chipRadius = 8.0;
}

// ── ProductDetailPage ─────────────────────────────────────────────────────────

/// 商品詳情頁（路由 `/products/:categoryId/:productId`）。
///
/// 佈局：AppNavBar → 捲動主體 → 固定底部加入購物車按鈕
class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
    required this.categoryId,
  });

  final String productId;
  final String categoryId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  /// 目前選中的變體 index；-1 代表尚未選擇
  int _selectedVariantIndex = -1;

  /// 目前顯示的主圖 URL（null 時使用 coverImageUrl）
  String? _activeImageUrl;

  bool _isAddingToCart = false;

  Future<void> _handleAddToCart(
    ProductDetailModel detail,
    ProductVariantModel variant,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先登入才能加入購物車')),
        );
      }
      return;
    }
    setState(() => _isAddingToCart = true);
    try {
      final repo = ref.read(cartRepositoryProvider);
      await repo.addItem(
        user.uid,
        CartItem(
          productId: widget.productId,
          variantId: variant.id,
          productName: detail.name,
          variantName: variant.name,
          price: variant.price,
          quantity: 1,
          isPreorder: variant.isPreorder,
          imageUrl: variant.imageUrls.isNotEmpty
              ? variant.imageUrls.first
              : detail.coverImageUrl,
          estimatedShipDate: variant.estimatedShipDate,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已加入購物車')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // 在第一幀結束後觸發追蹤，確保 ref 已完成掛載
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = ref.read(currentUserProvider)?.uid;
      ProductViewTracker().trackProductView(widget.productId, userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(productDetailProvider(widget.productId));
    final variantsAsync = ref.watch(productVariantsProvider(widget.productId));

    final selectedVariant = variantsAsync.valueOrNull != null &&
            _selectedVariantIndex >= 0 &&
            _selectedVariantIndex < variantsAsync.valueOrNull!.length
        ? variantsAsync.valueOrNull![_selectedVariantIndex]
        : null;

    return Scaffold(
      backgroundColor: _DetailTokens.surface,
      appBar: const AppNavBar(),
      body: detailAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (error, _) => _DetailError(message: error.toString()),
        data: (detail) => _DetailScrollBody(
          detail: detail,
          variants: variantsAsync.valueOrNull ?? [],
          selectedVariantIndex: _selectedVariantIndex,
          activeImageUrl: _activeImageUrl,
          onThumbnailTap: (url) => setState(() => _activeImageUrl = url),
          onVariantTap: (index) {
            setState(() {
              _selectedVariantIndex = index;
              // 若選中的變體有附圖，切換主圖
              final variant = variantsAsync.valueOrNull?[index];
              if (variant != null && variant.imageUrls.isNotEmpty) {
                _activeImageUrl = variant.imageUrls.first;
              } else {
                _activeImageUrl = null;
              }
            });
          },
        ),
      ),
      bottomNavigationBar: detailAsync.valueOrNull == null
          ? null
          : _AddToCartBar(
              variant: selectedVariant,
              isLoading: _isAddingToCart,
              onAddToCart: selectedVariant != null
                  ? () => _handleAddToCart(detailAsync.value!, selectedVariant)
                  : null,
            ),
    );
  }
}

// ── 捲動主體 ──────────────────────────────────────────────────────────────────

class _DetailScrollBody extends StatelessWidget {
  const _DetailScrollBody({
    required this.detail,
    required this.variants,
    required this.selectedVariantIndex,
    required this.activeImageUrl,
    required this.onThumbnailTap,
    required this.onVariantTap,
  });

  final ProductDetailModel detail;
  final List<ProductVariantModel> variants;
  final int selectedVariantIndex;
  final String? activeImageUrl;
  final ValueChanged<String> onThumbnailTap;
  final ValueChanged<int> onVariantTap;

  @override
  Widget build(BuildContext context) {
    final displayImageUrl =
        activeImageUrl?.isNotEmpty == true ? activeImageUrl! : detail.coverImageUrl;

    // 組合所有展示圖（封面圖 + imageUrls 去重）
    final allImages = <String>[
      if (detail.coverImageUrl.isNotEmpty) detail.coverImageUrl,
      ...detail.imageUrls.where((url) => url != detail.coverImageUrl),
    ];

    final selectedVariant = selectedVariantIndex >= 0 &&
            selectedVariantIndex < variants.length
        ? variants[selectedVariantIndex]
        : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _DetailTokens.contentMaxWidth,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 主封面圖
              _MainImage(imageUrl: displayImageUrl, productName: detail.name),

              // 2. 縮圖列（超過一張才顯示）
              if (allImages.length > 1)
                _ThumbnailStrip(
                  imageUrls: allImages,
                  activeImageUrl: displayImageUrl,
                  onTap: onThumbnailTap,
                ),

              const SizedBox(height: _DetailTokens.sectionGap),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _DetailTokens.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. 農產名稱 + 預購標籤
                    _ProductHeading(
                      name: detail.name,
                      isPreorder: detail.isPreorder,
                    ),

                    // 3b. 農產描述
                    if (detail.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _ExpandableText(
                        text: detail.description,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 15,
                          color: _DetailTokens.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],

                    const SizedBox(height: _DetailTokens.sectionGap),

                    // 4. 變體選擇（有變體才顯示）
                    if (variants.isNotEmpty) ...[
                      _VariantSelector(
                        variants: variants,
                        selectedIndex: selectedVariantIndex,
                        onTap: onVariantTap,
                      ),
                      const SizedBox(height: _DetailTokens.sectionGap),
                    ],

                    // 5. 價格顯示
                    if (selectedVariant != null)
                      _PriceDisplay(variant: selectedVariant),

                    // 6. 庫存 / 預估出貨日
                    if (selectedVariant != null)
                      _StockInfo(variant: selectedVariant),

                    const SizedBox(height: _DetailTokens.sectionGap),

                    // 7. 農產故事（ExpansionTile）
                    if (detail.story.isNotEmpty)
                      _StoryExpansion(story: detail.story),

                    const SizedBox(height: _DetailTokens.sectionGap),
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

// ── 主封面圖 ──────────────────────────────────────────────────────────────────

class _MainImage extends StatelessWidget {
  const _MainImage({
    required this.imageUrl,
    required this.productName,
  });

  final String imageUrl;
  final String productName;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: _DetailTokens.skeletonColor,
              ),
              errorWidget: (_, __, ___) =>
                  _ImageFallback(label: productName),
            )
          : _ImageFallback(label: productName),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0EAE4),
      child: Center(
        child: Text(
          label.isNotEmpty ? label[0] : '?',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: _DetailTokens.brandBrown,
          ),
        ),
      ),
    );
  }
}

// ── 縮圖列 ────────────────────────────────────────────────────────────────────

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.imageUrls,
    required this.activeImageUrl,
    required this.onTap,
  });

  final List<String> imageUrls;
  final String activeImageUrl;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _DetailTokens.thumbnailSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: _DetailTokens.pagePadding,
          vertical: 0,
        ),
        itemCount: imageUrls.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: _DetailTokens.thumbnailGap),
        itemBuilder: (context, index) {
          final url = imageUrls[index];
          final isActive = url == activeImageUrl;
          return GestureDetector(
            onTap: () => onTap(url),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: _DetailTokens.thumbnailSize,
              height: _DetailTokens.thumbnailSize,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(_DetailTokens.thumbnailRadius),
                border: Border.all(
                  color: isActive
                      ? _DetailTokens.brandBrown
                      : _DetailTokens.divider,
                  width: isActive ? 2.5 : 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  _DetailTokens.thumbnailRadius - 1,
                ),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: _DetailTokens.skeletonColor),
                  errorWidget: (_, __, ___) =>
                      Container(color: _DetailTokens.skeletonColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 商品標題 ──────────────────────────────────────────────────────────────────

class _ProductHeading extends StatelessWidget {
  const _ProductHeading({
    required this.name,
    required this.isPreorder,
  });

  final String name;
  final bool isPreorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPreorder) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _DetailTokens.preorderBadgeBg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              '預購',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _DetailTokens.textPrimary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ── 變體選擇器 ────────────────────────────────────────────────────────────────

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.variants,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<ProductVariantModel> variants;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '規格選擇',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _DetailTokens.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(variants.length, (index) {
            final variant = variants[index];
            final isSelected = index == selectedIndex;
            final isAvailable = variant.isAvailable;

            return GestureDetector(
              onTap: isAvailable ? () => onTap(index) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _DetailTokens.brandBrown
                      : isAvailable
                          ? Colors.white
                          : const Color(0xFFF5F0EC),
                  borderRadius:
                      BorderRadius.circular(_DetailTokens.chipRadius),
                  border: Border.all(
                    color: isSelected
                        ? _DetailTokens.brandBrown
                        : isAvailable
                            ? _DetailTokens.divider
                            : const Color(0xFFD7CFC8),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      variant.unit.isNotEmpty
                          ? '${variant.name}（${variant.unit}）'
                          : variant.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isAvailable
                                ? _DetailTokens.textPrimary
                                : _DetailTokens.textSecondary.withAlpha(153),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NT\$ ${variant.price}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white.withAlpha(204)
                            : isAvailable
                                ? _DetailTokens.brandBrownLight
                                : _DetailTokens.textSecondary.withAlpha(102),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── 價格顯示 ──────────────────────────────────────────────────────────────────

class _PriceDisplay extends StatelessWidget {
  const _PriceDisplay({required this.variant});

  final ProductVariantModel variant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'NT\$ ${variant.price}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _DetailTokens.brandBrown,
            ),
          ),
          if (variant.comparePrice != null) ...[
            const SizedBox(width: 10),
            Text(
              'NT\$ ${variant.comparePrice}',
              style: TextStyle(
                fontSize: 16,
                color: _DetailTokens.textSecondary.withAlpha(153),
                decoration: TextDecoration.lineThrough,
                decorationColor: _DetailTokens.textSecondary.withAlpha(153),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Text(
            '/ ${variant.unit}',
            style: const TextStyle(
              fontSize: 14,
              color: _DetailTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 庫存說明 ──────────────────────────────────────────────────────────────────

class _StockInfo extends StatelessWidget {
  const _StockInfo({required this.variant});

  final ProductVariantModel variant;

  @override
  Widget build(BuildContext context) {
    // 有庫存 → 不顯示
    if (variant.stock > 0) return const SizedBox.shrink();

    // 無庫存且為預購 → 顯示預估出貨日
    if (variant.isPreorder) {
      final shipDate = variant.estimatedShipDate;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFCC80)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 16,
              color: Color(0xFFE65100),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                shipDate != null && shipDate.isNotEmpty
                    ? '預估出貨日：$shipDate'
                    : '預購中，出貨日期待定',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE65100),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 無庫存且非預購 → 顯示已售完提示
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.remove_shopping_cart_outlined,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Text(
            '此規格目前已售完',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 農產故事（可展開） ────────────────────────────────────────────────────────

class _StoryExpansion extends StatelessWidget {
  const _StoryExpansion({required this.story});

  final String story;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '農產故事',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _DetailTokens.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        _ExpandableText(
          text: story,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 15,
            color: _DetailTokens.textSecondary,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

// ── 底部加入購物車 Bar ─────────────────────────────────────────────────────────

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.variant,
    required this.isLoading,
    this.onAddToCart,
  });

  final ProductVariantModel? variant;
  final bool isLoading;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    // 已選擇變體時，判斷是否可加入購物車
    final isAvailable = variant?.isAvailable ?? false;
    final hasVariantSelected = variant != null;

    // 按鈕狀態文字
    final String buttonLabel;
    if (isLoading) {
      buttonLabel = '加入中...';
    } else if (!hasVariantSelected) {
      buttonLabel = '請先選擇規格';
    } else if (!isAvailable) {
      buttonLabel = '已售完';
    } else {
      buttonLabel = '加入購物車';
    }

    final bool isEnabled = hasVariantSelected && isAvailable && !isLoading;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: _DetailTokens.divider),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: ElevatedButton(
              onPressed: isEnabled ? onAddToCart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled
                    ? _DetailTokens.brandBrown
                    : _DetailTokens.disabledBg,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _DetailTokens.disabledBg,
                disabledForegroundColor: Colors.white,
                elevation: isEnabled ? 2 : 0,
                shadowColor: _DetailTokens.brandBrown.withAlpha(102),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 載入骨架 ──────────────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 主圖骨架
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(color: _DetailTokens.skeletonColor),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _DetailTokens.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 200, height: 32),
              const SizedBox(height: 16),
              _SkeletonBox(width: double.infinity, height: 16),
              const SizedBox(height: 8),
              _SkeletonBox(width: 160, height: 16),
              const SizedBox(height: 24),
              _SkeletonBox(width: 120, height: 36),
            ],
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
        color: _DetailTokens.skeletonColor,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ── 錯誤狀態 ──────────────────────────────────────────────────────────────────

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              '載入失敗：$message',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 可展開文字（收合至 maxLines，顯示 ...more） ─────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: widget.text, style: widget.style);
        final tp = TextPainter(
          text: textSpan,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflow = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: widget.style,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (isOverflow)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _expanded ? '收合' : '...more',
                    style: TextStyle(
                      fontSize: widget.style.fontSize ?? 14,
                      color: _DetailTokens.brandBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
