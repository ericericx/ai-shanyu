// lib/features/products/data/product_view_tracker.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 商品瀏覽行為追蹤。
///
/// 每次使用者進入商品詳情頁時，寫入一筆 `productViews` 記錄，
/// 供後台 CRM 分析使用。
///
/// 遵循靜默失敗原則：任何 Firestore 錯誤只記錄至 debug console，
/// 不對頁面流程造成任何影響。
class ProductViewTracker {
  ProductViewTracker({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// 寫入商品瀏覽記錄。
  ///
  /// - [productId]：被瀏覽的商品 ID
  /// - [productName]：商品名稱，供後台 CRM 直接顯示
  /// - [userId]：目前登入的使用者 UID；匿名瀏覽時傳入 null
  Future<void> trackProductView(
    String productId,
    String? userId, {
    String? productName,
  }) async {
    try {
      await _firestore.collection('productViews').add({
        'productId': productId,
        if (productName != null) 'productName': productName,
        'userId': userId,
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } catch (error, stackTrace) {
      // 靜默失敗：僅在 debug 模式下印出，不影響頁面流程
      debugPrint('[ProductViewTracker] trackProductView 失敗: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 6);
    }
  }
}
