// lib/features/admin/data/crm_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/crm_models.dart';

/// CRM 資料存取層 — 讀取商品瀏覽記錄與熱門商品排行。
///
/// Firestore 結構：
/// ```
/// productViews/{docId}
///   productId: string
///   productName: string (optional)
///   userId: string (optional)
///   viewedAt: Timestamp
/// ```
class CrmRepository {
  CrmRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _viewsCol =>
      _firestore.collection('productViews');

  CollectionReference<Map<String, dynamic>> get _productsCol =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _pageViewsCol =>
      _firestore.collection('pageViews');

  /// 快取：productId → productName，避免重複查詢
  final Map<String, String> _productNameCache = {};

  /// 根據 productId 批量查詢商品名稱，回傳 id→name 對應表。
  Future<Map<String, String>> resolveProductNames(Set<String> ids) async {
    final result = <String, String>{};
    final toFetch = <String>[];

    for (final id in ids) {
      if (_productNameCache.containsKey(id)) {
        result[id] = _productNameCache[id]!;
      } else {
        toFetch.add(id);
      }
    }

    if (toFetch.isNotEmpty) {
      final futures = toFetch.map((id) => _productsCol.doc(id).get());
      final docs = await Future.wait(futures);
      for (final doc in docs) {
        if (doc.exists) {
          final name = (doc.data()?['name'] as String?) ?? '';
          if (name.isNotEmpty) {
            _productNameCache[doc.id] = name;
            result[doc.id] = name;
          }
        }
      }
    }

    return result;
  }

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection('orders');

  // ── 瀏覽記錄查詢 ──────────────────────────────────────────────────────────

  /// 取得商品瀏覽記錄，支援以 productId、日期範圍篩選，以及游標分頁。
  Future<List<ProductViewRecord>> getProductViews({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    Query<Map<String, dynamic>> query =
        _viewsCol.orderBy('viewedAt', descending: true);

    if (productId != null && productId.isNotEmpty) {
      query = query.where('productId', isEqualTo: productId);
    }

    if (startDate != null) {
      query = query.where(
        'viewedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'viewedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(
          endDate.copyWith(hour: 23, minute: 59, second: 59),
        ),
      );
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map(ProductViewRecord.fromFirestore).toList();
  }

  /// 取得分頁用的原始 DocumentSnapshot 清單（供下一頁游標使用）。
  Future<List<DocumentSnapshot>> getProductViewDocs({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    Query<Map<String, dynamic>> query =
        _viewsCol.orderBy('viewedAt', descending: true);

    if (productId != null && productId.isNotEmpty) {
      query = query.where('productId', isEqualTo: productId);
    }

    if (startDate != null) {
      query = query.where(
        'viewedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'viewedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(
          endDate.copyWith(hour: 23, minute: 59, second: 59),
        ),
      );
    }

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs;
  }

  // ── 熱門商品排行 ──────────────────────────────────────────────────────────

  /// 取得熱門商品前 N 名（依瀏覽次數聚合）。
  ///
  /// 由於 Firestore 不支援 GROUP BY，此處在 client 端對最近 1000 筆記錄做聚合。
  /// 若資料量大，建議改為 Cloud Functions 定期計算並寫入 `popularProducts` 集合。
  Future<List<PopularProduct>> getTopProducts({int limit = 5}) async {
    // 取近 1000 筆，做 client 端聚合
    final snapshot = await _viewsCol
        .orderBy('viewedAt', descending: true)
        .limit(1000)
        .get();

    final countMap = <String, int>{};
    final nameMap = <String, String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final productId = (data['productId'] as String?) ?? '';
      if (productId.isEmpty) continue;

      countMap[productId] = (countMap[productId] ?? 0) + 1;
      if (!nameMap.containsKey(productId)) {
        final name = data['productName'] as String?;
        if (name != null) nameMap[productId] = name;
      }
    }

    final sorted = countMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sorted.take(limit).toList();

    // 對缺少 productName 的商品，從 products 集合反查名稱
    final missingIds = topEntries
        .where((e) => !nameMap.containsKey(e.key))
        .map((e) => e.key)
        .toSet();
    if (missingIds.isNotEmpty) {
      final resolved = await resolveProductNames(missingIds);
      nameMap.addAll(resolved);
    }

    return topEntries.map((entry) {
      return PopularProduct(
        productId: entry.key,
        productName: nameMap[entry.key],
        viewCount: entry.value,
      );
    }).toList();
  }

  // ── 概覽統計 ──────────────────────────────────────────────────────────────

  /// 取得概覽統計：今日瀏覽數、本月訂單數、本月營收、活躍使用者數。
  ///
  /// 三項查詢以 [Future.wait] 平行執行，降低總延遲。
  Future<OverviewStats> getOverviewStats() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    final results = await Future.wait([
      _pageViewsCol
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
          )
          .get(),
      _pageViewsCol
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .limit(1000)
          .get(),
      _ordersCol
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          .get(),
    ]);

    final todayViews = results[0].docs.length;

    final monthPageViews = results[1].docs;
    final activeUserIds = <String>{};
    for (final doc in monthPageViews) {
      final userId = doc.data()['userId'] as String?;
      if (userId != null) activeUserIds.add(userId);
    }

    final orderDocs = results[2].docs;
    var monthlyRevenue = 0;
    for (final doc in orderDocs) {
      final data = doc.data();
      monthlyRevenue += (data['total'] as int?) ?? 0;
    }

    return OverviewStats(
      todayPageViews: todayViews,
      monthlyOrders: orderDocs.length,
      monthlyRevenue: monthlyRevenue,
      activeUsers: activeUserIds.length,
    );
  }

  // ── 熱門頁面排行 ──────────────────────────────────────────────────────────

  /// 取得指定時間範圍內瀏覽次數最高的頁面前 [limit] 名。
  ///
  /// Client 端對最近 1000 筆 pageViews 做聚合。
  Future<List<PopularPage>> getTopPages({
    required DateTime since,
    int limit = 10,
  }) async {
    final snapshot = await _pageViewsCol
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since),
        )
        .orderBy('timestamp', descending: true)
        .limit(1000)
        .get();

    final countMap = <String, int>{};
    final titleMap = <String, String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final path = (data['path'] as String?) ?? '';
      if (path.isEmpty) continue;
      countMap[path] = (countMap[path] ?? 0) + 1;
      if (!titleMap.containsKey(path)) {
        titleMap[path] = (data['title'] as String?) ?? path;
      }
    }

    final sorted = countMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) {
      return PopularPage(
        path: e.key,
        title: titleMap[e.key] ?? e.key,
        viewCount: e.value,
      );
    }).toList();
  }
}
