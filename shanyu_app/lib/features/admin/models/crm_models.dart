// lib/features/admin/models/crm_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 單筆商品瀏覽記錄。
class ProductViewRecord {
  const ProductViewRecord({
    required this.id,
    required this.productId,
    this.productName,
    this.userId,
    required this.viewedAt,
  });

  final String id;
  final String productId;
  final String? productName;
  final String? userId;
  final DateTime viewedAt;

  factory ProductViewRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final viewedAtRaw = data['viewedAt'] ?? data['createdAt'];
    final DateTime viewedAt;
    if (viewedAtRaw is Timestamp) {
      viewedAt = viewedAtRaw.toDate();
    } else {
      viewedAt = DateTime.now();
    }

    return ProductViewRecord(
      id: doc.id,
      productId: (data['productId'] as String?) ?? '',
      productName: data['productName'] as String?,
      userId: data['userId'] as String?,
      viewedAt: viewedAt,
    );
  }
}

/// 熱門商品排行（依瀏覽次數聚合）。
class PopularProduct {
  const PopularProduct({
    required this.productId,
    this.productName,
    required this.viewCount,
  });

  final String productId;
  final String? productName;
  final int viewCount;
}
