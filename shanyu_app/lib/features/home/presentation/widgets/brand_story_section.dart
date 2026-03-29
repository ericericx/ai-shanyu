// lib/features/home/presentation/widgets/brand_story_section.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/cms_models.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _BrandTokens {
  static const surface = Color(0xFFFAF8F5);
  static const brandBrown = Color(0xFF5C4033);
  static const brandBrownLight = Color(0xFF8D6E63);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const accentLine = Color(0xFF5C4033);

  static const pagePadding = 24.0;
  static const imageRadius = 12.0;
  static const accentLineWidth = 4.0;
  static const accentLineHeight = 56.0;

  // 響應式斷點（與 T-10 一致）
  static const mobileBreakpoint = 600.0;
}

// ── BrandStorySection ─────────────────────────────────────────────────────────

/// 首頁品牌故事區塊。
///
/// 響應式佈局：
/// - 桌機（>= 600dp）：左側圖片 + 右側文字，左右分欄
/// - 手機（< 600dp）：上圖下文，垂直堆疊
///
/// 圖片由 [cms.brandStoryImageUrl] 提供；無圖時改為純文字置中排版。
class BrandStorySection extends StatelessWidget {
  const BrandStorySection({
    super.key,
    required this.cms,
  });

  final CmsHomepage cms;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _BrandTokens.mobileBreakpoint;
        final hasImage = cms.brandStoryImageUrl.isNotEmpty;

        if (!hasImage) {
          return _TextOnlyLayout(
            title: cms.brandStoryTitle,
            content: cms.brandStoryContent,
          );
        }

        return isDesktop
            ? _DesktopLayout(
                imageUrl: cms.brandStoryImageUrl,
                title: cms.brandStoryTitle,
                content: cms.brandStoryContent,
              )
            : _MobileLayout(
                imageUrl: cms.brandStoryImageUrl,
                title: cms.brandStoryTitle,
                content: cms.brandStoryContent,
              );
      },
    );
  }
}

// ── 桌機：左右分欄 ────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.imageUrl,
    required this.title,
    required this.content,
  });

  final String imageUrl;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _BrandTokens.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: _BrandTokens.pagePadding,
        vertical: 40,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左側裝飾線
          Container(
            width: _BrandTokens.accentLineWidth,
            height: _BrandTokens.accentLineHeight,
            decoration: BoxDecoration(
              color: _BrandTokens.accentLine,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 20),

          // 左側：品牌圖片
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_BrandTokens.imageRadius),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFFEDE5DD),
                  ),
                  errorWidget: (_, __, ___) => _ImageFallback(),
                ),
              ),
            ),
          ),

          const SizedBox(width: 40),

          // 右側：文字內容
          Expanded(
            flex: 6,
            child: _BrandTextContent(
              title: title,
              content: content,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 手機：上下堆疊 ────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.imageUrl,
    required this.title,
    required this.content,
  });

  final String imageUrl;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _BrandTokens.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 上方：品牌圖片（全寬）
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(_BrandTokens.imageRadius),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFFEDE5DD),
                ),
                errorWidget: (_, __, ___) => _ImageFallback(),
              ),
            ),
          ),

          // 下方：文字 + 左側裝飾線
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _BrandTokens.pagePadding,
              24,
              _BrandTokens.pagePadding,
              32,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 裝飾線
                  Container(
                    width: _BrandTokens.accentLineWidth,
                    decoration: BoxDecoration(
                      color: _BrandTokens.accentLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _BrandTextContent(
                      title: title,
                      content: content,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 無圖純文字佈局 ────────────────────────────────────────────────────────────

class _TextOnlyLayout extends StatelessWidget {
  const _TextOnlyLayout({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _BrandTokens.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: _BrandTokens.pagePadding,
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: _BrandTokens.brandBrown,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _BrandTextContent(
            title: title,
            content: content,
            centerAlign: true,
          ),
        ],
      ),
    );
  }
}

// ── 文字內容元件（可複用） ─────────────────────────────────────────────────────

class _BrandTextContent extends StatelessWidget {
  const _BrandTextContent({
    required this.title,
    required this.content,
    this.centerAlign = false,
  });

  final String title;
  final String content;
  final bool centerAlign;

  @override
  Widget build(BuildContext context) {
    final alignment =
        centerAlign ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centerAlign ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 小標題
        Text(
          '品牌故事',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _BrandTokens.brandBrownLight,
            letterSpacing: 2.0,
          ),
          textAlign: textAlign,
        ),
        const SizedBox(height: 10),

        // 大標題
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _BrandTokens.textPrimary,
            height: 1.35,
            letterSpacing: 0.3,
          ),
          textAlign: textAlign,
        ),
        const SizedBox(height: 16),

        // 內文
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            color: _BrandTokens.textSecondary,
            height: 1.8,
          ),
          textAlign: textAlign,
        ),
      ],
    );
  }
}

// ── 圖片載入失敗佔位 ──────────────────────────────────────────────────────────

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEDE5DD),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: _BrandTokens.brandBrownLight,
        ),
      ),
    );
  }
}
