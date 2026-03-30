import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../home/models/cms_models.dart';

// ── CmsAdminRepository ────────────────────────────────────────────────────────

/// CMS 後台寫入層。
///
/// 管理員專用，負責更新 Firestore `cms/homepage` 與上傳圖片至 Firebase Storage。
class CmsAdminRepository {
  CmsAdminRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _kCmsCollection = 'cms';
  static const _kHomepageDoc = 'homepage';
  static const _kStorageCmsPath = 'cms';

  DocumentReference<Map<String, dynamic>> get _homepageRef =>
      _firestore.collection(_kCmsCollection).doc(_kHomepageDoc);

  // ── Banner ──────────────────────────────────────────────────────────────────

  /// 以傳入的 [banners] 完整替換 `cms/homepage.banners` 陣列。
  /// sortOrder 依列表順序自動重新編號（0-based），確保順序一致。
  Future<void> updateBanners(List<BannerItem> banners) async {
    final reordered = banners.asMap().entries.map((entry) {
      final item = entry.value;
      return BannerItem(
        id: item.id,
        imageUrl: item.imageUrl,
        linkUrl: item.linkUrl,
        title: item.title,
        sortOrder: entry.key,
        isActive: item.isActive,
      ).toMap();
    }).toList();

    await _homepageRef.set(
      {'banners': reordered},
      SetOptions(merge: true),
    );
  }

  // ── 品牌故事 ────────────────────────────────────────────────────────────────

  /// 更新 `cms/homepage` 的品牌故事三個欄位。
  Future<void> updateBrandStory({
    required String title,
    required String content,
    required String imageUrl,
  }) async {
    await _homepageRef.set(
      {
        'brandStoryTitle': title,
        'brandStoryContent': content,
        'brandStoryImageUrl': imageUrl,
      },
      SetOptions(merge: true),
    );
  }

  // ── 圖片上傳 ────────────────────────────────────────────────────────────────

  /// 上傳圖片至 Firebase Storage `cms/<fileName>`，回傳公開下載 URL。
  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final ref = _storage.ref('$_kStorageCmsPath/$fileName');
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: _inferContentType(fileName)),
    );
    return task.ref.getDownloadURL();
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  String _inferContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }
}
