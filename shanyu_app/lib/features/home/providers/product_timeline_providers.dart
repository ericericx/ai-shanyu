// lib/features/home/providers/product_timeline_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/product_timeline_repository.dart';
import '../models/product_timeline_models.dart';

part 'product_timeline_providers.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

/// ProductTimelineRepository 單例。
@Riverpod(keepAlive: true)
ProductTimelineRepository productTimelineRepository(Ref ref) {
  return ProductTimelineRepository();
}

// ── Stream Provider ───────────────────────────────────────────────────────────

/// 監聽所有 active 商品的 Stream，供 ProductTimeline 元件消費。
@riverpod
Stream<List<TimelineProduct>> productTimeline(Ref ref) {
  return ref.watch(productTimelineRepositoryProvider).watchActiveProducts();
}
