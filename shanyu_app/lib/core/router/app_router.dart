import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

// ── Router 設定 ──────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const _PlaceholderPage(title: '首頁'),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const _PlaceholderPage(title: '登入'),
    ),
    GoRoute(
      path: AppRoutes.products,
      name: 'products',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId'] ?? '';
        return _PlaceholderPage(title: '商品列表 — $categoryId');
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
