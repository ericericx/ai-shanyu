// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productRepositoryHash() => r'476e2fc385c456e43ba14088eaf8a71ef314514f';

/// ProductRepository 單例。
///
/// Copied from [productRepository].
@ProviderFor(productRepository)
final productRepositoryProvider = Provider<ProductRepository>.internal(
  productRepository,
  name: r'productRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProductRepositoryRef = ProviderRef<ProductRepository>;
String _$productsByCategoryHash() =>
    r'1cd360b6a6d4b8ffb7dd6c7f5bfa6f4ab212fef8';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 監聽指定分類下的 active 商品列表。
///
/// Copied from [productsByCategory].
@ProviderFor(productsByCategory)
const productsByCategoryProvider = ProductsByCategoryFamily();

/// 監聽指定分類下的 active 商品列表。
///
/// Copied from [productsByCategory].
class ProductsByCategoryFamily extends Family<AsyncValue<List<ProductModel>>> {
  /// 監聽指定分類下的 active 商品列表。
  ///
  /// Copied from [productsByCategory].
  const ProductsByCategoryFamily();

  /// 監聽指定分類下的 active 商品列表。
  ///
  /// Copied from [productsByCategory].
  ProductsByCategoryProvider call(String categoryId) {
    return ProductsByCategoryProvider(categoryId);
  }

  @override
  ProductsByCategoryProvider getProviderOverride(
    covariant ProductsByCategoryProvider provider,
  ) {
    return call(provider.categoryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'productsByCategoryProvider';
}

/// 監聽指定分類下的 active 商品列表。
///
/// Copied from [productsByCategory].
class ProductsByCategoryProvider
    extends AutoDisposeStreamProvider<List<ProductModel>> {
  /// 監聽指定分類下的 active 商品列表。
  ///
  /// Copied from [productsByCategory].
  ProductsByCategoryProvider(String categoryId)
    : this._internal(
        (ref) => productsByCategory(ref as ProductsByCategoryRef, categoryId),
        from: productsByCategoryProvider,
        name: r'productsByCategoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$productsByCategoryHash,
        dependencies: ProductsByCategoryFamily._dependencies,
        allTransitiveDependencies:
            ProductsByCategoryFamily._allTransitiveDependencies,
        categoryId: categoryId,
      );

  ProductsByCategoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
  }) : super.internal();

  final String categoryId;

  @override
  Override overrideWith(
    Stream<List<ProductModel>> Function(ProductsByCategoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProductsByCategoryProvider._internal(
        (ref) => create(ref as ProductsByCategoryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ProductModel>> createElement() {
    return _ProductsByCategoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductsByCategoryProvider &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProductsByCategoryRef
    on AutoDisposeStreamProviderRef<List<ProductModel>> {
  /// The parameter `categoryId` of this provider.
  String get categoryId;
}

class _ProductsByCategoryProviderElement
    extends AutoDisposeStreamProviderElement<List<ProductModel>>
    with ProductsByCategoryRef {
  _ProductsByCategoryProviderElement(super.provider);

  @override
  String get categoryId => (origin as ProductsByCategoryProvider).categoryId;
}

String _$categoriesHash() => r'd59dfe38dc788de1bec3174fb689b476ec9ed279';

/// 監聽所有分類列表。
///
/// Copied from [categories].
@ProviderFor(categories)
final categoriesProvider =
    AutoDisposeStreamProvider<List<CategoryModel>>.internal(
      categories,
      name: r'categoriesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$categoriesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoriesRef = AutoDisposeStreamProviderRef<List<CategoryModel>>;
String _$categoryByIdHash() => r'9f7dc13c37d64166a86e835047d262683f1d8721';

/// 取得單一分類資料，用於列表頁標題顯示。
///
/// Copied from [categoryById].
@ProviderFor(categoryById)
const categoryByIdProvider = CategoryByIdFamily();

/// 取得單一分類資料，用於列表頁標題顯示。
///
/// Copied from [categoryById].
class CategoryByIdFamily extends Family<AsyncValue<CategoryModel?>> {
  /// 取得單一分類資料，用於列表頁標題顯示。
  ///
  /// Copied from [categoryById].
  const CategoryByIdFamily();

  /// 取得單一分類資料，用於列表頁標題顯示。
  ///
  /// Copied from [categoryById].
  CategoryByIdProvider call(String categoryId) {
    return CategoryByIdProvider(categoryId);
  }

  @override
  CategoryByIdProvider getProviderOverride(
    covariant CategoryByIdProvider provider,
  ) {
    return call(provider.categoryId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'categoryByIdProvider';
}

/// 取得單一分類資料，用於列表頁標題顯示。
///
/// Copied from [categoryById].
class CategoryByIdProvider extends AutoDisposeFutureProvider<CategoryModel?> {
  /// 取得單一分類資料，用於列表頁標題顯示。
  ///
  /// Copied from [categoryById].
  CategoryByIdProvider(String categoryId)
    : this._internal(
        (ref) => categoryById(ref as CategoryByIdRef, categoryId),
        from: categoryByIdProvider,
        name: r'categoryByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$categoryByIdHash,
        dependencies: CategoryByIdFamily._dependencies,
        allTransitiveDependencies:
            CategoryByIdFamily._allTransitiveDependencies,
        categoryId: categoryId,
      );

  CategoryByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.categoryId,
  }) : super.internal();

  final String categoryId;

  @override
  Override overrideWith(
    FutureOr<CategoryModel?> Function(CategoryByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CategoryByIdProvider._internal(
        (ref) => create(ref as CategoryByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        categoryId: categoryId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<CategoryModel?> createElement() {
    return _CategoryByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryByIdProvider && other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CategoryByIdRef on AutoDisposeFutureProviderRef<CategoryModel?> {
  /// The parameter `categoryId` of this provider.
  String get categoryId;
}

class _CategoryByIdProviderElement
    extends AutoDisposeFutureProviderElement<CategoryModel?>
    with CategoryByIdRef {
  _CategoryByIdProviderElement(super.provider);

  @override
  String get categoryId => (origin as CategoryByIdProvider).categoryId;
}

String _$productDetailHash() => r'20074514628d3c62532f3369b1a69e8fd0bc7184';

/// 監聽單一商品詳情（含 story、imageUrls）。
///
/// Copied from [productDetail].
@ProviderFor(productDetail)
const productDetailProvider = ProductDetailFamily();

/// 監聽單一商品詳情（含 story、imageUrls）。
///
/// Copied from [productDetail].
class ProductDetailFamily extends Family<AsyncValue<ProductDetailModel>> {
  /// 監聽單一商品詳情（含 story、imageUrls）。
  ///
  /// Copied from [productDetail].
  const ProductDetailFamily();

  /// 監聽單一商品詳情（含 story、imageUrls）。
  ///
  /// Copied from [productDetail].
  ProductDetailProvider call(String productId) {
    return ProductDetailProvider(productId);
  }

  @override
  ProductDetailProvider getProviderOverride(
    covariant ProductDetailProvider provider,
  ) {
    return call(provider.productId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'productDetailProvider';
}

/// 監聽單一商品詳情（含 story、imageUrls）。
///
/// Copied from [productDetail].
class ProductDetailProvider
    extends AutoDisposeStreamProvider<ProductDetailModel> {
  /// 監聽單一商品詳情（含 story、imageUrls）。
  ///
  /// Copied from [productDetail].
  ProductDetailProvider(String productId)
    : this._internal(
        (ref) => productDetail(ref as ProductDetailRef, productId),
        from: productDetailProvider,
        name: r'productDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$productDetailHash,
        dependencies: ProductDetailFamily._dependencies,
        allTransitiveDependencies:
            ProductDetailFamily._allTransitiveDependencies,
        productId: productId,
      );

  ProductDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.productId,
  }) : super.internal();

  final String productId;

  @override
  Override overrideWith(
    Stream<ProductDetailModel> Function(ProductDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProductDetailProvider._internal(
        (ref) => create(ref as ProductDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        productId: productId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<ProductDetailModel> createElement() {
    return _ProductDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductDetailProvider && other.productId == productId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, productId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProductDetailRef on AutoDisposeStreamProviderRef<ProductDetailModel> {
  /// The parameter `productId` of this provider.
  String get productId;
}

class _ProductDetailProviderElement
    extends AutoDisposeStreamProviderElement<ProductDetailModel>
    with ProductDetailRef {
  _ProductDetailProviderElement(super.provider);

  @override
  String get productId => (origin as ProductDetailProvider).productId;
}

String _$productVariantsHash() => r'66dd22846ba9791114567f278ae4e38d643ce5ac';

/// 監聽指定商品的所有變體列表。
///
/// Copied from [productVariants].
@ProviderFor(productVariants)
const productVariantsProvider = ProductVariantsFamily();

/// 監聽指定商品的所有變體列表。
///
/// Copied from [productVariants].
class ProductVariantsFamily
    extends Family<AsyncValue<List<ProductVariantModel>>> {
  /// 監聽指定商品的所有變體列表。
  ///
  /// Copied from [productVariants].
  const ProductVariantsFamily();

  /// 監聽指定商品的所有變體列表。
  ///
  /// Copied from [productVariants].
  ProductVariantsProvider call(String productId) {
    return ProductVariantsProvider(productId);
  }

  @override
  ProductVariantsProvider getProviderOverride(
    covariant ProductVariantsProvider provider,
  ) {
    return call(provider.productId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'productVariantsProvider';
}

/// 監聽指定商品的所有變體列表。
///
/// Copied from [productVariants].
class ProductVariantsProvider
    extends AutoDisposeStreamProvider<List<ProductVariantModel>> {
  /// 監聽指定商品的所有變體列表。
  ///
  /// Copied from [productVariants].
  ProductVariantsProvider(String productId)
    : this._internal(
        (ref) => productVariants(ref as ProductVariantsRef, productId),
        from: productVariantsProvider,
        name: r'productVariantsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$productVariantsHash,
        dependencies: ProductVariantsFamily._dependencies,
        allTransitiveDependencies:
            ProductVariantsFamily._allTransitiveDependencies,
        productId: productId,
      );

  ProductVariantsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.productId,
  }) : super.internal();

  final String productId;

  @override
  Override overrideWith(
    Stream<List<ProductVariantModel>> Function(ProductVariantsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProductVariantsProvider._internal(
        (ref) => create(ref as ProductVariantsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        productId: productId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ProductVariantModel>> createElement() {
    return _ProductVariantsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductVariantsProvider && other.productId == productId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, productId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProductVariantsRef
    on AutoDisposeStreamProviderRef<List<ProductVariantModel>> {
  /// The parameter `productId` of this provider.
  String get productId;
}

class _ProductVariantsProviderElement
    extends AutoDisposeStreamProviderElement<List<ProductVariantModel>>
    with ProductVariantsRef {
  _ProductVariantsProviderElement(super.provider);

  @override
  String get productId => (origin as ProductVariantsProvider).productId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
