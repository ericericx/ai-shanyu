// lib/features/admin/presentation/products_admin_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../products/models/category_model.dart';
import '../../products/models/product_models.dart';
import '../../home/models/product_timeline_models.dart';
import '../../home/presentation/widgets/product_timeline.dart';
import '../data/products_admin_repository.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _Tokens {
  static const surface = Color(0xFFFAF8F5);
  static const brandBrown = Color(0xFF5C4033);
  static const brandBrownLight = Color(0xFF8D6E63);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const divider = Color(0xFFEFEBE9);
  static const cardBg = Colors.white;

  // 狀態顏色
  static const statusActive = Color(0xFF2E7D32);
  static const statusActiveBg = Color(0xFFE8F5E9);
  static const statusDraft = Color(0xFF1565C0);
  static const statusDraftBg = Color(0xFFE3F2FD);
  static const statusArchived = Color(0xFF616161);
  static const statusArchivedBg = Color(0xFFF5F5F5);

  static const cardBorderRadius = 8.0;
  static const sectionPadding = EdgeInsets.all(16.0);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _repoProvider = Provider<ProductsAdminRepository>(
  (ref) => ProductsAdminRepository(),
);

final _allCategoriesProvider =
    StreamProvider<List<AdminCategoryModel>>((ref) {
  return ref.watch(_repoProvider).watchAllCategories();
});

final _allProductsProvider =
    StreamProvider<List<AdminProductModel>>((ref) {
  return ref.watch(_repoProvider).watchAllProducts();
});

/// 當前選擇的分類篩選（null 代表全部）
final _selectedCategoryFilterProvider =
    StateProvider<String?>((ref) => null);

/// 商品排序方式（循環切換：狀態 → 分類 → 時間）
enum _ProductSortBy {
  status(Icons.toggle_on_outlined, '狀態排序'),
  category(Icons.category_outlined, '分類排序'),
  updatedAt(Icons.schedule_outlined, '時間排序');

  const _ProductSortBy(this.icon, this.label);
  final IconData icon;
  final String label;

  _ProductSortBy get next =>
      _ProductSortBy.values[(index + 1) % _ProductSortBy.values.length];
}

final _productSortByProvider =
    StateProvider<_ProductSortBy>((ref) => _ProductSortBy.status);

// ── ProductsAdminPage ─────────────────────────────────────────────────────────

/// 農產管理後台頁面（路由：`/admin/products`）。
/// 分為「分類管理」與「農產管理」兩個 Tab。
class ProductsAdminPage extends ConsumerWidget {
  const ProductsAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('農產管理'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.category_outlined),
                text: '分類管理',
              ),
              Tab(
                icon: Icon(Icons.inventory_2_outlined),
                text: '農產管理',
              ),
              Tab(
                icon: Icon(Icons.storefront_outlined),
                text: '架上管理',
              ),
              Tab(
                icon: Icon(Icons.calendar_month_outlined),
                text: '時程總覽',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryTab(),
            _ProductTab(),
            _ShelfTab(),
            _TimelineTab(),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Tab 1：分類管理
// ════════════════════════════════════════════════════════════════════════════════

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(_allCategoriesProvider);

    return Scaffold(
      backgroundColor: _Tokens.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, ref),
        backgroundColor: _Tokens.brandBrown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('新增分類'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            '載入失敗：$err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text(
                '尚無分類，請點擊右下角按鈕新增',
                style: TextStyle(color: _Tokens.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryListTile(
                category: category,
                onEdit: () =>
                    _showCategoryDialog(context, ref, existing: category),
                onDelete: () =>
                    _confirmDeleteCategory(context, ref, category),
                onToggleActive: (value) {
                  ref.read(_repoProvider).updateCategory(
                    category.id,
                    {'isActive': value},
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    AdminCategoryModel? existing,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => _CategoryDialog(
        existing: existing,
        onSave: (data) async {
          final repo = ref.read(_repoProvider);
          if (existing == null) {
            await repo.createCategory(
              CategoryModel(
                id: '',
                name: data['name'] as String,
                slug: data['slug'] as String,
                description: data['description'] as String,
                coverImageUrl: '',
                sortOrder: data['sortOrder'] as int,
              ),
            );
          } else {
            await repo.updateCategory(existing.id, {
              'name': data['name'],
              'slug': data['slug'],
              'description': data['description'],
              'sortOrder': data['sortOrder'],
            });
          }
        },
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    WidgetRef ref,
    AdminCategoryModel category,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('確認刪除'),
        content: Text('確定要刪除分類「${category.name}」嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(_repoProvider).deleteCategory(category.id);
      }
    });
  }
}

// ── 分類列表行 ────────────────────────────────────────────────────────────────

class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final AdminCategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Tokens.cardBg,
        borderRadius: BorderRadius.circular(_Tokens.cardBorderRadius),
        border: Border.all(color: _Tokens.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _Tokens.textPrimary,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _Tokens.brandBrown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '排序 ${category.sortOrder}',
                style: const TextStyle(
                  fontSize: 11,
                  color: _Tokens.brandBrown,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'slug: ${category.slug}',
              style: const TextStyle(
                fontSize: 12,
                color: _Tokens.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: category.isActive,
              activeColor: _Tokens.brandBrown,
              onChanged: onToggleActive,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: _Tokens.brandBrownLight,
              tooltip: '編輯',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red,
              tooltip: '刪除',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 分類 Dialog ───────────────────────────────────────────────────────────────

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({
    this.existing,
    required this.onSave,
  });

  final AdminCategoryModel? existing;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _sortCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _slugCtrl = TextEditingController(text: e?.slug ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _sortCtrl =
        TextEditingController(text: e?.sortOrder.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave({
        'name': _nameCtrl.text.trim(),
        'slug': _slugCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'sortOrder': int.tryParse(_sortCtrl.text) ?? 0,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(isEdit ? '編輯分類' : '新增分類'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogTextField(
                controller: _nameCtrl,
                label: '分類名稱',
                hint: '例如：水蜜桃',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '請輸入名稱' : null,
              ),
              const SizedBox(height: 12),
              _DialogTextField(
                controller: _slugCtrl,
                label: 'Slug（英文代號）',
                hint: '例如：peach',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '請輸入 slug';
                  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim())) {
                    return '只允許小寫英文、數字與連字號';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DialogTextField(
                controller: _descCtrl,
                label: '描述',
                hint: '分類簡介（選填）',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _DialogTextField(
                controller: _sortCtrl,
                label: '排序',
                hint: '數字越小越前面',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          style: FilledButton.styleFrom(
            backgroundColor: _Tokens.brandBrown,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEdit ? '儲存' : '新增'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Tab 2：農產管理
// ════════════════════════════════════════════════════════════════════════════════

class _ProductTab extends ConsumerWidget {
  const _ProductTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(_allCategoriesProvider);
    final productsAsync = ref.watch(_allProductsProvider);
    final selectedCategoryId = ref.watch(_selectedCategoryFilterProvider);
    final sortBy = ref.watch(_productSortByProvider);

    return Scaffold(
      backgroundColor: _Tokens.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showCreateProductDialog(context, ref, categoriesAsync.valueOrNull ?? []),
        backgroundColor: _Tokens.brandBrown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('新增農產'),
      ),
      body: Column(
        children: [
          // 分類篩選列 + 排序按鈕
          _CategoryFilterBar(
            categoriesAsync: categoriesAsync,
            selectedId: selectedCategoryId,
            onSelect: (id) {
              ref
                  .read(_selectedCategoryFilterProvider.notifier)
                  .state = id;
            },
            sortBy: sortBy,
            onSortTap: () => ref
                .read(_productSortByProvider.notifier)
                .state = sortBy.next,
          ),

          // 商品列表
          Expanded(
            child: productsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  '載入失敗：$err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (allProducts) {
                var products = selectedCategoryId == null
                    ? allProducts.toList()
                    : allProducts
                        .where(
                            (p) => p.categoryId == selectedCategoryId)
                        .toList();

                // 排序
                final categoryMap = {
                  for (final c
                      in categoriesAsync.valueOrNull ?? <AdminCategoryModel>[])
                    c.id: c.name,
                };
                const statusOrder = {'active': 0, 'draft': 1, 'archived': 2};
                switch (sortBy) {
                  case _ProductSortBy.status:
                    products.sort((a, b) =>
                        (statusOrder[a.status] ?? 9)
                            .compareTo(statusOrder[b.status] ?? 9));
                  case _ProductSortBy.category:
                    products.sort((a, b) =>
                        (categoryMap[a.categoryId] ?? '')
                            .compareTo(categoryMap[b.categoryId] ?? ''));
                  case _ProductSortBy.updatedAt:
                    products.sort((a, b) =>
                        (b.updatedAt ?? DateTime(2000))
                            .compareTo(a.updatedAt ?? DateTime(2000)));
                }

                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      '此分類下尚無農產',
                      style:
                          TextStyle(color: _Tokens.textSecondary),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final available = constraints.maxWidth - 32; // padding
                    const spacing = 12.0;
                    const maxCols = 4;
                    final cols = ((available + spacing) / (180 + spacing))
                        .floor()
                        .clamp(1, maxCols);
                    final cardWidth =
                        (available - spacing * (cols - 1)) / cols;

                    return SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: products.map((product) {
                      return SizedBox(
                        width: cardWidth,
                        child: _ProductCard(
                          product: product,
                          categoryName:
                              categoryMap[product.categoryId] ?? '—',
                          onEditStatus: () => _showEditStatusDialog(
                            context,
                            ref,
                            product,
                          ),
                          onEditSeasons: () => _showEditSeasonsDialog(
                            context,
                            ref,
                            product,
                          ),
                          onEditContent: () => _showEditContentDialog(
                            context,
                            ref,
                            product,
                          ),
                          onEditVariants: () => _showVariantsDialog(
                            context,
                            ref,
                            product,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateProductDialog(
    BuildContext context,
    WidgetRef ref,
    List<AdminCategoryModel> categories,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _CreateProductDialog(
        categories: categories,
        onSave: (data) async {
          await ref.read(_repoProvider).createProduct(
                ProductModel(
                  id: '',
                  categoryId: data['categoryId'] as String,
                  name: data['name'] as String,
                  description: data['description'] as String,
                  coverImageUrl: data['coverImageUrl'] as String,
                  status: 'draft',
                  sortOrder: data['sortOrder'] as int,
                  isPreorder: false,
                ),
              );
        },
      ),
    );
  }

  void _showEditSeasonsDialog(
    BuildContext context,
    WidgetRef ref,
    AdminProductModel product,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditSeasonsDialog(
        product: product,
        onSave: (gs, ge, hs, he, showOnTimeline) async {
          await ref.read(_repoProvider).updateProductSeasons(
                product.id,
                growingStartPeriod: gs,
                growingEndPeriod: ge,
                harvestStartPeriod: hs,
                harvestEndPeriod: he,
                showOnTimeline: showOnTimeline,
              );
        },
      ),
    );
  }

  void _showVariantsDialog(
    BuildContext context,
    WidgetRef ref,
    AdminProductModel product,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _VariantsDialog(product: product),
    );
  }

  void _showEditContentDialog(
    BuildContext context,
    WidgetRef ref,
    AdminProductModel product,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditContentDialog(
        product: product,
        onSave: (description, story, imageUrls, coverImageUrl) async {
          await ref.read(_repoProvider).updateProductContent(
                product.id,
                description: description,
                story: story,
                imageUrls: imageUrls,
                coverImageUrl: coverImageUrl,
              );
        },
      ),
    );
  }

  void _showEditStatusDialog(
    BuildContext context,
    WidgetRef ref,
    AdminProductModel product,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditStatusDialog(
        product: product,
        onSave: (status, scheduledAt) async {
          await ref.read(_repoProvider).updateProductStatus(
                product.id,
                status,
                scheduledAt: scheduledAt,
              );
        },
      ),
    );
  }
}

// ── 分類篩選列 ────────────────────────────────────────────────────────────────

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categoriesAsync,
    required this.selectedId,
    required this.onSelect,
    required this.sortBy,
    required this.onSortTap,
  });

  final AsyncValue<List<AdminCategoryModel>> categoriesAsync;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final _ProductSortBy sortBy;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    final categories = categoriesAsync.valueOrNull ?? [];

    return Container(
      height: 52,
      color: _Tokens.cardBg,
      child: Row(
        children: [
          // 分類 chips（可水平捲動）
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
              children: [
                _FilterChipItem(
                  label: '全部',
                  isSelected: selectedId == null,
                  onTap: () => onSelect(null),
                ),
                ...categories.map(
                  (c) => _FilterChipItem(
                    label: c.name,
                    isSelected: selectedId == c.id,
                    onTap: () => onSelect(c.id),
                  ),
                ),
              ],
            ),
          ),
          // 排序按鈕靠右
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: onSortTap,
              icon: Icon(sortBy.icon, size: 20),
              tooltip: sortBy.label,
              color: _Tokens.brandBrown,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: _Tokens.brandBrown.withValues(alpha: 0.12),
        checkmarkColor: _Tokens.brandBrown,
        labelStyle: TextStyle(
          color: isSelected ? _Tokens.brandBrown : _Tokens.textSecondary,
          fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        side: BorderSide(
          color: isSelected ? _Tokens.brandBrown : _Tokens.divider,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// ── 商品卡片 ──────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.onEditStatus,
    required this.onEditSeasons,
    required this.onEditContent,
    required this.onEditVariants,
  });

  final AdminProductModel product;
  final String categoryName;
  final VoidCallback onEditStatus;
  final VoidCallback onEditSeasons;
  final VoidCallback onEditContent;
  final VoidCallback onEditVariants;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Tokens.cardBg,
        borderRadius: BorderRadius.circular(_Tokens.cardBorderRadius),
        border: Border.all(color: _Tokens.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 封面圖（1:1）
          AspectRatio(
            aspectRatio: 1,
            child: product.coverImageUrl.isNotEmpty
                ? Image.network(
                    product.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Image.asset(
                          'assets/images/product_placeholder.jpeg',
                          fit: BoxFit.contain,
                        ),
                  )
                : Image.asset(
                    'assets/images/product_placeholder.jpeg',
                    fit: BoxFit.contain,
                  ),
          ),

          // 資訊區
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 農產名稱
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // 標籤列（狀態 + 分類）
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _StatusBadge(status: product.status),
                    _CategoryBadge(name: categoryName),
                  ],
                ),
                const SizedBox(height: 8),
                // 操作按鈕（垂直排列）
                _CardActionButton(
                  icon: Icons.tune,
                  label: '編輯狀態',
                  onPressed: onEditStatus,
                ),
                const SizedBox(height: 4),
                _CardActionButton(
                  icon: Icons.edit_note_outlined,
                  label: '編輯內容',
                  onPressed: onEditContent,
                ),
                const SizedBox(height: 4),
                _CardActionButton(
                  icon: Icons.calendar_month_outlined,
                  label: '農產時程',
                  onPressed: onEditSeasons,
                ),
                const SizedBox(height: 4),
                _CardActionButton(
                  icon: Icons.sell_outlined,
                  label: '販售規格',
                  onPressed: onEditVariants,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _Tokens.brandBrown,
          side: const BorderSide(color: _Tokens.divider),
          textStyle: const TextStyle(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  const _PlaceholderThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: _Tokens.divider,
      child: const Icon(
        Icons.image_outlined,
        size: 28,
        color: _Tokens.textSecondary,
      ),
    );
  }
}

// ── 狀態 Badge ────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = switch (status) {
      'active' => ('上架中', _Tokens.statusActive, _Tokens.statusActiveBg),
      'archived' => ('已下架', _Tokens.statusArchived, _Tokens.statusArchivedBg),
      _ => ('草稿', _Tokens.statusDraft, _Tokens.statusDraftBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _Tokens.brandBrown.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _Tokens.brandBrown,
        ),
      ),
    );
  }
}

// ── 編輯狀態 Dialog ───────────────────────────────────────────────────────────

// ── 編輯內容 Dialog ──────────────────────────────────────────────────────────

class _EditContentDialog extends StatefulWidget {
  const _EditContentDialog({
    required this.product,
    required this.onSave,
  });

  final AdminProductModel product;
  final Future<void> Function(
    String description,
    String story,
    List<String> imageUrls,
    String coverImageUrl,
  ) onSave;

  @override
  State<_EditContentDialog> createState() => _EditContentDialogState();
}

class _EditContentDialogState extends State<_EditContentDialog> {
  late final TextEditingController _descController;
  late final TextEditingController _storyController;
  late List<String> _imageUrls;
  late String _coverImageUrl;
  bool _isSaving = false;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.product.description);
    _storyController = TextEditingController(text: widget.product.story);
    _imageUrls = List<String>.from(widget.product.imageUrls);
    _coverImageUrl = widget.product.coverImageUrl;
  }

  @override
  void dispose() {
    _descController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  int _uploadedCount = 0;
  int _uploadTotal = 0;

  Future<void> _pickAndUpload() async {
    if (_imageUrls.length >= 5) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    // 過濾有效檔案
    final files = result.files.where((f) => f.bytes != null).toList();
    if (files.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadedCount = 0;
      _uploadTotal = files.length;
    });

    final repo = ProductsAdminRepository();
    for (final file in files) {
      try {
        final fileName = '${const Uuid().v4()}_${file.name}';
        final url = await repo.uploadProductImage(
          file.bytes!,
          fileName,
          onProgress: (p) {
            if (mounted) {
              setState(() {
                _uploadProgress =
                    (_uploadedCount + p) / _uploadTotal;
              });
            }
          },
        );
        if (mounted) {
          setState(() {
            _imageUrls.add(url);
            _uploadedCount++;
            if (_coverImageUrl.isEmpty) _coverImageUrl = url;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上傳失敗（${file.name}）：$e')),
          );
        }
      }
    }

    if (mounted) setState(() => _isUploading = false);
  }

  void _removeImage(int index) {
    setState(() {
      final removed = _imageUrls.removeAt(index);
      if (_coverImageUrl == removed) {
        _coverImageUrl = _imageUrls.isNotEmpty ? _imageUrls.first : '';
      }
    });
  }

  void _swapImage(int from, int to) {
    setState(() {
      final item = _imageUrls.removeAt(from);
      _imageUrls.insert(to, item);
    });
  }

  void _setCover(String url) {
    setState(() => _coverImageUrl = url);
  }

  void _previewImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Scaffold(
          backgroundColor: Colors.black87,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(url),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _descController.text.trim(),
        _storyController.text.trim(),
        _imageUrls,
        _coverImageUrl,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('編輯內容 — ${widget.product.name}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 描述
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: '農產描述',
                  hintText: '簡短描述農產特色',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // 故事
              TextFormField(
                controller: _storyController,
                decoration: const InputDecoration(
                  labelText: '品牌故事 / 產品故事',
                  hintText: '產地背景、種植理念、風味描述...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 5,
                maxLines: null,
              ),
              const SizedBox(height: 20),

              // 圖片區標題
              Row(
                children: [
                  Text(
                    '展示圖片',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_imageUrls.length}/5',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '建議比例 1:1（800×800 px）',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 圖片列表
              if (_imageUrls.isNotEmpty)
                ...List.generate(_imageUrls.length, (i) {
                  final url = _imageUrls[i];
                  final isCover = url == _coverImageUrl;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // 縮圖（點擊預覽）
                        GestureDetector(
                          onTap: () => _previewImage(url),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                url,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 64,
                                  height: 64,
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 預覽圖標記
                        if (isCover)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _Tokens.statusActiveBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star,
                                    size: 12, color: _Tokens.statusActive),
                                const SizedBox(width: 2),
                                Text(
                                  '預覽圖',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _Tokens.statusActive,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          TextButton(
                            onPressed: () => _setCover(url),
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 11),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('設為預覽圖'),
                          ),
                        const Spacer(),
                        // 上移
                        IconButton(
                          onPressed:
                              i == 0 ? null : () => _swapImage(i, i - 1),
                          icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                          visualDensity: VisualDensity.compact,
                          tooltip: '上移',
                        ),
                        // 下移
                        IconButton(
                          onPressed: i == _imageUrls.length - 1
                              ? null
                              : () => _swapImage(i, i + 1),
                          icon:
                              const Icon(Icons.keyboard_arrow_down, size: 20),
                          visualDensity: VisualDensity.compact,
                          tooltip: '下移',
                        ),
                        // 刪除
                        IconButton(
                          onPressed: () => _removeImage(i),
                          icon: Icon(Icons.delete_outline,
                              size: 20, color: theme.colorScheme.error),
                          visualDensity: VisualDensity.compact,
                          tooltip: '刪除',
                        ),
                      ],
                    ),
                  );
                }),

              // 上傳進度
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 4),
                      Text(
                        '上傳中 $_uploadedCount/$_uploadTotal（${(_uploadProgress * 100).toInt()}%）',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

              // 超過 5 張警告
              if (_imageUrls.length > 5)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '圖片超過 5 張上限，請刪除多餘圖片後才能儲存',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),

              // 新增圖片按鈕
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickAndUpload,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  '新增圖片（${_imageUrls.length}/5）',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: _isSaving
          ? [
              SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 4),
                    Text('儲存中...', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: _imageUrls.length > 5 ? null : _handleSave,
                child: const Text('儲存'),
              ),
            ],
    );
  }
}

// ── 販售規格管理 Dialog ───────────────────────────────────────────────────────

class _VariantsDialog extends StatefulWidget {
  const _VariantsDialog({required this.product});

  final AdminProductModel product;

  @override
  State<_VariantsDialog> createState() => _VariantsDialogState();
}

class _VariantsDialogState extends State<_VariantsDialog> {
  final _repo = ProductsAdminRepository();
  late final Stream<List<AdminVariantModel>> _stream;

  static const _unitPresets = ['盒', '袋', '兩', '斤', '包', '罐', '粒裝'];

  // 新增表單
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _comparePriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _selectedUnit;
  bool _isPreorder = false;
  bool _isAdding = false;

  // 編輯中的 variant id
  String? _editingId;
  final _editNameCtrl = TextEditingController();
  final _editPriceCtrl = TextEditingController();
  final _editComparePriceCtrl = TextEditingController();
  final _editStockCtrl = TextEditingController();
  final _editUnitCtrl = TextEditingController();
  final _editNoteCtrl = TextEditingController();
  String? _editSelectedUnit;
  bool _editIsPreorder = false;
  bool _isSavingEdit = false;

  @override
  void initState() {
    super.initState();
    _stream = _repo.watchVariants(widget.product.id);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _comparePriceCtrl.dispose();
    _stockCtrl.dispose();
    _unitCtrl.dispose();
    _noteCtrl.dispose();
    _editNameCtrl.dispose();
    _editPriceCtrl.dispose();
    _editComparePriceCtrl.dispose();
    _editStockCtrl.dispose();
    _editUnitCtrl.dispose();
    _editNoteCtrl.dispose();
    super.dispose();
  }

  void _startEdit(AdminVariantModel v) {
    setState(() {
      _editingId = v.id;
      _editNameCtrl.text = v.name;
      _editPriceCtrl.text = v.price.toString();
      _editComparePriceCtrl.text = v.comparePrice?.toString() ?? '';
      _editStockCtrl.text = v.stock.toString();
      _editIsPreorder = v.isPreorder;
      _editNoteCtrl.text = v.note;
      if (_unitPresets.contains(v.unit)) {
        _editSelectedUnit = v.unit;
        _editUnitCtrl.text = '';
      } else {
        _editSelectedUnit = '自填';
        _editUnitCtrl.text = v.unit;
      }
    });
  }

  void _cancelEdit() => setState(() => _editingId = null);

  Future<void> _saveEdit() async {
    final name = _editNameCtrl.text.trim();
    final price = int.tryParse(_editPriceCtrl.text) ?? 0;
    if (name.isEmpty || price <= 0) return;

    setState(() => _isSavingEdit = true);
    try {
      await _repo.updateVariant(
        widget.product.id,
        _editingId!,
        name: name,
        price: price,
        comparePrice: int.tryParse(_editComparePriceCtrl.text),
        stock: int.tryParse(_editStockCtrl.text) ?? 0,
        unit: _editSelectedUnit == '自填'
            ? _editUnitCtrl.text.trim()
            : (_editSelectedUnit ?? ''),
        isPreorder: _editIsPreorder,
        note: _editNoteCtrl.text.trim(),
      );
      setState(() => _editingId = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingEdit = false);
    }
  }

  Future<void> _addVariant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇單位')),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      await _repo.createVariant(
        widget.product.id,
        name: _nameCtrl.text.trim(),
        price: int.parse(_priceCtrl.text),
        comparePrice: int.tryParse(_comparePriceCtrl.text),
        stock: 0,
        unit: _selectedUnit == '自填'
            ? _unitCtrl.text.trim()
            : (_selectedUnit ?? ''),
        isPreorder: _isPreorder,
        note: _noteCtrl.text.trim(),
      );
      _nameCtrl.clear();
      _priceCtrl.clear();
      _comparePriceCtrl.clear();
      _stockCtrl.clear();
      _unitCtrl.clear();
      _noteCtrl.clear();
      setState(() {
        _isPreorder = false;
        _selectedUnit = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('新增失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteVariant(AdminVariantModel v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除規格「${v.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.deleteVariant(widget.product.id, v.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('販售規格 — ${widget.product.name}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 現有規格列表
              StreamBuilder<List<AdminVariantModel>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final variants = snapshot.data ?? [];
                  if (variants.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '尚無販售規格，請在下方新增',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Column(
                    children: variants.map((v) {
                      if (_editingId == v.id) {
                        return _buildEditRow(v);
                      }
                      return _buildVariantRow(v);
                    }).toList(),
                  );
                },
              ),

              const Divider(height: 32),

              // 新增表單
              Text('新增規格', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: '名稱',
                              hintText: '如：4兩、半斤',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? '必填' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: '單位',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              errorText: _selectedUnit == null && _formKey.currentState != null
                                  ? null : null,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedUnit,
                                isExpanded: true,
                                isDense: true,
                                hint: const Text('選擇'),
                                items: [
                                  ..._unitPresets.map((u) =>
                                      DropdownMenuItem(value: u, child: Text(u))),
                                  const DropdownMenuItem(
                                      value: '自填', child: Text('自填...')),
                                ],
                                onChanged: (v) => setState(() => _selectedUnit = v),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedUnit == '自填') ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(
                          labelText: '自訂單位',
                          hintText: '輸入自訂單位',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '必填' : null,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            decoration: const InputDecoration(
                              labelText: '售價',
                              prefixText: 'NT\$ ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return '必填';
                              if ((int.tryParse(v) ?? 0) <= 0) return '須 > 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _comparePriceCtrl,
                            decoration: const InputDecoration(
                              labelText: '原價（選填）',
                              prefixText: 'NT\$ ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        labelText: '備註（選填）',
                        hintText: '如：限量、季節限定',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _isPreorder,
                          onChanged: (v) =>
                              setState(() => _isPreorder = v ?? false),
                        ),
                        const Text('預購', style: TextStyle(fontSize: 13)),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _isAdding ? null : _addVariant,
                          icon: _isAdding
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add, size: 16),
                          label: const Text('新增'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('完成'),
        ),
      ],
    );
  }

  Widget _buildVariantRow(AdminVariantModel v) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _Tokens.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${v.name}（${v.unit}）',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _Tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'NT\$ ${v.price}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _Tokens.brandBrown,
                      ),
                    ),
                    if (v.comparePrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        'NT\$ ${v.comparePrice}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _Tokens.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                if (v.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    v.note,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _Tokens.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // 庫存
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: v.stock > 0
                  ? _Tokens.statusActiveBg
                  : _Tokens.statusArchivedBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              v.stock > 0 ? '庫存 ${v.stock}' : (v.isPreorder ? '預購' : '售完'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: v.stock > 0
                    ? _Tokens.statusActive
                    : (v.isPreorder
                        ? _Tokens.statusDraft
                        : _Tokens.statusArchived),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _startEdit(v),
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: '編輯',
            visualDensity: VisualDensity.compact,
            color: _Tokens.brandBrown,
          ),
          IconButton(
            onPressed: () => _deleteVariant(v),
            icon: Icon(Icons.delete_outline, size: 18,
                color: Theme.of(context).colorScheme.error),
            tooltip: '刪除',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildEditRow(AdminVariantModel v) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: _Tokens.statusDraftBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _editNameCtrl,
                  decoration: const InputDecoration(
                    labelText: '名稱',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '單位',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _editSelectedUnit,
                      isExpanded: true,
                      isDense: true,
                      items: [
                        ..._unitPresets.map((u) =>
                            DropdownMenuItem(value: u, child: Text(u))),
                        const DropdownMenuItem(
                            value: '自填', child: Text('自填...')),
                      ],
                      onChanged: (v) => setState(() => _editSelectedUnit = v),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_editSelectedUnit == '自填') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _editUnitCtrl,
              decoration: const InputDecoration(
                labelText: '自訂單位',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _editPriceCtrl,
                  decoration: const InputDecoration(
                    labelText: '售價',
                    prefixText: 'NT\$ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _editComparePriceCtrl,
                  decoration: const InputDecoration(
                    labelText: '原價',
                    prefixText: 'NT\$ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _editNoteCtrl,
            decoration: const InputDecoration(
              labelText: '備註（選填）',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _editIsPreorder,
                onChanged: (val) =>
                    setState(() => _editIsPreorder = val ?? false),
              ),
              const Text('預購', style: TextStyle(fontSize: 13)),
              const Spacer(),
              TextButton(
                onPressed: _isSavingEdit ? null : _cancelEdit,
                child: const Text('取消'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: _isSavingEdit ? null : _saveEdit,
                child: _isSavingEdit
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('儲存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 編輯狀態 Dialog ───────────────────────────────────────────────────────────

class _EditStatusDialog extends StatefulWidget {
  const _EditStatusDialog({
    required this.product,
    required this.onSave,
  });

  final AdminProductModel product;
  final Future<void> Function(String status, DateTime? scheduledAt) onSave;

  @override
  State<_EditStatusDialog> createState() => _EditStatusDialogState();
}

class _EditStatusDialogState extends State<_EditStatusDialog> {
  late String _selectedStatus;
  DateTime? _scheduledAt;
  bool _isSaving = false;

  static const _statusOptions = [
    ('draft', '草稿'),
    ('active', '上架中'),
    ('archived', '已下架'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.product.status;
    _scheduledAt = widget.product.scheduledAt;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_selectedStatus, _scheduledAt);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('編輯農產狀態'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _Tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // 狀態選擇
            const Text(
              '上架狀態',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _Tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ..._statusOptions.map(
              (option) => RadioListTile<String>(
                title: Text(
                  option.$2,
                  style: const TextStyle(fontSize: 14),
                ),
                value: option.$1,
                groupValue: _selectedStatus,
                activeColor: _Tokens.brandBrown,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // 預約上架時間
            const Text(
              '預約上架時間（選填）',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _Tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(
                      _scheduledAt != null
                          ? DateFormat('yyyy/MM/dd HH:mm')
                              .format(_scheduledAt!)
                          : '選擇日期與時間',
                      style: TextStyle(
                        fontSize: 13,
                        color: _scheduledAt != null
                            ? _Tokens.textPrimary
                            : _Tokens.textSecondary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _Tokens.divider),
                      foregroundColor: _Tokens.brandBrown,
                    ),
                  ),
                ),
                if (_scheduledAt != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    color: _Tokens.textSecondary,
                    tooltip: '清除時間',
                    onPressed: () =>
                        setState(() => _scheduledAt = null),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          style: FilledButton.styleFrom(
            backgroundColor: _Tokens.brandBrown,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('儲存'),
        ),
      ],
    );
  }
}

// ── 新增農產 Dialog ───────────────────────────────────────────────────────────

class _CreateProductDialog extends StatefulWidget {
  const _CreateProductDialog({
    required this.categories,
    required this.onSave,
  });

  final List<AdminCategoryModel> categories;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<_CreateProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _coverUrlCtrl;
  late final TextEditingController _sortCtrl;
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _coverUrlCtrl = TextEditingController();
    _sortCtrl = TextEditingController(text: '0');
    if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _coverUrlCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇分類')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave({
        'categoryId': _selectedCategoryId!,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'coverImageUrl': _coverUrlCtrl.text.trim(),
        'sortOrder': int.tryParse(_sortCtrl.text) ?? 0,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('新增失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('新增農產'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 分類選擇
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: '農產分類',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: widget.categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                  validator: (v) => v == null ? '請選擇分類' : null,
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: _nameCtrl,
                  label: '農產名稱',
                  hint: '例如：玉荷包荔枝禮盒',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '請輸入名稱' : null,
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: _descCtrl,
                  label: '農產描述',
                  hint: '農產簡介（選填）',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: _coverUrlCtrl,
                  label: '封面圖片 URL',
                  hint: 'https://...',
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: _sortCtrl,
                  label: '排序',
                  hint: '數字越小越前面',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          style: FilledButton.styleFrom(
            backgroundColor: _Tokens.brandBrown,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('新增'),
        ),
      ],
    );
  }
}

// ── 編輯農產時程 Dialog ───────────────────────────────────────────────────────

class _EditSeasonsDialog extends StatefulWidget {
  const _EditSeasonsDialog({required this.product, required this.onSave});

  final AdminProductModel product;
  final Future<void> Function(int gs, int ge, int hs, int he, bool showOnTimeline) onSave;

  @override
  State<_EditSeasonsDialog> createState() => _EditSeasonsDialogState();
}

class _EditSeasonsDialogState extends State<_EditSeasonsDialog> {
  late int _gs;
  late int _ge;
  late int _hs;
  late int _he;
  late bool _showOnTimeline;
  bool _isSaving = false;

  static final _periods = [
    (0, '未設定'),
    ...List.generate(36, (i) {
      final period = i + 1;
      return (period, PeriodHelper.label(period));
    }),
  ];

  @override
  void initState() {
    super.initState();
    _gs = widget.product.growingStartPeriod ?? 0;
    _ge = widget.product.growingEndPeriod ?? 0;
    _hs = widget.product.harvestStartPeriod ?? 0;
    _he = widget.product.harvestEndPeriod ?? 0;
    _showOnTimeline = widget.product.showOnTimeline;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_gs, _ge, _hs, _he, _showOnTimeline);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _periodDropdown(int value, ValueChanged<int?> onChanged) {
    return DropdownButton<int>(
      value: value,
      isExpanded: true,
      items: _periods
          .map((p) => DropdownMenuItem(value: p.$1, child: Text(p.$2)))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('農產時程設定'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _Tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // 生長期
            Row(children: [
              Container(width: 10, height: 10,
                decoration: const BoxDecoration(color: Color(0xFF81C784), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('生長期', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('起始月', style: TextStyle(fontSize: 11, color: _Tokens.textSecondary)),
                  _periodDropdown(_gs, (v) => setState(() => _gs = v ?? 0)),
                ],
              )),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('至', style: TextStyle(color: _Tokens.textSecondary)),
              ),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('結束月', style: TextStyle(fontSize: 11, color: _Tokens.textSecondary)),
                  _periodDropdown(_ge, (v) => setState(() => _ge = v ?? 0)),
                ],
              )),
            ]),

            const SizedBox(height: 20),

            // 採收期
            Row(children: [
              Container(width: 10, height: 10,
                decoration: const BoxDecoration(color: Color(0xFFFF7043), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('採收期', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('起始月', style: TextStyle(fontSize: 11, color: _Tokens.textSecondary)),
                  _periodDropdown(_hs, (v) => setState(() => _hs = v ?? 0)),
                ],
              )),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('至', style: TextStyle(color: _Tokens.textSecondary)),
              ),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('結束月', style: TextStyle(fontSize: 11, color: _Tokens.textSecondary)),
                  _periodDropdown(_he, (v) => setState(() => _he = v ?? 0)),
                ],
              )),
            ]),

            const SizedBox(height: 16),

            // 顯示於時程表
            CheckboxListTile(
              value: _showOnTimeline,
              onChanged: (v) => setState(() => _showOnTimeline = v ?? true),
              title: const Text('顯示於首頁農產時程', style: TextStyle(fontSize: 13)),
              subtitle: const Text(
                '既成農產（如茶庫存）可關閉此選項',
                style: TextStyle(fontSize: 11),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 8),
            const Text(
              '跨年設定範例：採收期 11月 至 2月（會自動跨年計算）',
              style: TextStyle(fontSize: 11, color: _Tokens.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          style: FilledButton.styleFrom(backgroundColor: _Tokens.brandBrown),
          child: _isSaving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('儲存'),
        ),
      ],
    );
  }
}

// ── 通用 Dialog TextFormField ─────────────────────────────────────────────────

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Tab 3：時程總覽
// ════════════════════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════════════════════
// Tab 3：架上管理
// ════════════════════════════════════════════════════════════════════════════════

class _ShelfTab extends ConsumerWidget {
  const _ShelfTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(_allProductsProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('載入失敗：$err')),
      data: (allProducts) {
        final products =
            allProducts.where((p) => p.status == 'active').toList();
        if (products.isEmpty) {
          return const Center(
            child: Text('目前沒有上架中的農產',
                style: TextStyle(color: _Tokens.textSecondary)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) =>
              _ShelfProductCard(product: products[index]),
        );
      },
    );
  }
}

class _ShelfProductCard extends StatefulWidget {
  const _ShelfProductCard({required this.product});

  final AdminProductModel product;

  @override
  State<_ShelfProductCard> createState() => _ShelfProductCardState();
}

class _ShelfProductCardState extends State<_ShelfProductCard> {
  final _repo = ProductsAdminRepository();
  bool _isEditing = false;
  bool _isSaving = false;

  // 編輯中的本地副本：variantId → stock
  Map<String, int> _localStocks = {};
  // 編輯中的本地排序副本
  List<AdminVariantModel>? _localVariants;

  void _enterEdit(List<AdminVariantModel> variants) {
    setState(() {
      _isEditing = true;
      _localStocks = {for (final v in variants) v.id: v.stock};
      _localVariants = List.of(variants);
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _localStocks = {};
      _localVariants = null;
    });
  }

  void _adjustStock(String id, int delta) {
    setState(() {
      final current = _localStocks[id] ?? 0;
      final next = (current + delta).clamp(0, 999999);
      _localStocks[id] = next;
    });
  }

  void _swapLocal(int from, int to) {
    if (_localVariants == null) return;
    setState(() {
      final item = _localVariants!.removeAt(from);
      _localVariants!.insert(to, item);
    });
  }

  Future<void> _saveAll() async {
    if (_localVariants == null) return;
    setState(() => _isSaving = true);
    try {
      final futures = <Future>[];
      for (int i = 0; i < _localVariants!.length; i++) {
        final v = _localVariants![i];
        final newStock = _localStocks[v.id] ?? v.stock;
        futures.add(_repo.updateVariant(
          widget.product.id, v.id,
          name: v.name, price: v.price, comparePrice: v.comparePrice,
          stock: newStock, unit: v.unit, isPreorder: v.isPreorder,
          note: v.note, sortOrder: i,
        ));
      }
      await Future.wait(futures);
      if (mounted) setState(() {
        _isEditing = false;
        _localStocks = {};
        _localVariants = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteVariant(AdminVariantModel v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除規格「${v.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.deleteVariant(widget.product.id, v.id);
      // 同步移除本地副本
      setState(() {
        _localVariants?.removeWhere((lv) => lv.id == v.id);
        _localStocks.remove(v.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 標題列
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isEditing ? _Tokens.statusDraftBg : _Tokens.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                if (widget.product.coverImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      widget.product.coverImageUrl,
                      width: 40, height: 40, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  )
                else
                  const Icon(Icons.eco, size: 28, color: _Tokens.brandBrownLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _Tokens.textPrimary,
                    ),
                  ),
                ),
                if (_isEditing)
                  Text('編輯中',
                      style: TextStyle(
                        fontSize: 12,
                        color: _Tokens.statusDraft,
                        fontWeight: FontWeight.w600,
                      )),
              ],
            ),
          ),

          // 規格列表
          StreamBuilder<List<AdminVariantModel>>(
            stream: _repo.watchVariants(widget.product.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: LinearProgressIndicator()),
                );
              }
              final dbVariants = snapshot.data ?? [];
              if (dbVariants.isEmpty && !_isEditing) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('尚無販售規格',
                      style: TextStyle(color: _Tokens.textSecondary),
                      textAlign: TextAlign.center),
                );
              }

              // 編輯中用本地副本，否則用 DB
              final variants = _isEditing
                  ? (_localVariants ?? dbVariants)
                  : dbVariants;

              return Column(
                children: [
                  ...List.generate(variants.length, (i) {
                    final v = variants[i];
                    final stock = _isEditing
                        ? (_localStocks[v.id] ?? v.stock)
                        : v.stock;
                    return _ShelfVariantRow(
                      variant: v,
                      displayStock: stock,
                      isEditing: _isEditing,
                      isFirst: i == 0,
                      isLast: i == variants.length - 1,
                      onMoveUp: () => _swapLocal(i, i - 1),
                      onMoveDown: () => _swapLocal(i, i + 1),
                      onIncrement: () => _adjustStock(v.id, 1),
                      onDecrement: () => _adjustStock(v.id, -1),
                      onDelete: () => _deleteVariant(v),
                    );
                  }),

                  // 底部操作列
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: _isEditing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _isSaving ? null : _cancelEdit,
                                child: const Text('取消'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _isSaving ? null : _saveAll,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 14, height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.save_outlined, size: 16),
                                label: const Text('儲存全部'),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () => _enterEdit(dbVariants),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('編輯'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _Tokens.brandBrown,
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── 架上規格列（唯讀 / 編輯共用） ────────────────────────────────────────────

class _ShelfVariantRow extends StatelessWidget {
  const _ShelfVariantRow({
    required this.variant,
    required this.displayStock,
    required this.isEditing,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
  });

  final AdminVariantModel variant;
  final int displayStock;
  final bool isEditing;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final v = variant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _Tokens.divider)),
      ),
      child: Row(
        children: [
          // 排序（僅編輯模式）
          if (isEditing) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: isFirst ? null : onMoveUp,
                  icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                IconButton(
                  onPressed: isLast ? null : onMoveDown,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],

          // 規格資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${v.name}（${v.unit}）',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _Tokens.textPrimary,
                  ),
                ),
                Text(
                  'NT\$ ${v.price}',
                  style: const TextStyle(
                    fontSize: 13, color: _Tokens.brandBrown),
                ),
                if (v.note.isNotEmpty)
                  Text(v.note,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _Tokens.textSecondary,
                        fontStyle: FontStyle.italic,
                      )),
              ],
            ),
          ),

          // 庫存
          if (isEditing) ...[
            IconButton(
              onPressed: displayStock <= 0 ? null : onDecrement,
              icon: const Icon(Icons.remove_circle_outline, size: 22),
              color: Theme.of(context).colorScheme.error,
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$displayStock',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _Tokens.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline, size: 22),
              color: _Tokens.statusActive,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Theme.of(context).colorScheme.error),
              visualDensity: VisualDensity.compact,
            ),
          ] else ...[
            // 唯讀：庫存 badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: displayStock > 0
                    ? _Tokens.statusActiveBg
                    : (v.isPreorder
                        ? _Tokens.statusDraftBg
                        : _Tokens.statusArchivedBg),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                displayStock > 0
                    ? '庫存 $displayStock'
                    : (v.isPreorder ? '預購中' : '售完'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: displayStock > 0
                      ? _Tokens.statusActive
                      : (v.isPreorder
                          ? _Tokens.statusDraft
                          : _Tokens.statusArchived),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Tab 4：時程總覽
// ════════════════════════════════════════════════════════════════════════════════

class _TimelineTab extends StatelessWidget {
  const _TimelineTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: ProductTimeline(),
        ),
      ),
    );
  }
}
