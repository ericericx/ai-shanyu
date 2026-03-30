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

    return sorted.take(limit).map((entry) {
      return PopularProduct(
        productId: entry.key,
        productName: nameMap[entry.key],
        viewCount: entry.value,
      );
    }).toList();
  }
}
