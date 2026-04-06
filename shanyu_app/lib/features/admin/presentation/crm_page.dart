// lib/features/admin/presentation/crm_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/crm_models.dart';
import '../providers/crm_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _CrmTokens {
  static const surface = Color(0xFFFAF8F5);
  static const brandBrown = Color(0xFFB82020);
  static const brandBrownLight = Color(0xFF9C1B1B);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const divider = Color(0xFFEFEBE9);
  static const cardBg = Colors.white;
  static const rankGold = Color(0xFFFFB300);
  static const rankSilver = Color(0xFF9E9E9E);
  static const rankBronze = Color(0xFF8D6E63);

  static const cardBorderRadius = 12.0;
  static const sectionPadding = EdgeInsets.all(16.0);
}

// ── CrmPage ───────────────────────────────────────────────────────────────────

/// 後台 CRM — 商品瀏覽記錄查詢頁面（路由 `/admin/crm`）。
class CrmPage extends ConsumerStatefulWidget {
  const CrmPage({super.key});

  @override
  ConsumerState<CrmPage> createState() => _CrmPageState();
}

class _CrmPageState extends ConsumerState<CrmPage> {
  final _productIdController = TextEditingController();
  final _scrollController = ScrollController();

  DateTime? _startDate;
  DateTime? _endDate;

  static final _dateInputFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    // 初始載入
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(crmViewsNotifierProvider.notifier).loadInitial();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(crmViewsNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2024),
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: _CrmTokens.brandBrown,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _applySearch() {
    final filter = CrmFilter(
      productId: _productIdController.text.trim().isEmpty
          ? null
          : _productIdController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
    );
    ref.read(crmViewsNotifierProvider.notifier).applyFilter(filter);
  }

  void _clearSearch() {
    _productIdController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    ref
        .read(crmViewsNotifierProvider.notifier)
        .applyFilter(const CrmFilter());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CrmTokens.surface,
      appBar: AppBar(
        title: const Text(
          '商品瀏覽記錄',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _CrmTokens.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _CrmTokens.brandBrown),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: _CrmTokens.divider,
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 篩選列
          SliverToBoxAdapter(
            child: _SearchBar(
              productIdController: _productIdController,
              startDate: _startDate,
              endDate: _endDate,
              onPickStartDate: () => _pickDate(isStart: true),
              onPickEndDate: () => _pickDate(isStart: false),
              onApply: _applySearch,
              onClear: _clearSearch,
              dateFormat: _dateInputFormat,
            ),
          ),

          // 熱門商品排行
          const SliverToBoxAdapter(
            child: _TopProductsSection(),
          ),

          // 瀏覽記錄列表標頭
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: const Text(
                '瀏覽記錄',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _CrmTokens.textPrimary,
                ),
              ),
            ),
          ),

          // 記錄列表
          const _ViewRecordsList(),
        ],
      ),
    );
  }
}

// ── 篩選搜尋列 ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.productIdController,
    required this.startDate,
    required this.endDate,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onApply,
    required this.onClear,
    required this.dateFormat,
  });

  final TextEditingController productIdController;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品 ID 搜尋
          TextField(
            controller: productIdController,
            style: const TextStyle(
              fontSize: 14,
              color: _CrmTokens.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '按商品 ID 搜尋…',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: _CrmTokens.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: _CrmTokens.brandBrownLight,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: _CrmTokens.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _CrmTokens.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _CrmTokens.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: _CrmTokens.brandBrown,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 日期範圍
          Row(
            children: [
              Expanded(
                child: _DatePickerChip(
                  label: startDate != null
                      ? dateFormat.format(startDate!)
                      : '開始日期',
                  onTap: onPickStartDate,
                  hasValue: startDate != null,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '至',
                  style: TextStyle(
                    fontSize: 13,
                    color: _CrmTokens.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: _DatePickerChip(
                  label: endDate != null
                      ? dateFormat.format(endDate!)
                      : '結束日期',
                  onTap: onPickEndDate,
                  hasValue: endDate != null,
                ),
              ),
              const SizedBox(width: 10),
              // 查詢按鈕
              FilledButton(
                onPressed: onApply,
                style: FilledButton.styleFrom(
                  backgroundColor: _CrmTokens.brandBrown,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '查詢',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // 清除按鈕
              OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: _CrmTokens.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '清除',
                  style: TextStyle(
                    fontSize: 13,
                    color: _CrmTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatePickerChip extends StatelessWidget {
  const _DatePickerChip({
    required this.label,
    required this.onTap,
    required this.hasValue,
  });

  final String label;
  final VoidCallback onTap;
  final bool hasValue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue
              ? _CrmTokens.brandBrown.withValues(alpha: 0.06)
              : _CrmTokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasValue ? _CrmTokens.brandBrown : _CrmTokens.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: hasValue
                  ? _CrmTokens.brandBrown
                  : _CrmTokens.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: hasValue
                      ? _CrmTokens.brandBrown
                      : _CrmTokens.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 熱門商品排行 ──────────────────────────────────────────────────────────────

class _TopProductsSection extends ConsumerWidget {
  const _TopProductsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(topProductsProvider());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '熱門商品排行（前 5 名）',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _CrmTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          topAsync.when(
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '載入排行失敗：$e',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                ),
              ),
            ),
            data: (products) {
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '目前尚無瀏覽記錄',
                    style: TextStyle(
                      fontSize: 13,
                      color: _CrmTokens.textSecondary,
                    ),
                  ),
                );
              }

              return Column(
                children: products.asMap().entries.map((entry) {
                  return _TopProductCard(
                    rank: entry.key + 1,
                    product: entry.value,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopProductCard extends StatelessWidget {
  const _TopProductCard({
    required this.rank,
    required this.product,
  });

  final int rank;
  final PopularProduct product;

  Color get _rankColor {
    switch (rank) {
      case 1:
        return _CrmTokens.rankGold;
      case 2:
        return _CrmTokens.rankSilver;
      case 3:
        return _CrmTokens.rankBronze;
      default:
        return _CrmTokens.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = product.productName?.isNotEmpty == true
        ? product.productName!
        : product.productId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _CrmTokens.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _CrmTokens.divider),
      ),
      child: Row(
        children: [
          // 名次
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _rankColor,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 商品名稱
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _CrmTokens.textPrimary,
                  ),
                ),
                Text(
                  'ID: ${product.productId}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _CrmTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 瀏覽次數
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _CrmTokens.brandBrown.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${product.viewCount} 次',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _CrmTokens.brandBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 瀏覽記錄列表 ──────────────────────────────────────────────────────────────

class _ViewRecordsList extends ConsumerWidget {
  const _ViewRecordsList();

  static final _dtFormat = DateFormat('MM/dd HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crmViewsNotifierProvider);

    if (state.records.isEmpty && state.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.records.isEmpty && state.errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            state.errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
      );
    }

    if (state.records.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            '沒有符合條件的記錄',
            style: TextStyle(
              fontSize: 14,
              color: _CrmTokens.textSecondary,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == state.records.length) {
            // 底部 loading / no-more 指示器
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        state.hasMore ? '' : '已顯示全部記錄',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _CrmTokens.textSecondary,
                        ),
                      ),
              ),
            );
          }

          final record = state.records[index];
          final isEven = index % 2 == 0;
          final displayName = record.productName?.isNotEmpty == true
              ? record.productName!
              : record.productId;
          final userId = record.userId ?? '—';
          final shortUserId = userId.length > 12
              ? '${userId.substring(0, 6)}…${userId.substring(userId.length - 6)}'
              : userId;

          return Container(
            color: isEven
                ? Colors.white
                : _CrmTokens.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                // 商品名稱 / ID
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _CrmTokens.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        record.productId,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _CrmTokens.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 使用者 ID（截斷）
                Expanded(
                  flex: 2,
                  child: Text(
                    shortUserId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _CrmTokens.textSecondary,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 瀏覽時間
                Text(
                  _dtFormat.format(record.viewedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _CrmTokens.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
        childCount: state.records.length + 1,
      ),
    );
  }
}
