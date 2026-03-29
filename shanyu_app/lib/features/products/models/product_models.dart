// lib/features/products/models/product_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 商品資料模型（Dart 端）。
/// 對應 Firestore `products` 集合。
/// `isPreorder` 與 `minPrice` 由 variants 子集合衍生，
/// 此處直接從 denormalized 欄位讀取（由 Cloud Functions 維護）。
class ProductModel {
  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.status,
    required this.sortOrder,
    required this.isPreorder,
    this.minPrice,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String coverImageUrl;

  /// 'active' | 'draft'
  final String status;

  final int sortOrder;

  /// 是否為預購商品（由 variants 決定）
  final bool isPreorder;

  /// 最低價格，單位：新台幣（由 variants 決定）
  final int? minPrice;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      categoryId: (data['categoryId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      coverImageUrl: (data['coverImageUrl'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'draft',
      sortOrder: (data['sortOrder'] as int?) ?? 0,
      isPreorder: (data['isPreorder'] as bool?) ?? false,
      minPrice: data['minPrice'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
