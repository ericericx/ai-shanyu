import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/cms_repository.dart';
import '../models/cms_models.dart';

part 'cms_providers.g.dart';

// ── CmsRepository Provider ────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
CmsRepository cmsRepository(Ref ref) => CmsRepository();

// ── CmsHomepage StreamProvider ────────────────────────────────────────────────

/// 監聽 Firestore `cms/homepage`，提供首頁 CMS 資料的即時串流。
///
/// - `AsyncData(CmsHomepage)` → 已取得資料
/// - `AsyncData(null)`        → 文件不存在
/// - `AsyncLoading()`         → 初始化中
/// - `AsyncError()`           → 讀取失敗
@riverpod
Stream<CmsHomepage?> cmsHomepage(Ref ref) {
  return ref.watch(cmsRepositoryProvider).watchHomepage();
}
