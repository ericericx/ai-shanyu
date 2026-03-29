import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cms_models.dart';

// ── CmsRepository ─────────────────────────────────────────────────────────────

/// 首頁 CMS 資料存取層。
///
/// 透過 Firestore `cms/homepage` 文件提供即時更新的 Stream。
class CmsRepository {
  CmsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _kCmsCollection = 'cms';
  static const _kHomepageDoc = 'homepage';

  /// 監聽首頁 CMS 資料，回傳即時更新的 Stream。
  /// 文件不存在時回傳 null。
  Stream<CmsHomepage?> watchHomepage() {
    return _firestore
        .collection(_kCmsCollection)
        .doc(_kHomepageDoc)
        .withConverter<CmsHomepage?>(
          fromFirestore: (snapshot, _) =>
              snapshot.exists ? CmsHomepage.fromSnapshot(snapshot) : null,
          toFirestore: (_, __) => {},
        )
        .snapshots()
        .map((snapshot) => snapshot.data());
  }
}
