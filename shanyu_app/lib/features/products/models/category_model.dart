// lib/features/products/models/category_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 商品分類資料模型。
/// 對應 Firestore `categories` 集合。
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.coverImageUrl,
    required this.sortOrder,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String coverImageUrl;
  final int sortOrder;
  final bool isActive;

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      slug: (data['slug'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      coverImageUrl: (data['coverImageUrl'] as String?) ?? '',
      sortOrder: (data['sortOrder'] as int?) ?? 0,
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
