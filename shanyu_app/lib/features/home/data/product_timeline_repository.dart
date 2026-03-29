// lib/features/home/data/product_timeline_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_timeline_models.dart';

/// 從 Firestore 讀取 active 商品，供季節流水線元件使用。
class ProductTimelineRepository {
  ProductTimelineRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// 監聽所有 status == 'active' 的商品，依 sortOrder 排序。
  Stream<List<TimelineProduct>> watchActiveProducts() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(TimelineProduct.fromFirestore)
              .toList(),
        );
  }
}
