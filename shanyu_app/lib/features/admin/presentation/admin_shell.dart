import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/admin_providers.dart';

// ── 常數 ──────────────────────────────────────────────────────────────────────

const _kNavRailWidth = 220.0;
const _kMobileBreakpoint = 600.0;

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
    label: '商品管理',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: _kNavRailWidth,
            color: colorScheme.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '山裕後台',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
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
              ],
            ),
          ),
          const VerticalDivider(width: 1),
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
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? item.selectedIcon : item.icon,
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: _kNavItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
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
