// lib/features/products/data/product_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';
import '../models/product_detail_model.dart';
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

  /// 監聽所有顯示中的分類，依 sortOrder 排序。
  Stream<List<CategoryModel>> watchCategories() {
    return _firestore
        .collection('categories')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CategoryModel.fromFirestore)
              .where((c) => c.isActive)
              .toList(),
        );
  }

  /// 取得單一分類資料（一次性讀取）。
  Future<CategoryModel?> fetchCategory(String categoryId) async {
    final doc =
        await _firestore.collection('categories').doc(categoryId).get();
    if (!doc.exists) return null;
    return CategoryModel.fromFirestore(doc);
  }

  /// 監聽單一商品詳情（含 story、imageUrls）。
  Stream<ProductDetailModel> watchProductDetail(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) {
        throw Exception('農產 $productId 不存在');
      }
      return ProductDetailModel.fromFirestore(snap);
    });
  }

  /// 監聽指定商品的所有變體，依 sortOrder 排序。
  Stream<List<ProductVariantModel>> watchVariants(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('variants')
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ProductVariantModel.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }
}
