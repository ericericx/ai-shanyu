// lib/features/home/models/product_timeline_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 季節流水線用的商品資料模型。
/// 對應 Firestore `products` 集合中的欄位。
class TimelineProduct {
  const TimelineProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.growingStartMonth,
    required this.growingEndMonth,
    required this.harvestStartMonth,
    required this.harvestEndMonth,
    required this.status,
  });

  final String id;
  final String categoryId;
  final String name;

  /// 生長期起始月份（1–12）
  final int growingStartMonth;

  /// 生長期結束月份（1–12）
  final int growingEndMonth;

  /// 採收期起始月份（1–12）
  final int harvestStartMonth;

  /// 採收期結束月份（1–12）
  final int harvestEndMonth;

  /// 'active' | 'draft'
  final String status;

  factory TimelineProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimelineProduct(
      id: doc.id,
      categoryId: (data['categoryId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      growingStartMonth: (data['growingStartMonth'] as int?) ?? 0,
      growingEndMonth: (data['growingEndMonth'] as int?) ?? 0,
      harvestStartMonth: (data['harvestStartMonth'] as int?) ?? 0,
      harvestEndMonth: (data['harvestEndMonth'] as int?) ?? 0,
      status: (data['status'] as String?) ?? 'draft',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineProduct &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
