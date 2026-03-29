// lib/features/products/providers/product_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/product_repository.dart';
import '../models/category_model.dart';
import '../models/product_detail_model.dart';
import '../models/product_models.dart';

part 'product_providers.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

/// ProductRepository 單例。
@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) {
  return ProductRepository();
}

// ── Stream Providers ──────────────────────────────────────────────────────────

/// 監聽指定分類下的 active 商品列表。
@riverpod
Stream<List<ProductModel>> productsByCategory(
  Ref ref,
  String categoryId,
) {
  return ref
      .watch(productRepositoryProvider)
      .watchProductsByCategory(categoryId);
}

/// 監聽所有分類列表。
@riverpod
Stream<List<CategoryModel>> categories(Ref ref) {
  return ref.watch(productRepositoryProvider).watchCategories();
}

// ── 單一分類（FutureProvider）────────────────────────────────────────────────

/// 取得單一分類資料，用於列表頁標題顯示。
@riverpod
Future<CategoryModel?> categoryById(Ref ref, String categoryId) {
  return ref
      .watch(productRepositoryProvider)
      .fetchCategory(categoryId);
}

// ── 商品詳情 Stream Providers ─────────────────────────────────────────────────

/// 監聽單一商品詳情（含 story、imageUrls）。
@riverpod
Stream<ProductDetailModel> productDetail(Ref ref, String productId) {
  return ref
      .watch(productRepositoryProvider)
      .watchProductDetail(productId);
}

/// 監聽指定商品的所有變體列表。
@riverpod
Stream<List<ProductVariantModel>> productVariants(Ref ref, String productId) {
  return ref
      .watch(productRepositoryProvider)
      .watchVariants(productId);
}
