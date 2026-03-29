// lib/features/products/models/product_detail_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// ── ProductDetailModel ────────────────────────────────────────────────────────

/// 商品詳情資料模型，對應 Firestore `products/{productId}` 文件。
/// 比 ProductModel 多了 story、imageUrls 等詳細資訊。
class ProductDetailModel {
  const ProductDetailModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.story,
    required this.coverImageUrl,
    required this.imageUrls,
    required this.status,
    required this.isPreorder,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;

  /// 品牌故事 / 產品故事（長文）
  final String story;

  final String coverImageUrl;

  /// 額外展示圖片列表（不含 coverImageUrl）
  final List<String> imageUrls;

  /// 'active' | 'draft'
  final String status;

  final bool isPreorder;

  factory ProductDetailModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final rawImages = data['imageUrls'] as List<dynamic>? ?? [];
    final imageUrls = rawImages.whereType<String>().toList();

    return ProductDetailModel(
      id: doc.id,
      categoryId: (data['categoryId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      story: (data['story'] as String?) ?? '',
      coverImageUrl: (data['coverImageUrl'] as String?) ?? '',
      imageUrls: imageUrls,
      status: (data['status'] as String?) ?? 'draft',
      isPreorder: (data['isPreorder'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductDetailModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ── ProductVariantModel ───────────────────────────────────────────────────────

/// 商品變體資料模型，對應 Firestore `products/{productId}/variants/{variantId}`。
class ProductVariantModel {
  const ProductVariantModel({
    required this.id,
    required this.name,
    required this.price,
    this.comparePrice,
    required this.stock,
    required this.unit,
    required this.imageUrls,
    required this.isPreorder,
    this.estimatedShipDate,
  });

  final String id;
  final String name;

  /// 售價，單位：新台幣（整數）
  final int price;

  /// 原價（顯示刪除線用），若無折扣則為 null
  final int? comparePrice;

  /// 庫存數量；>0 表示有庫存，<=0 表示售完或待進貨
  final int stock;

  /// 計量單位，例如「斤」「盒」「公斤」
  final String unit;

  /// 變體附圖（可為空列表）
  final List<String> imageUrls;

  final bool isPreorder;

  /// 預估出貨日（ISO 8601 格式），僅預購且缺貨時顯示
  final String? estimatedShipDate;

  bool get isAvailable => stock > 0 || isPreorder;

  factory ProductVariantModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final rawImages = data['imageUrls'] as List<dynamic>? ?? [];
    final imageUrls = rawImages.whereType<String>().toList();

    return ProductVariantModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      price: (data['price'] as int?) ?? 0,
      comparePrice: data['comparePrice'] as int?,
      stock: (data['stock'] as int?) ?? 0,
      unit: (data['unit'] as String?) ?? '',
      imageUrls: imageUrls,
      isPreorder: (data['isPreorder'] as bool?) ?? false,
      estimatedShipDate: data['estimatedShipDate'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVariantModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
