// lib/features/cart/presentation/cart_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/utils/price_format.dart';
import '../../../shared/widgets/app_nav_bar.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/cart_models.dart';
import '../providers/cart_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _CartTokens {
  static const surface = Color(0xFFFAF7F4);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const brandBrown = Color(0xFFB82020);
  static const dividerColor = Color(0xFFE8E0DA);
  static const cardBackground = Colors.white;
  static const preorderBadgeBg = Color(0xFFFF8A65);
  static const preorderBadgeText = Colors.white;
  static const sectionHeaderBg = Color(0xFFF3EDE8);
  static const quantityButtonBorder = Color(0xFFD7CAC3);
  static const checkoutButtonBg = Color(0xFFB82020);
  static const checkoutButtonText = Colors.white;
  static const errorColor = Color(0xFFB71C1C);

  static const pagePadding = 16.0;
  static const desktopMaxWidth = 860.0;
  static const cardRadius = 12.0;
  static const badgeRadius = 4.0;
  static const itemImageSize = 80.0;
  static const quantityButtonSize = 32.0;
  static const sectionHeaderVerticalPadding = 10.0;
  static const checkoutButtonHeight = 52.0;

  static const mobileBreakpoint = 600.0;
}

// ── CartPage ──────────────────────────────────────────────────────────────────

/// 購物車頁（路由 `/cart`）。
///
/// 狀態分支：
/// - 未登入 → 提示登入
/// - 已登入但購物車為空 → 空購物車畫面
/// - 已登入且有商品 → 分組列表 + 結帳摘要
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _CartTokens.surface,
      appBar: const AppNavBar(),
      body: const _CartBody(),
    );
  }
}

// ── 頁面主體 ──────────────────────────────────────────────────────────────────

class _CartBody extends ConsumerWidget {
  const _CartBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // 未登入
    if (user == null) {
      return const _UnauthenticatedView();
    }

    final cartAsync = ref.watch(cartProvider);

    return cartAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: _CartTokens.brandBrown,
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(_CartTokens.pagePadding * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: _CartTokens.errorColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '載入購物車時發生錯誤',
                style: TextStyle(
                  color: _CartTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: TextStyle(
                  color: _CartTokens.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (cart) {
        if (cart == null || cart.isEmpty) {
          return const _EmptyCartView();
        }
        return _CartContent(cart: cart, userId: user.uid);
      },
    );
  }
}

// ── 未登入畫面 ────────────────────────────────────────────────────────────────

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_CartTokens.pagePadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              color: _CartTokens.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              '請先登入',
              style: TextStyle(
                color: _CartTokens.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '登入後即可查看購物車內容',
              style: TextStyle(
                color: _CartTokens.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => context.go(AppRoutes.login),
              style: FilledButton.styleFrom(
                backgroundColor: _CartTokens.brandBrown,
                foregroundColor: _CartTokens.checkoutButtonText,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_CartTokens.cardRadius),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('前往登入'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 空購物車畫面 ──────────────────────────────────────────────────────────────

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_CartTokens.pagePadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: _CartTokens.textSecondary,
              size: 72,
            ),
            const SizedBox(height: 20),
            const Text(
              '購物車是空的',
              style: TextStyle(
                color: _CartTokens.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '快去挑選您喜歡的商品吧！',
              style: TextStyle(
                color: _CartTokens.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.home),
              style: OutlinedButton.styleFrom(
                foregroundColor: _CartTokens.brandBrown,
                side: const BorderSide(color: _CartTokens.brandBrown),
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_CartTokens.cardRadius),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('繼續購物'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 購物車主內容（有商品）────────────────────────────────────────────────────

class _CartContent extends ConsumerWidget {
  const _CartContent({required this.cart, required this.userId});

  final Cart cart;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= _CartTokens.mobileBreakpoint;

    Widget content = Column(
      children: [
        Expanded(
          child: _CartItemList(cart: cart, userId: userId),
        ),
        _CheckoutSummary(cart: cart),
      ],
    );

    if (isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _CartTokens.desktopMaxWidth,
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}

// ── 購物車商品列表 ────────────────────────────────────────────────────────────

class _CartItemList extends StatelessWidget {
  const _CartItemList({required this.cart, required this.userId});

  final Cart cart;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final regularItems = cart.regularItems;
    final preorderItems = cart.preorderItems;

    return ListView(
      padding: const EdgeInsets.only(
        left: _CartTokens.pagePadding,
        right: _CartTokens.pagePadding,
        top: _CartTokens.pagePadding,
        bottom: 8,
      ),
      children: [
        // 一般商品區塊
        if (regularItems.isNotEmpty) ...[
          _SectionHeader(label: '一般商品', count: regularItems.length),
          const SizedBox(height: 8),
          ...regularItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CartItemCard(item: item, userId: userId),
            ),
          ),
        ],

        // 預購商品區塊
        if (preorderItems.isNotEmpty) ...[
          if (regularItems.isNotEmpty) const SizedBox(height: 8),
          _SectionHeader(label: '預購商品', count: preorderItems.length),
          const SizedBox(height: 8),
          ...preorderItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CartItemCard(item: item, userId: userId),
            ),
          ),
        ],
      ],
    );
  }
}

// ── 分組標題 ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: _CartTokens.sectionHeaderVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: _CartTokens.sectionHeaderBg,
        borderRadius: BorderRadius.circular(_CartTokens.badgeRadius),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _CartTokens.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: _CartTokens.brandBrown.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: _CartTokens.brandBrown,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 購物車商品卡片 ────────────────────────────────────────────────────────────

class _CartItemCard extends ConsumerWidget {
  const _CartItemCard({required this.item, required this.userId});

  final CartItem item;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(cartRepositoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: _CartTokens.cardBackground,
        borderRadius: BorderRadius.circular(_CartTokens.cardRadius),
        border: Border.all(color: _CartTokens.dividerColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 商品縮圖 ──
          _ItemThumbnail(imageUrl: item.imageUrl, isPreorder: item.isPreorder),

          const SizedBox(width: 12),

          // ── 商品資訊 ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 商品名稱
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: _CartTokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // 規格名稱
                Text(
                  item.variantName,
                  style: const TextStyle(
                    color: _CartTokens.textSecondary,
                    fontSize: 12,
                  ),
                ),

                // 預購 badge + 預估出貨日
                if (item.isPreorder) ...[
                  const SizedBox(height: 6),
                  _PreorderBadge(estimatedShipDate: item.estimatedShipDate),
                ],

                const SizedBox(height: 10),

                // ── 數量控制列 ──
                Row(
                  children: [
                    _QuantityControl(
                      quantity: item.quantity,
                      onDecrement: () async {
                        await repo.updateQuantity(
                          userId,
                          item.variantId,
                          item.quantity - 1,
                        );
                      },
                      onIncrement: () async {
                        await repo.updateQuantity(
                          userId,
                          item.variantId,
                          item.quantity + 1,
                        );
                      },
                    ),
                    const Spacer(),
                    // 小計
                    Text(
                      formatPrice(item.subtotal),
                      style: const TextStyle(
                        color: _CartTokens.brandBrown,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 刪除按鈕 ──
          _DeleteButton(
            onPressed: () async {
              await repo.removeItem(userId, item.variantId);
            },
          ),
        ],
      ),
    );
  }
}

// ── 商品縮圖 ──────────────────────────────────────────────────────────────────

class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({required this.imageUrl, required this.isPreorder});

  final String imageUrl;
  final bool isPreorder;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: _CartTokens.itemImageSize,
        height: _CartTokens.itemImageSize,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ImagePlaceholder(),
              )
            : _ImagePlaceholder(),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _CartTokens.sectionHeaderBg,
      child: const Icon(
        Icons.image_outlined,
        color: _CartTokens.textSecondary,
        size: 32,
      ),
    );
  }
}

// ── 預購 Badge ────────────────────────────────────────────────────────────────

class _PreorderBadge extends StatelessWidget {
  const _PreorderBadge({this.estimatedShipDate});

  final String? estimatedShipDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _CartTokens.preorderBadgeBg,
            borderRadius: BorderRadius.circular(_CartTokens.badgeRadius),
          ),
          child: const Text(
            '預購',
            style: TextStyle(
              color: _CartTokens.preorderBadgeText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (estimatedShipDate != null) ...[
          const SizedBox(width: 6),
          Text(
            '預估出貨：$estimatedShipDate',
            style: const TextStyle(
              color: _CartTokens.preorderBadgeBg,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

// ── 數量控制器 ────────────────────────────────────────────────────────────────

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _CartTokens.quantityButtonSize,
      decoration: BoxDecoration(
        border: Border.all(color: _CartTokens.quantityButtonBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove,
            onPressed: onDecrement,
            tooltip: '減少數量',
          ),
          Container(
            width: 1,
            height: _CartTokens.quantityButtonSize,
            color: _CartTokens.quantityButtonBorder,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: _CartTokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 1,
            height: _CartTokens.quantityButtonSize,
            color: _CartTokens.quantityButtonBorder,
          ),
          _QuantityButton(
            icon: Icons.add,
            onPressed: onIncrement,
            tooltip: '增加數量',
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: _CartTokens.quantityButtonSize,
          height: _CartTokens.quantityButtonSize,
          child: Icon(icon, size: 16, color: _CartTokens.brandBrown),
        ),
      ),
    );
  }
}

// ── 刪除按鈕 ──────────────────────────────────────────────────────────────────

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '移除商品',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            Icons.close,
            size: 18,
            color: _CartTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── 結帳摘要區塊 ──────────────────────────────────────────────────────────────

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({required this.cart});

  final Cart cart;

  /// 目前運費固定為 0（金流未實作）
  static const int _shippingFee = 0;

  @override
  Widget build(BuildContext context) {
    final total = cart.totalPrice + _shippingFee;

    return Container(
      decoration: const BoxDecoration(
        color: _CartTokens.cardBackground,
        border: Border(
          top: BorderSide(color: _CartTokens.dividerColor),
        ),
      ),
      padding: EdgeInsets.only(
        left: _CartTokens.pagePadding,
        right: _CartTokens.pagePadding,
        top: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 商品小計列
          _SummaryRow(
            label: '商品小計',
            value: formatPrice(cart.totalPrice),
          ),
          const SizedBox(height: 6),
          // 運費列
          _SummaryRow(
            label: '運費',
            value: _shippingFee == 0 ? '免運費' : formatPrice(_shippingFee),
            valueColor: _shippingFee == 0
                ? const Color(0xFF388E3C)
                : _CartTokens.textPrimary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: _CartTokens.dividerColor, height: 1),
          ),
          // 總計列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '總計',
                style: TextStyle(
                  color: _CartTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatPrice(total),
                style: const TextStyle(
                  color: _CartTokens.brandBrown,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 前往結帳按鈕
          SizedBox(
            width: double.infinity,
            height: _CartTokens.checkoutButtonHeight,
            child: FilledButton(
              onPressed: () => context.go('/orders/new'),
              style: FilledButton.styleFrom(
                backgroundColor: _CartTokens.checkoutButtonBg,
                foregroundColor: _CartTokens.checkoutButtonText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_CartTokens.cardRadius),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              child: const Text('前往結帳'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _CartTokens.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _CartTokens.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
