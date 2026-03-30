// lib/features/orders/presentation/order_success_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _SuccessTokens {
  static const surface = Color(0xFFFAF7F4);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const brandBrown = Color(0xFF5C4033);
  static const dividerColor = Color(0xFFE8E0DA);
  static const successIconColor = Color(0xFF5C4033);
  static const orderIdBg = Color(0xFFF3EDE8);

  static const pagePadding = 24.0;
  static const desktopMaxWidth = 480.0;
  static const cardRadius = 16.0;
  static const buttonHeight = 52.0;
  static const iconSize = 96.0;

  static const mobileBreakpoint = 600.0;
}

// ── OrderSuccessPage ──────────────────────────────────────────────────────────

/// 訂單成功頁（路由 `/orders/success/:orderId`）。
///
/// 在訂單成功建立後顯示，提供訂單編號確認與後續導航選項。
class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SuccessTokens.surface,
      body: SafeArea(
        child: _SuccessBody(orderId: orderId),
      ),
    );
  }
}

// ── 頁面主體 ──────────────────────────────────────────────────────────────────

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= _SuccessTokens.mobileBreakpoint;

    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: _SuccessTokens.pagePadding,
        vertical: 48,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── 成功圖示 ──
          _SuccessIcon(),

          const SizedBox(height: 32),

          // ── 標題 ──
          const Text(
            '訂單已送出！',
            style: TextStyle(
              color: _SuccessTokens.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            '感謝您的購買，我們已收到您的訂單。\n我們將盡快處理並通知您出貨資訊。',
            style: TextStyle(
              color: _SuccessTokens.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // ── 訂單編號卡片 ──
          _OrderIdCard(orderId: orderId),

          const SizedBox(height: 48),

          // ── 操作按鈕群 ──
          _ActionButtons(orderId: orderId),
        ],
      ),
    );

    if (isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _SuccessTokens.desktopMaxWidth,
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}

// ── 成功圖示 ──────────────────────────────────────────────────────────────────

class _SuccessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: _SuccessTokens.iconSize + 32,
      height: _SuccessTokens.iconSize + 32,
      decoration: BoxDecoration(
        color: _SuccessTokens.orderIdBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_outline,
        color: _SuccessTokens.successIconColor,
        size: _SuccessTokens.iconSize,
      ),
    );
  }
}

// ── 訂單編號卡片 ──────────────────────────────────────────────────────────────

class _OrderIdCard extends StatelessWidget {
  const _OrderIdCard({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _SuccessTokens.orderIdBg,
        borderRadius: BorderRadius.circular(_SuccessTokens.cardRadius),
        border: Border.all(color: _SuccessTokens.dividerColor),
      ),
      child: Column(
        children: [
          const Text(
            '訂單編號',
            style: TextStyle(
              color: _SuccessTokens.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            orderId,
            style: const TextStyle(
              color: _SuccessTokens.brandBrown,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            '（可長按複製）',
            style: TextStyle(
              color: _SuccessTokens.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 操作按鈕群 ────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 查看訂單按鈕（主按鈕）
        SizedBox(
          width: double.infinity,
          height: _SuccessTokens.buttonHeight,
          child: FilledButton(
            onPressed: () => context.go('/orders'),
            style: FilledButton.styleFrom(
              backgroundColor: _SuccessTokens.brandBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            child: const Text('查看訂單'),
          ),
        ),

        const SizedBox(height: 12),

        // 繼續購物按鈕（次要按鈕）
        SizedBox(
          width: double.infinity,
          height: _SuccessTokens.buttonHeight,
          child: OutlinedButton(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _SuccessTokens.brandBrown,
              side: const BorderSide(color: _SuccessTokens.brandBrown),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            child: const Text('繼續購物'),
          ),
        ),
      ],
    );
  }
}
