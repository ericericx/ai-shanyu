// lib/features/admin/providers/crm_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/crm_repository.dart';
import '../models/crm_models.dart';

part 'crm_providers.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
CrmRepository crmRepository(Ref ref) => CrmRepository();

// ── 瀏覽記錄分頁狀態 ──────────────────────────────────────────────────────────

/// 分頁篩選條件。
class CrmFilter {
  const CrmFilter({
    this.productId,
    this.startDate,
    this.endDate,
  });

  final String? productId;
  final DateTime? startDate;
  final DateTime? endDate;

  CrmFilter copyWith({
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    bool clearProductId = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return CrmFilter(
      productId: clearProductId ? null : (productId ?? this.productId),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}

/// 分頁瀏覽記錄狀態。
class CrmViewsState {
  const CrmViewsState({
    this.records = const [],
    this.docs = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.filter = const CrmFilter(),
    this.errorMessage,
  });

  final List<ProductViewRecord> records;
  final List<DocumentSnapshot> docs;
  final bool isLoading;
  final bool hasMore;
  final CrmFilter filter;
  final String? errorMessage;

  CrmViewsState copyWith({
    List<ProductViewRecord>? records,
    List<DocumentSnapshot>? docs,
    bool? isLoading,
    bool? hasMore,
    CrmFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CrmViewsState(
      records: records ?? this.records,
      docs: docs ?? this.docs,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 瀏覽記錄分頁 Notifier。
@riverpod
class CrmViewsNotifier extends _$CrmViewsNotifier {
  static const _pageSize = 20;

  @override
  CrmViewsState build() {
    return const CrmViewsState();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      records: [],
      docs: [],
      hasMore: true,
      clearError: true,
    );

    try {
      final docs = await ref.read(crmRepositoryProvider).getProductViewDocs(
            productId: state.filter.productId,
            startDate: state.filter.startDate,
            endDate: state.filter.endDate,
            limit: _pageSize,
          );

      final records = docs
          .map((d) => ProductViewRecord.fromFirestore(d))
          .toList();

      state = state.copyWith(
        records: records,
        docs: docs,
        isLoading: false,
        hasMore: docs.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '載入失敗：$e',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final lastDoc = state.docs.isNotEmpty ? state.docs.last : null;

    try {
      final newDocs = await ref.read(crmRepositoryProvider).getProductViewDocs(
            productId: state.filter.productId,
            startDate: state.filter.startDate,
            endDate: state.filter.endDate,
            limit: _pageSize,
            lastDoc: lastDoc,
          );

      final newRecords = newDocs
          .map((d) => ProductViewRecord.fromFirestore(d))
          .toList();

      state = state.copyWith(
        records: [...state.records, ...newRecords],
        docs: [...state.docs, ...newDocs],
        isLoading: false,
        hasMore: newDocs.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '載入更多失敗：$e',
      );
    }
  }

  Future<void> applyFilter(CrmFilter filter) async {
    state = state.copyWith(filter: filter);
    await loadInitial();
  }
}

// ── 熱門商品 Provider ─────────────────────────────────────────────────────────

@riverpod
Future<List<PopularProduct>> topProducts(Ref ref, {int limit = 5}) {
  return ref.watch(crmRepositoryProvider).getTopProducts(limit: limit);
}
