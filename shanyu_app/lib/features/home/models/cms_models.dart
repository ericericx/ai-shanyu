import 'package:cloud_firestore/cloud_firestore.dart';

// ── BannerItem ────────────────────────────────────────────────────────────────

/// 首頁 Banner 單項資料，對應 Firestore `cms/homepage.banners[]`。
class BannerItem {
  const BannerItem({
    required this.id,
    required this.imageUrl,
    this.linkUrl,
    this.title,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String imageUrl;
  final String? linkUrl;
  final String? title;
  final int sortOrder;
  final bool isActive;

  factory BannerItem.fromMap(Map<String, dynamic> map) {
    return BannerItem(
      id: map['id'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      linkUrl: map['linkUrl'] as String?,
      title: map['title'] as String?,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      if (linkUrl != null) 'linkUrl': linkUrl,
      if (title != null) 'title': title,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

// ── CmsHomepage ───────────────────────────────────────────────────────────────

/// 首頁 CMS 資料，對應 Firestore `cms/homepage` 文件。
class CmsHomepage {
  const CmsHomepage({
    required this.banners,
    required this.brandStoryTitle,
    required this.brandStoryContent,
    required this.brandStoryImageUrl,
  });

  final List<BannerItem> banners;
  final String brandStoryTitle;
  final String brandStoryContent;
  final String brandStoryImageUrl;

  factory CmsHomepage.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final rawBanners = data['banners'] as List<dynamic>? ?? [];
    final banners = rawBanners
        .whereType<Map<String, dynamic>>()
        .map(BannerItem.fromMap)
        .where((b) => b.isActive && b.imageUrl.isNotEmpty)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return CmsHomepage(
      banners: banners,
      brandStoryTitle: data['brandStoryTitle'] as String? ?? '山裕的故事',
      brandStoryContent: data['brandStoryContent'] as String? ??
          '我們來自梨山，用心栽培每一顆果實，將大自然的恩賜直送到您的餐桌。',
      brandStoryImageUrl: data['brandStoryImageUrl'] as String? ?? '',
    );
  }
}
