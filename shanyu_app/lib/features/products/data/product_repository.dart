// lib/features/products/data/product_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';
import '../models/product_models.dart';

/// 商品與分類的 Firestore 資料存取層。
class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// 監聽指定分類下所有 status == 'active' 的商品，依 sortOrder 排序。
  Stream<List<ProductModel>> watchProductsByCategory(String categoryId) {
    return _firestore
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'active')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ProductModel.fromFirestore).toList(),
        );
  }

  /// 監聽所有分類，依 sortOrder 排序。
  Stream<List<CategoryModel>> watchCategories() {
    return _firestore
        .collection('categories')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(CategoryModel.fromFirestore).toList(),
        );
  }

  /// 取得單一分類資料（一次性讀取）。
  Future<CategoryModel?> fetchCategory(String categoryId) async {
    final doc =
        await _firestore.collection('categories').doc(categoryId).get();
    if (!doc.exists) return null;
    return CategoryModel.fromFirestore(doc);
  }
}
