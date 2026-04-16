import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../features/admin/providers/admin_providers.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/cart/providers/cart_providers.dart';
import '../../features/chat/providers/chat_providers.dart';
import '../theme/app_design_tokens.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _NavBarTokens {
  static const brandRed = AppDesignTokens.brandRed;
  static const dividerGrey = AppDesignTokens.dividerGrey;
  static const backgroundColor = Colors.white;
  static const navLinkColor = AppDesignTokens.brandRedDark;
  static const navLinkHoverColor = AppDesignTokens.brandRed;

  static const appBarHeight = 64.0;
  static const horizontalPadding = AppDesignTokens.pagePadding;
  static const desktopHorizontalPadding = 40.0;
  static const iconButtonSize = 40.0;
  static const avatarRadius = 16.0;

  static const mobileBreakpoint = AppDesignTokens.mobileBreakpoint;

  static const logoFontSize = 22.0;
  static const navLinkFontSize = 14.0;
  static const loginFontSize = 14.0;
}

// ── AppNavBar ─────────────────────────────────────────────────────────────────

/// 全站頂部導覽列。
///
/// 手機（< 600dp）：Logo + 購物車 + 登入/頭像
/// 桌機（>= 600dp）：Logo + 分類連結 + 購物車 + 登入/頭像
///
/// 實作 [PreferredSizeWidget] 以直接用於 [Scaffold.appBar]。
class AppNavBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(_NavBarTokens.appBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= _NavBarTokens.mobileBreakpoint;

    return Container(
      height: _NavBarTokens.appBarHeight,
      decoration: const BoxDecoration(
        color: _NavBarTokens.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: _NavBarTokens.dividerGrey,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop
                ? _NavBarTokens.desktopHorizontalPadding
                : _NavBarTokens.horizontalPadding,
          ),
          child: Row(
            children: [
              // ── 左側：品牌 Logo ──
              _BrandLogo(),

              const Spacer(),

              // ── 右側：Chat + 購物車 + 後台 + 使用者動作 ──
              _ChatButton(),
              const SizedBox(width: 4),
              _CartButton(),
              const SizedBox(width: 4),
              _AdminEntryButton(),
              const SizedBox(width: 4),
              _UserAction(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 品牌 Logo ─────────────────────────────────────────────────────────────────

class _BrandLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.home),
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            _NavBarTokens.brandRed,
            BlendMode.srcIn,
          ),
          child: Image.asset(
            'assets/images/shanyu.png',
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ── Chat 客服按鈕 ─────────────────────────────────────────────────────────────

class _ChatButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        ref.watch(unreadChatCountProvider).valueOrNull ?? 0;

    return SizedBox(
      width: _NavBarTokens.iconButtonSize,
      height: _NavBarTokens.iconButtonSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => context.go(AppRoutes.chat),
            icon: const Icon(Icons.chat_bubble_outline),
            color: _NavBarTokens.brandRed,
            iconSize: 22,
            tooltip: '聯繫我們',
            splashRadius: 20,
          ),
          if (unreadCount > 0)
            Positioned(
              top: 4,
              right: 4,
              child: _UnreadBadge(),
            ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: _NavBarTokens.brandRed,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── 購物車按鈕 ────────────────────────────────────────────────────────────────

class _CartButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = ref.watch(cartItemCountProvider);

    return SizedBox(
      width: _NavBarTokens.iconButtonSize,
      height: _NavBarTokens.iconButtonSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: () => context.go(AppRoutes.cart),
            icon: const Icon(Icons.shopping_bag_outlined),
            color: _NavBarTokens.brandRed,
            iconSize: 22,
            tooltip: '購物車',
            splashRadius: 20,
          ),
          if (itemCount > 0)
            Positioned(
              top: 4,
              right: 4,
              child: _CartBadge(count: itemCount),
            ),
        ],
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: const BoxDecoration(
        color: _NavBarTokens.brandRed,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── 後台入口按鈕 ──────────────────────────────────────────────────────────────

class _AdminEntryButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(isAdminProvider).when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (isAdmin) {
        if (!isAdmin) return const SizedBox.shrink();
        return SizedBox(
          width: _NavBarTokens.iconButtonSize,
          height: _NavBarTokens.iconButtonSize,
          child: IconButton(
            onPressed: () => context.go(AppRoutes.adminCms),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            color: _NavBarTokens.brandRed,
            iconSize: 22,
            tooltip: '後台管理',
            splashRadius: 20,
          ),
        );
      },
    );
  }
}

// ── 使用者動作（登入 or 頭像） ────────────────────────────────────────────────

class _UserAction extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return _LoginTextButton();
    }

    return _UserAvatar(
      photoUrl: user.photoURL,
      displayName: user.displayName,
      email: user.email,
    );
  }
}

class _LoginTextButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(AppRoutes.login),
      style: TextButton.styleFrom(
        foregroundColor: _NavBarTokens.brandRed,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(44, _NavBarTokens.iconButtonSize),
        textStyle: const TextStyle(
          fontSize: _NavBarTokens.loginFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: const Text('登入'),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.photoUrl,
    required this.displayName,
    required this.email,
  });

  final String? photoUrl;
  final String? displayName;
  final String? email;

  String get _initials {
    final name = displayName ?? email ?? '?';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _NavBarTokens.iconButtonSize,
      height: _NavBarTokens.iconButtonSize,
      child: InkWell(
        borderRadius: BorderRadius.circular(_NavBarTokens.iconButtonSize / 2),
        onTap: () => context.go(AppRoutes.profile),
        child: Center(
          child: CircleAvatar(
            radius: _NavBarTokens.avatarRadius,
            backgroundColor: _NavBarTokens.brandRed,
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
