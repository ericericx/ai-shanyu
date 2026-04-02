// lib/features/admin/data/products_admin_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../products/models/category_model.dart';
import '../../products/models/product_models.dart';

// ── AdminCategoryModel ────────────────────────────────────────────────────────

/// 管理後台用的分類模型，額外包含 `isActive` 欄位。
class AdminCategoryModel {
  const AdminCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final int sortOrder;
  final bool isActive;

  factory AdminCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminCategoryModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      slug: (data['slug'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      sortOrder: (data['sortOrder'] as int?) ?? 0,
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  AdminCategoryModel copyWith({
    String? name,
    String? slug,
    String? description,
    int? sortOrder,
    bool? isActive,
  }) {
    return AdminCategoryModel(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'slug': slug,
        'description': description,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };
}

// ── AdminProductModel ─────────────────────────────────────────────────────────

/// 管理後台用的商品模型，額外包含 `scheduledAt` 欄位。
class AdminProductModel {
  const AdminProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.status,
    required this.sortOrder,
    required this.isPreorder,
    this.minPrice,
    this.scheduledAt,
    this.seasonalMonths,
    this.growingStartMonth,
    this.growingEndMonth,
    this.harvestStartMonth,
    this.harvestEndMonth,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String coverImageUrl;

  /// 'draft' | 'active' | 'archived'
  final String status;

  final int sortOrder;
  final bool isPreorder;
  final int? minPrice;

  /// 預約上架時間（可為 null）
  final DateTime? scheduledAt;

  /// 季節性月份，例如 [6, 7, 8] 代表夏季
  final List<int>? seasonalMonths;

  /// 生長期起始月（1–12，null 表示未設定）
  final int? growingStartMonth;

  /// 生長期結束月（1–12，null 表示未設定）
  final int? growingEndMonth;

  /// 採收期起始月（1–12，null 表示未設定）
  final int? harvestStartMonth;

  /// 採收期結束月（1–12，null 表示未設定）
  final int? harvestEndMonth;

  factory AdminProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final scheduledAtTs = data['scheduledAt'] as Timestamp?;
    final rawMonths = data['seasonalMonths'] as List<dynamic>?;
    return AdminProductModel(
      id: doc.id,
      categoryId: (data['categoryId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      coverImageUrl: (data['coverImageUrl'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'draft',
      sortOrder: (data['sortOrder'] as int?) ?? 0,
      isPreorder: (data['isPreorder'] as bool?) ?? false,
      minPrice: data['minPrice'] as int?,
      scheduledAt: scheduledAtTs?.toDate(),
      seasonalMonths: rawMonths?.map((e) => e as int).toList(),
      growingStartMonth: data['growingStartMonth'] as int?,
      growingEndMonth: data['growingEndMonth'] as int?,
      harvestStartMonth: data['harvestStartMonth'] as int?,
      harvestEndMonth: data['harvestEndMonth'] as int?,
    );
  }
}

// ── ProductsAdminRepository ───────────────────────────────────────────────────

/// 商品與分類的管理員寫入層。
///
/// 提供 CRUD 操作給 `/admin/products` 頁面使用。
class ProductsAdminRepository {
  ProductsAdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _kCategories = 'categories';
  static const _kProducts = 'products';

  // ── 分類 ────────────────────────────────────────────────────────────────────

  /// 監聽所有分類（不限 isActive），依 sortOrder 排序。
  Stream<List<AdminCategoryModel>> watchAllCategories() {
    return _firestore
        .collection(_kCategories)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(AdminCategoryModel.fromFirestore).toList(),
        );
  }

  /// 建立新分類。
  Future<void> createCategory(CategoryModel category) async {
    await _firestore.collection(_kCategories).add({
      'name': category.name,
      'slug': category.slug,
      'description': category.description,
      'coverImageUrl': category.coverImageUrl,
      'sortOrder': category.sortOrder,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 更新分類指定欄位。
  Future<void> updateCategory(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(_kCategories).doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 刪除分類。
  Future<void> deleteCategory(String id) async {
    await _firestore.collection(_kCategories).doc(id).delete();
  }

  // ── 商品 ────────────────────────────────────────────────────────────────────

  /// 監聽所有商品（含 draft、archived），依 sortOrder 排序。
  Stream<List<AdminProductModel>> watchAllProducts() {
    return _firestore
        .collection(_kProducts)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(AdminProductModel.fromFirestore).toList(),
        );
  }

  /// 監聽指定分類下的所有商品。
  Stream<List<AdminProductModel>> watchProductsByCategory(String categoryId) {
    return _firestore
        .collection(_kProducts)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(AdminProductModel.fromFirestore).toList(),
        );
  }

  /// 建立新商品。
  Future<void> createProduct(ProductModel product) async {
    await _firestore.collection(_kProducts).add({
      'categoryId': product.categoryId,
      'name': product.name,
      'description': product.description,
      'coverImageUrl': product.coverImageUrl,
      'status': product.status,
      'sortOrder': product.sortOrder,
      'isPreorder': product.isPreorder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 更新商品狀態，並可選擇設定預約上架時間。
  Future<void> updateProductStatus(
    String id,
    String status, {
    DateTime? scheduledAt,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (scheduledAt != null) {
      payload['scheduledAt'] = Timestamp.fromDate(scheduledAt);
    } else {
      // 明確傳入 null 時清除 scheduledAt
      payload['scheduledAt'] = FieldValue.delete();
    }

    await _firestore.collection(_kProducts).doc(id).update(payload);
  }

  /// 更新商品的生長期與採收期月份。
  Future<void> updateProductSeasons(
    String id, {
    required int growingStartMonth,
    required int growingEndMonth,
    required int harvestStartMonth,
    required int harvestEndMonth,
  }) async {
    await _firestore.collection(_kProducts).doc(id).update({
      'growingStartMonth': growingStartMonth,
      'growingEndMonth': growingEndMonth,
      'harvestStartMonth': harvestStartMonth,
      'harvestEndMonth': harvestEndMonth,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
