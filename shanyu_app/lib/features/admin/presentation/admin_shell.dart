import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../providers/admin_providers.dart';

// ── 常數 ──────────────────────────────────────────────────────────────────────

const _kNavRailWidth = 220.0;
const _kMobileBreakpoint = 600.0;

// 品牌色（直接使用避免引入 token 僅為兩個常數）
const _kBrandRed = Color(0xFFB82020);
const _kSidebarBg = Color(0xFF2A1A14); // 深棕底色，烘托品牌紅
const _kSidebarSelected = Color(0xFFB82020);
const _kSidebarSelectedBg = Color(0x1FB82020); // 品牌紅 12% 透明
const _kSidebarText = Color(0xFFEDE0D8);
const _kSidebarTextMuted = Color(0xFF9E8880);

// ── 導覽項目定義 ──────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

const _kNavItems = [
  _NavItem(
    label: '首頁視覺管理',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    path: '/admin/cms',
  ),
  _NavItem(
    label: '農產管理',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    path: '/admin/products',
  ),
  _NavItem(
    label: '訂單管理',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    path: '/admin/orders',
  ),
  _NavItem(
    label: 'CRM',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    path: '/admin/crm',
  ),
  _NavItem(
    label: '客服',
    icon: Icons.support_agent_outlined,
    selectedIcon: Icons.support_agent,
    path: '/admin/chat',
  ),
];

// ── AdminShell ─────────────────────────────────────────────────────────────────

/// Admin 後台外殼 Widget，搭配 GoRouter ShellRoute 使用。
/// - 桌機（>= 600dp）：左側 NavigationRail
/// - 手機（< 600dp）：底部 NavigationBar
/// - 非 admin：顯示無存取權限頁面
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => _UnauthorizedPage(
            onRetry: () => ref.invalidate(isAdminProvider),
          ),
      data: (isAdmin) {
        if (!isAdmin) {
          return _UnauthorizedPage(
            onRetry: () => ref.invalidate(isAdminProvider),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= _kMobileBreakpoint;
            return isDesktop
                ? _DesktopLayout(navigationShell: navigationShell)
                : _MobileLayout(navigationShell: navigationShell);
          },
        );
      },
    );
  }
}

// ── _DesktopLayout ────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: _kNavRailWidth,
            color: _kSidebarBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 品牌標頭 ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kBrandRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            '山',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '山裕農產',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kSidebarText,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            '管理後台',
                            style: TextStyle(
                              fontSize: 11,
                              color: _kSidebarTextMuted,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ── 導覽分隔 ──────────────────────────────────────────────
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFF3D2A22),
                ),
                const SizedBox(height: 8),
                // ── 導覽項目 ──────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _kNavItems.length,
                    itemBuilder: (context, index) {
                      final item = _kNavItems[index];
                      final isSelected =
                          navigationShell.currentIndex == index;
                      return _DesktopNavTile(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => _onDestinationSelected(index),
                      );
                    },
                  ),
                ),
                // ── 底部返回首頁 ──────────────────────────────────────────
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFF3D2A22),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _DesktopNavTile(
                    item: const _NavItem(
                      label: '返回首頁',
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      path: AppRoutes.home,
                    ),
                    isSelected: false,
                    onTap: () => context.go(AppRoutes.home),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE0D8D4)),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

// ── _DesktopNavTile ───────────────────────────────────────────────────────────

class _DesktopNavTile extends StatelessWidget {
  const _DesktopNavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? _kSidebarSelectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: _kSidebarSelected.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // 選中指示條
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: 18,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _kSidebarSelected : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: isSelected ? _kSidebarSelected : _kSidebarTextMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? _kSidebarText : _kSidebarTextMuted,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _MobileLayout ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: '返回首頁',
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('山裕後台'),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '視覺',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '農產',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '訂單',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'CRM',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: '客服',
          ),
        ],
      ),
    );
  }
}

// ── _UnauthorizedPage ─────────────────────────────────────────────────────────

class _UnauthorizedPage extends StatelessWidget {
  const _UnauthorizedPage({this.onRetry});

  /// When set (e.g. from AdminShell), lets user refetch ID token claims after admin promotion.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '無存取權限',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '此頁面僅限帳號具備 admin 自訂權限（ID Token 內 admin: true）。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '若您已在後台被設為管理員，請先按「重新整理權限」或登出後再登入。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (onRetry != null) ...[
                  FilledButton.tonalIcon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.sync),
                    label: const Text('重新整理權限'),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('返回首頁'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
