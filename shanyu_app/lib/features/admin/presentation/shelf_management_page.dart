import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/products_admin_repository.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final _repoProvider = Provider((_) => ProductsAdminRepository());

final _activeProductsProvider =
    StreamProvider<List<AdminProductModel>>((ref) {
  return ref.watch(_repoProvider).watchAllProducts().map(
        (list) => list.where((p) => p.status == 'active').toList(),
      );
});

// ── ShelfManagementPage ──────────────────────────────────────────────────────

/// 架上管理頁面（路由：`/admin/shelf`）。
/// 列出所有上架中農產及其販售規格，可即時調整庫存或刪除規格。
class ShelfManagementPage extends ConsumerWidget {
  const ShelfManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(_activeProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('架上管理')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('載入失敗：$err')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text('目前沒有上架中的農產',
                  style: TextStyle(color: Color(0xFF9E9E9E))),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) =>
                _ProductShelfCard(product: products[index]),
          );
        },
      ),
    );
  }
}

// ── 農產架上卡片 ─────────────────────────────────────────────────────────────

class _ProductShelfCard extends ConsumerWidget {
  const _ProductShelfCard({required this.product});

  final AdminProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(_repoProvider);
    final variantsStream = repo.watchVariants(product.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 農產名稱標題
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F0EB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // 縮圖
                if (product.coverImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      product.coverImageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  )
                else
                  const Icon(Icons.eco, size: 28, color: Color(0xFF8D6E63)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D2118),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 規格列表
          StreamBuilder<List<AdminVariantModel>>(
            stream: variantsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final variants = snapshot.data ?? [];
              if (variants.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '尚無販售規格',
                    style: TextStyle(color: Color(0xFF9E9E9E)),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return Column(
                children: variants
                    .map((v) => _VariantShelfRow(
                          productId: product.id,
                          variant: v,
                          repo: repo,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── 規格列 ──────────────────────────────────────────────────────────────────

class _VariantShelfRow extends StatefulWidget {
  const _VariantShelfRow({
    required this.productId,
    required this.variant,
    required this.repo,
  });

  final String productId;
  final AdminVariantModel variant;
  final ProductsAdminRepository repo;

  @override
  State<_VariantShelfRow> createState() => _VariantShelfRowState();
}

class _VariantShelfRowState extends State<_VariantShelfRow> {
  late final TextEditingController _stockCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _stockCtrl = TextEditingController(text: widget.variant.stock.toString());
  }

  @override
  void didUpdateWidget(covariant _VariantShelfRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variant.stock != widget.variant.stock && !_isSaving) {
      _stockCtrl.text = widget.variant.stock.toString();
    }
  }

  @override
  void dispose() {
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStock(int newStock) async {
    if (newStock < 0) return;
    setState(() => _isSaving = true);
    try {
      await widget.repo.updateVariant(
        widget.productId,
        widget.variant.id,
        name: widget.variant.name,
        price: widget.variant.price,
        comparePrice: widget.variant.comparePrice,
        stock: newStock,
        unit: widget.variant.unit,
        isPreorder: widget.variant.isPreorder,
        note: widget.variant.note,
      );
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

  Future<void> _deleteVariant() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除規格「${widget.variant.name}」嗎？\n此操作無法復原。'),
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
      await widget.repo.deleteVariant(widget.productId, widget.variant.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.variant;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEFEBE9)),
        ),
      ),
      child: Row(
        children: [
          // 規格資訊
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
                    color: Color(0xFF2D2118),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NT\$ ${v.price}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5C4033),
                  ),
                ),
                if (v.note.isNotEmpty)
                  Text(
                    v.note,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // 庫存調整
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 減少
              IconButton(
                onPressed: _isSaving || v.stock <= 0
                    ? null
                    : () => _updateStock(v.stock - 1),
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 22,
                color: theme.colorScheme.error,
                visualDensity: VisualDensity.compact,
                tooltip: '庫存 -1',
              ),
              // 數量輸入
              SizedBox(
                width: 56,
                child: TextField(
                  controller: _stockCtrl,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (val) {
                    final n = int.tryParse(val);
                    if (n != null && n >= 0) _updateStock(n);
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 增加
              IconButton(
                onPressed: _isSaving
                    ? null
                    : () => _updateStock(v.stock + 1),
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 22,
                color: const Color(0xFF2E7D32),
                visualDensity: VisualDensity.compact,
                tooltip: '庫存 +1',
              ),
            ],
          ),

          const SizedBox(width: 4),

          // 狀態 badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: v.stock > 0
                  ? const Color(0xFFE8F5E9)
                  : (v.isPreorder
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFF5F5F5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              v.stock > 0
                  ? '有庫存'
                  : (v.isPreorder ? '預購中' : '售完'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: v.stock > 0
                    ? const Color(0xFF2E7D32)
                    : (v.isPreorder
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF616161)),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // 刪除
          IconButton(
            onPressed: _deleteVariant,
            icon: Icon(Icons.delete_outline,
                size: 20, color: theme.colorScheme.error),
            tooltip: '刪除規格',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
