// lib/features/orders/presentation/checkout_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/price_format.dart';
import '../../../shared/widgets/app_nav_bar.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cart/models/cart_models.dart';
import '../../cart/providers/cart_providers.dart';
import '../models/order_models.dart';
import '../providers/order_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _CheckoutTokens {
  static const surface = Color(0xFFFAF7F4);
  static const cardBackground = Colors.white;
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const brandBrown = Color(0xFFB82020);
  static const dividerColor = Color(0xFFE8E0DA);
  static const sectionHeaderBg = Color(0xFFF3EDE8);
  static const inputBorder = Color(0xFFD7CAC3);
  static const inputFocusBorder = Color(0xFFB82020);
  static const errorColor = Color(0xFFB71C1C);

  static const pagePadding = 20.0;
  static const desktopMaxWidth = 760.0;
  static const cardRadius = 12.0;
  static const inputRadius = 8.0;
  static const buttonHeight = 52.0;
  static const itemImageSize = 60.0;

  static const mobileBreakpoint = 600.0;
}

// ── CheckoutPage ──────────────────────────────────────────────────────────────

/// 結帳頁（路由 `/orders/new`）。
///
/// 顯示訂單摘要（唯讀購物車商品）與收件資訊表單，
/// 送出後呼叫 createOrder Callable Function，成功後清空購物車並導向訂單成功頁。
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  // 表單控制器
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(List<CartItem> cartItems) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final address = ShippingAddress(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
    );

    final note = _noteController.text.trim();

    try {
      final repo = ref.read(orderRepositoryProvider);
      final orderId = await repo.createOrder(
        items: cartItems,
        address: address,
        note: note.isNotEmpty ? note : null,
      );

      // 取得目前使用者 UID，清空購物車
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final cartRepo = ref.read(cartRepositoryProvider);
        await cartRepo.clearCart(user.uid);
      }

      if (!mounted) return;
      context.go('/orders/success/$orderId');
    } on Exception catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_parseErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _parseErrorMessage(Exception e) {
    final message = e.toString();
    if (message.contains('unauthenticated') || message.contains('permission')) {
      return '請先登入後再進行結帳';
    }
    if (message.contains('invalid-argument')) {
      return '訂單資料有誤，請確認後重試';
    }
    if (message.contains('internal')) {
      return '系統內部錯誤，請稍後再試';
    }
    return '送出訂單時發生錯誤，請稍後再試';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _CheckoutTokens.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CheckoutTokens.surface,
      appBar: const AppNavBar(),
      body: _CheckoutBody(
        formKey: _formKey,
        nameController: _nameController,
        phoneController: _phoneController,
        addressController: _addressController,
        cityController: _cityController,
        postalCodeController: _postalCodeController,
        noteController: _noteController,
        isSubmitting: _isSubmitting,
        onSubmit: _submitOrder,
      ),
    );
  }
}

// ── 頁面主體 ──────────────────────────────────────────────────────────────────

class _CheckoutBody extends ConsumerWidget {
  const _CheckoutBody({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.cityController,
    required this.postalCodeController,
    required this.noteController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final TextEditingController noteController;
  final bool isSubmitting;
  final Future<void> Function(List<CartItem>) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return cartAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _CheckoutTokens.brandBrown),
      ),
      error: (err, _) => _ErrorView(message: err.toString()),
      data: (cart) {
        if (cart == null || cart.isEmpty) {
          return const _EmptyCartView();
        }
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isDesktop = screenWidth >= _CheckoutTokens.mobileBreakpoint;

        Widget content = SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: _CheckoutTokens.pagePadding,
            right: _CheckoutTokens.pagePadding,
            top: _CheckoutTokens.pagePadding,
            bottom: 40,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 訂單摘要區塊
                _OrderSummarySection(cart: cart),
                const SizedBox(height: 24),

                // 收件資訊表單
                _ShippingFormSection(
                  nameController: nameController,
                  phoneController: phoneController,
                  addressController: addressController,
                  cityController: cityController,
                  postalCodeController: postalCodeController,
                  noteController: noteController,
                ),
                const SizedBox(height: 32),

                // 送出按鈕
                _SubmitButton(
                  isSubmitting: isSubmitting,
                  onPressed: () => onSubmit(cart.items),
                ),
              ],
            ),
          ),
        );

        if (isDesktop) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _CheckoutTokens.desktopMaxWidth,
              ),
              child: content,
            ),
          );
        }

        return content;
      },
    );
  }
}

// ── 訂單摘要區塊 ──────────────────────────────────────────────────────────────

class _OrderSummarySection extends StatelessWidget {
  const _OrderSummarySection({required this.cart});

  final Cart cart;

  static const int _shippingFee = 0;

  @override
  Widget build(BuildContext context) {
    final total = cart.totalPrice + _shippingFee;

    return _SectionCard(
      title: '訂單摘要',
      child: Column(
        children: [
          // 商品列表
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OrderSummaryItem(item: item),
            ),
          ),

          const Divider(color: _CheckoutTokens.dividerColor, height: 24),

          // 小計
          _SummaryRow(
            label: '商品小計',
            value: formatPrice(cart.totalPrice),
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: '運費',
            value: _shippingFee == 0 ? '免運費' : formatPrice(_shippingFee),
            valueColor: _shippingFee == 0
                ? const Color(0xFF388E3C)
                : _CheckoutTokens.textPrimary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: _CheckoutTokens.dividerColor, height: 1),
          ),

          // 總計
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '應付總計',
                style: TextStyle(
                  color: _CheckoutTokens.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatPrice(total),
                style: const TextStyle(
                  color: _CheckoutTokens.brandBrown,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryItem extends StatelessWidget {
  const _OrderSummaryItem({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 商品縮圖
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: _CheckoutTokens.itemImageSize,
            height: _CheckoutTokens.itemImageSize,
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                  )
                : const _ImagePlaceholder(),
          ),
        ),
        const SizedBox(width: 12),

        // 商品資訊
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  color: _CheckoutTokens.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${item.variantName}  x${item.quantity}',
                style: const TextStyle(
                  color: _CheckoutTokens.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // 小計
        Text(
          formatPrice(item.subtotal),
          style: const TextStyle(
            color: _CheckoutTokens.brandBrown,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _CheckoutTokens.sectionHeaderBg,
      child: const Icon(
        Icons.image_outlined,
        color: _CheckoutTokens.textSecondary,
        size: 24,
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
            color: _CheckoutTokens.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _CheckoutTokens.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── 收件資訊表單區塊 ──────────────────────────────────────────────────────────

class _ShippingFormSection extends StatelessWidget {
  const _ShippingFormSection({
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.cityController,
    required this.postalCodeController,
    required this.noteController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '收件資訊',
      child: Column(
        children: [
          // 收件人姓名
          _FormField(
            controller: nameController,
            label: '收件人姓名',
            hint: '請輸入收件人姓名',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '請輸入收件人姓名';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 聯絡電話
          _FormField(
            controller: phoneController,
            label: '聯絡電話',
            hint: '請輸入手機號碼（例：0912345678）',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '請輸入聯絡電話';
              }
              final digitsOnly = value.trim().replaceAll(RegExp(r'\s|-'), '');
              if (!RegExp(r'^\d{8,12}$').hasMatch(digitsOnly)) {
                return '請輸入有效的電話號碼（8-12 位數字）';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 詳細地址
          _FormField(
            controller: addressController,
            label: '詳細地址',
            hint: '請輸入詳細地址（街道、門牌號碼）',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '請輸入詳細地址';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 城市 + 郵遞區號（並排）
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _FormField(
                  controller: cityController,
                  label: '城市',
                  hint: '例：台北市',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入城市';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _FormField(
                  controller: postalCodeController,
                  label: '郵遞區號',
                  hint: '例：10001',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '請輸入郵遞區號';
                    }
                    if (!RegExp(r'^\d{3,6}$').hasMatch(value.trim())) {
                      return '請輸入 3-6 位數字的郵遞區號';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 備註（選填）
          _FormField(
            controller: noteController,
            label: '備註（選填）',
            hint: '如有特殊需求請在此說明',
            maxLines: 3,
            isRequired: false,
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.isRequired = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _CheckoutTokens.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  '*',
                  style: TextStyle(
                    color: _CheckoutTokens.errorColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            color: _CheckoutTokens.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFAA9990),
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_CheckoutTokens.inputRadius),
              borderSide: const BorderSide(color: _CheckoutTokens.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_CheckoutTokens.inputRadius),
              borderSide: const BorderSide(
                color: _CheckoutTokens.inputFocusBorder,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_CheckoutTokens.inputRadius),
              borderSide: const BorderSide(
                color: _CheckoutTokens.errorColor,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_CheckoutTokens.inputRadius),
              borderSide: const BorderSide(
                color: _CheckoutTokens.errorColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── 送出按鈕 ──────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _CheckoutTokens.buttonHeight,
      child: FilledButton(
        onPressed: isSubmitting ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _CheckoutTokens.brandBrown,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _CheckoutTokens.brandBrown.withAlpha(120),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_CheckoutTokens.cardRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text('確認送出訂單'),
      ),
    );
  }
}

// ── 共用區塊卡片 ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _CheckoutTokens.cardBackground,
        borderRadius: BorderRadius.circular(_CheckoutTokens.cardRadius),
        border: Border.all(color: _CheckoutTokens.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 區塊標題
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _CheckoutTokens.sectionHeaderBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_CheckoutTokens.cardRadius),
                topRight: Radius.circular(_CheckoutTokens.cardRadius),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: _CheckoutTokens.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // 內容
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── 錯誤視圖 ──────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_CheckoutTokens.pagePadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: _CheckoutTokens.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '載入購物車時發生錯誤',
              style: TextStyle(
                color: _CheckoutTokens.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: _CheckoutTokens.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 購物車為空視圖 ────────────────────────────────────────────────────────────

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_CheckoutTokens.pagePadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              color: _CheckoutTokens.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              '購物車是空的',
              style: TextStyle(
                color: _CheckoutTokens.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '請先加入商品再進行結帳',
              style: TextStyle(
                color: _CheckoutTokens.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _CheckoutTokens.brandBrown,
                side: const BorderSide(color: _CheckoutTokens.brandBrown),
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_CheckoutTokens.cardRadius),
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
