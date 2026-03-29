import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/products/presentation/product_list_page.dart';

part 'app_router.g.dart';

// ── 路由名稱常數 ─────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const products = '/products/:categoryId';
  static const productDetail = '/products/:categoryId/:productId';
  static const cart = '/cart';
  static const orders = '/orders';
  static const profile = '/profile';
  static const admin = '/admin';
}

/// 需要登入才能訪問的路由集合。
const _protectedRoutes = {
  AppRoutes.cart,
  AppRoutes.orders,
  AppRoutes.profile,
  AppRoutes.admin,
};

// ── 暫時佔位頁面（待各 Feature 實作後替換） ──────────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

// ── Router Provider ──────────────────────────────────────────────────────────

/// GoRouter Provider — keepAlive 確保 router 在 App 生命週期內不被 dispose。
/// 監聽 authStateProvider 驅動 redirect 邏輯。
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // 取得 auth 狀態的 listenable，讓 GoRouter 在狀態變化時重新執行 redirect。
  final authStateListenable = ValueNotifier<int>(0);

  ref.listen(authStateProvider, (_, __) {
    authStateListenable.value++;
  });

  ref.onDispose(authStateListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authStateListenable,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);

      // auth 尚未初始化（loading）— 不做 redirect，等待下一次刷新
      if (authAsync.isLoading) return null;

      final isLoggedIn = authAsync.valueOrNull != null;
      final currentPath = state.matchedLocation;

      // 未登入且嘗試訪問受保護路由 → 導向登入頁
      final isProtected = _protectedRoutes.any(
        (route) => currentPath.startsWith(
          // 將路徑參數去除後進行比對（例如 /cart 直接比對）
          route.replaceAll(RegExp(r'/:[\w]+'), ''),
        ),
      );

      if (!isLoggedIn && isProtected) {
        return AppRoutes.login;
      }

      // 已登入且訪問登入頁 → 導向首頁
      if (isLoggedIn && currentPath == AppRoutes.login) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.products,
        name: 'products',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId'] ?? '';
          return ProductListPage(categoryId: categoryId);
        },
        routes: [
          GoRoute(
            path: ':productId',
            name: 'productDetail',
            builder: (context, state) {
              final categoryId = state.pathParameters['categoryId'] ?? '';
              final productId = state.pathParameters['productId'] ?? '';
              return _PlaceholderPage(
                title: '商品詳情 — $categoryId / $productId',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.cart,
        name: 'cart',
        builder: (context, state) => const _PlaceholderPage(title: '購物車'),
      ),
      GoRoute(
        path: AppRoutes.orders,
        name: 'orders',
        builder: (context, state) => const _PlaceholderPage(title: '訂單列表'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const _PlaceholderPage(title: '會員中心'),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (context, state) => const _PlaceholderPage(title: '後台管理'),
      ),
    ],
  );
}
