import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/admin/presentation/admin_shell.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/cart/presentation/cart_page.dart';
import '../../features/chat/presentation/chat_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/orders/presentation/checkout_page.dart';
import '../../features/orders/presentation/order_history_page.dart';
import '../../features/orders/presentation/order_success_page.dart';
import '../../features/products/presentation/product_detail_page.dart';
import '../../features/products/presentation/product_list_page.dart';
part 'app_router.g.dart';

// ── 路由名稱常數 ─────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const products = '/products/:categoryId';
  static const productDetail = '/products/:categoryId/:productId';
  static const cart = '/cart';
  static const chat = '/chat';
  static const checkout = '/orders/new';
  static const orderSuccess = '/orders/success/:orderId';
  static const orders = '/orders';
  static const profile = '/profile';
  static const admin = '/admin';
  static const adminCms = '/admin/cms';
  static const adminProducts = '/admin/products';
  static const adminOrders = '/admin/orders';
  static const adminCrm = '/admin/crm';
  static const adminChat = '/admin/chat';
}

/// 需要登入才能訪問的路由集合。
const _protectedRoutes = {
  AppRoutes.cart,
  AppRoutes.checkout,
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

  ref.listen(authStateProvider, (previous, next) {
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
              return ProductDetailPage(
                categoryId: categoryId,
                productId: productId,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.cart,
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) => const ChatPage(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        name: 'orderSuccess',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderSuccessPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.orders,
        name: 'orders',
        builder: (context, state) => const OrderHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) =>
            const _PlaceholderPage(title: '會員中心'),
      ),
      // ── Admin 後台 ShellRoute ────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          // 0：首頁視覺管理
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminCms,
                name: 'adminCms',
                builder: (context, state) =>
                    const _PlaceholderPage(title: '首頁視覺管理'),
              ),
            ],
          ),
          // 1：商品管理（placeholder）
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminProducts,
                name: 'adminProducts',
                builder: (context, state) =>
                    const _PlaceholderPage(title: '商品管理'),
              ),
            ],
          ),
          // 2：訂單管理（placeholder）
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminOrders,
                name: 'adminOrders',
                builder: (context, state) =>
                    const _PlaceholderPage(title: '訂單管理'),
              ),
            ],
          ),
          // 3：CRM（placeholder）
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminCrm,
                name: 'adminCrm',
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'CRM'),
              ),
            ],
          ),
          // 4：客服（placeholder）
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminChat,
                name: 'adminChat',
                builder: (context, state) =>
                    const _PlaceholderPage(title: '客服'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
