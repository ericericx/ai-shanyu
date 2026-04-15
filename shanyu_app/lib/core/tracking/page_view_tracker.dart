// lib/core/tracking/page_view_tracker.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

// ── 資料模型 ──────────────────────────────────────────────────────────────────

/// 頁面瀏覽記錄資料類別。
class PageViewRecord {
  const PageViewRecord({
    required this.path,
    required this.title,
    required this.userId,
    required this.sessionId,
    required this.referrer,
  });

  /// 路由路徑（例如 `/products/fruit/abc123`）
  final String path;

  /// 頁面中文標題（例如「商品詳情」）
  final String title;

  /// 登入使用者的 UID；匿名瀏覽時為 null
  final String? userId;

  /// UUID v4，App 啟動時產生，整個 session 共用
  final String sessionId;

  /// 前一頁路徑；無前一頁時為空字串
  final String referrer;

  Map<String, dynamic> toFirestore() => {
        'path': path,
        'title': title,
        'userId': userId,
        'sessionId': sessionId,
        'referrer': referrer,
        'timestamp': FieldValue.serverTimestamp(),
      };
}

// ── Tracker ───────────────────────────────────────────────────────────────────

/// 全站頁面瀏覽追蹤器。
///
/// 遵循靜默失敗原則：任何 Firestore 錯誤只記錄至 debug console，
/// 不對頁面流程造成任何影響。
class PageViewTracker {
  PageViewTracker({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// App 啟動時產生一次，整個 session 共用。
  final String sessionId = const Uuid().v4();

  String? _currentUserId;

  /// Auth 狀態改變時由 Provider 呼叫，更新目前使用者 ID。
  void updateUserId(String? userId) {
    _currentUserId = userId;
  }

  /// 寫入一筆頁面瀏覽記錄至 Firestore `pageViews` 集合。
  ///
  /// fire-and-forget：呼叫後不需等待結果。
  Future<void> trackPageView({
    required String path,
    required String title,
    required String referrer,
  }) async {
    final record = PageViewRecord(
      path: path,
      title: title,
      userId: _currentUserId,
      sessionId: sessionId,
      referrer: referrer,
    );

    try {
      await _firestore.collection('pageViews').add(record.toFirestore());
    } catch (error, stackTrace) {
      debugPrint('[PageViewTracker] trackPageView 失敗: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 6);
    }
  }
}

// ── NavigatorObserver ─────────────────────────────────────────────────────────

/// GoRouter 的 NavigatorObserver，負責攔截頁面切換事件並觸發追蹤。
class PageViewTrackerObserver extends NavigatorObserver {
  PageViewTrackerObserver({required this.tracker});

  final PageViewTracker tracker;

  /// 紀錄前一頁路徑，供下一頁的 referrer 欄位使用。
  String _previousPath = '';

  // ── 路徑 → 中文標題對應 ──────────────────────────────────────────────────────

  /// 根據路由路徑解析對應的中文頁面標題。
  ///
  /// 規則（由上到下優先匹配）：
  /// - `/admin` 開頭 → 返回 null（不追蹤後台頁面）
  /// - 完整路徑精確比對
  /// - pattern 比對（含路徑參數）
  static String? _resolveTitle(String path) {
    // 後台頁面不追蹤
    if (path.startsWith('/admin')) return null;

    // 精確比對
    const exactTitles = <String, String>{
      '/': '首頁',
      '/login': '登入',
      '/cart': '購物車',
      '/orders/new': '結帳',
      '/orders': '訂單記錄',
      '/chat': '客服聊天',
      '/profile': '個人資料',
    };

    if (exactTitles.containsKey(path)) {
      return exactTitles[path]!;
    }

    // 訂單成功頁：/orders/success/{orderId}
    if (RegExp(r'^/orders/success/[^/]+$').hasMatch(path)) {
      return '訂單成功';
    }

    // 商品詳情頁：/products/{categoryId}/{productId}
    if (RegExp(r'^/products/[^/]+/[^/]+$').hasMatch(path)) {
      return '商品詳情';
    }

    // 分類商品列表：/products/{categoryId}
    if (RegExp(r'^/products/[^/]+$').hasMatch(path)) {
      return '商品列表';
    }

    // 未知路由：以路徑本身作為標題
    return path;
  }

  // ── NavigatorObserver 覆寫 ──────────────────────────────────────────────────

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _handleRouteChange(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _handleRouteChange(newRoute);
    }
  }

  void _handleRouteChange(Route<dynamic> route) {
    final path = route.settings.name;
    if (path == null || path.isEmpty) return;

    final title = _resolveTitle(path);
    // title 為 null 代表後台頁面，略過追蹤
    if (title == null) {
      _previousPath = path;
      return;
    }

    final referrer = _previousPath;
    _previousPath = path;

    // fire-and-forget：不 await，不影響導航流程
    tracker.trackPageView(
      path: path,
      title: title,
      referrer: referrer,
    );
  }
}
