// lib/core/tracking/page_view_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/providers/auth_providers.dart';
import 'page_view_tracker.dart';

part 'page_view_providers.g.dart';

// ── PageViewTracker Provider ──────────────────────────────────────────────────

/// 全站頁面瀏覽追蹤器 Provider。
///
/// keepAlive：整個 App 生命週期共用同一個 tracker 實例，
/// 確保 sessionId 與 userId 狀態持續有效。
@Riverpod(keepAlive: true)
PageViewTracker pageViewTracker(Ref ref) {
  final tracker = PageViewTracker(
    firestore: FirebaseFirestore.instance,
  );

  // 監聽 auth 狀態，Auth 變化時同步更新 tracker 的 userId
  ref.listen(authStateProvider, (previous, next) {
    next.whenData((user) => tracker.updateUserId(user?.uid));
  });

  return tracker;
}

// ── PageViewTrackerObserver Provider ─────────────────────────────────────────

/// GoRouter observers 所需的 NavigatorObserver Provider。
///
/// keepAlive：與 appRouterProvider 同生命週期，
/// 確保 observer 實例不被意外 dispose。
@Riverpod(keepAlive: true)
PageViewTrackerObserver pageViewTrackerObserver(Ref ref) {
  return PageViewTrackerObserver(
    tracker: ref.read(pageViewTrackerProvider),
  );
}
