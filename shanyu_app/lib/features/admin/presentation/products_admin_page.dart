// lib/features/admin/presentation/products_admin_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

// ── ProductsAdminPage ─────────────────────────────────────────────────────────

/// 商品管理後台頁面（路由：`/admin/products`）。
/// 分為「分類管理」與「商品管理」兩個 Tab。
class ProductsAdminPage extends ConsumerWidget {
  const ProductsAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('商品管理'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.category_outlined),
                text: '分類管理',
              ),
              Tab(
                icon: Icon(Icons.inventory_2_outlined),
                text: '商品管理',
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
// Tab 2：商品管理
// ════════════════════════════════════════════════════════════════════════════════

class _ProductTab extends ConsumerWidget {
  const _ProductTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(_allCategoriesProvider);
    final productsAsync = ref.watch(_allProductsProvider);
    final selectedCategoryId = ref.watch(_selectedCategoryFilterProvider);

    return Scaffold(
      backgroundColor: _Tokens.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showCreateProductDialog(context, ref, categoriesAsync.valueOrNull ?? []),
        backgroundColor: _Tokens.brandBrown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('新增商品'),
      ),
      body: Column(
        children: [
          // 分類篩選列
          _CategoryFilterBar(
            categoriesAsync: categoriesAsync,
            selectedId: selectedCategoryId,
            onSelect: (id) {
              ref
                  .read(_selectedCategoryFilterProvider.notifier)
                  .state = id;
            },
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
                final products = selectedCategoryId == null
                    ? allProducts
                    : allProducts
                        .where(
                            (p) => p.categoryId == selectedCategoryId)
                        .toList();

                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      '此分類下尚無商品',
                      style:
                          TextStyle(color: _Tokens.textSecondary),
                    ),
                  );
                }

                final categoryMap = {
                  for (final c
                      in categoriesAsync.valueOrNull ?? <AdminCategoryModel>[])
                    c.id: c.name,
                };

                return ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: products.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductCard(
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
        onSave: (gs, ge, hs, he) async {
          await ref.read(_repoProvider).updateProductSeasons(
                product.id,
                growingStartPeriod: gs,
                growingEndPeriod: ge,
                harvestStartPeriod: hs,
                harvestEndPeriod: he,
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
  });

  final AsyncValue<List<AdminCategoryModel>> categoriesAsync;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final categories = categoriesAsync.valueOrNull ?? [];

    return Container(
      height: 52,
      color: _Tokens.cardBg,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
  });

  final AdminProductModel product;
  final String categoryName;
  final VoidCallback onEditStatus;
  final VoidCallback onEditSeasons;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Tokens.cardBg,
        borderRadius: BorderRadius.circular(_Tokens.cardBorderRadius),
        border: Border.all(color: _Tokens.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面縮圖
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: product.coverImageUrl.isNotEmpty
                  ? Image.network(
                      product.coverImageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _PlaceholderThumb(),
                    )
                  : const _PlaceholderThumb(),
            ),
            const SizedBox(width: 12),

            // 商品資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _Tokens.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: product.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '分類：$categoryName',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _Tokens.textSecondary,
                    ),
                  ),
                  if (product.scheduledAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 12,
                          color: _Tokens.brandBrownLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '預約上架：${DateFormat('yyyy/MM/dd HH:mm').format(product.scheduledAt!)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _Tokens.brandBrownLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 操作按鈕
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEditStatus,
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('編輯狀態'),
                  style: TextButton.styleFrom(
                    foregroundColor: _Tokens.brandBrown,
                    textStyle: const TextStyle(fontSize: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEditSeasons,
                  icon: const Icon(Icons.calendar_month_outlined, size: 16),
                  label: const Text('農產時程'),
                  style: TextButton.styleFrom(
                    foregroundColor: _Tokens.brandBrown,
                    textStyle: const TextStyle(fontSize: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      title: Text('編輯商品狀態'),
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

// ── 新增商品 Dialog ───────────────────────────────────────────────────────────

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
      title: const Text('新增商品'),
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
                    labelText: '商品分類',
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
                  label: '商品名稱',
                  hint: '例如：玉荷包荔枝禮盒',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '請輸入名稱' : null,
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: _descCtrl,
                  label: '商品描述',
                  hint: '商品簡介（選填）',
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
  final Future<void> Function(int gs, int ge, int hs, int he) onSave;

  @override
  State<_EditSeasonsDialog> createState() => _EditSeasonsDialogState();
}

class _EditSeasonsDialogState extends State<_EditSeasonsDialog> {
  late int _gs;
  late int _ge;
  late int _hs;
  late int _he;
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
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_gs, _ge, _hs, _he);
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
