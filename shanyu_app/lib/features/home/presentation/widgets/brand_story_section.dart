// lib/features/home/presentation/widgets/brand_story_section.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_design_tokens.dart';
import '../../models/cms_models.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _BrandTokens {
  static const brandRed = AppDesignTokens.brandRed;
  static const surface = AppDesignTokens.surfaceAlt;
  static const brandBrownLight = Color(0xFF8D6E63);
  static const textPrimary = AppDesignTokens.textPrimary;
  static const textSecondary = AppDesignTokens.textSecondary;

  static const pagePadding = AppDesignTokens.pagePadding;
  static const imageRadius = 12.0;
  static const mobileBreakpoint = AppDesignTokens.mobileBreakpoint;
}

// ── BrandStorySection ─────────────────────────────────────────────────────────

class BrandStorySection extends StatelessWidget {
  const BrandStorySection({super.key, required this.cms});

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

// ── 共用：區塊標題列 ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.center = false});

  final String title;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: center ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: _BrandTokens.brandRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _BrandTokens.textPrimary,
            height: 1.3,
          ),
        ),
      ],
    );

    return center ? Center(child: row) : row;
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
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_BrandTokens.imageRadius),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFFEDE5DD)),
                      errorWidget: (_, __, ___) => const _ImageFallback(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 6,
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _BrandTokens.textSecondary,
                    height: 1.8,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _BrandTokens.pagePadding,
              24,
              _BrandTokens.pagePadding,
              16,
            ),
            child: _SectionHeader(title: title),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(_BrandTokens.imageRadius),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: const Color(0xFFEDE5DD)),
                errorWidget: (_, __, ___) => const _ImageFallback(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _BrandTokens.pagePadding,
              20,
              _BrandTokens.pagePadding,
              32,
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                color: _BrandTokens.textSecondary,
                height: 1.8,
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
  const _TextOnlyLayout({required this.title, required this.content});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
          const SizedBox(height: 20),
          Text(
            content,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 15,
              color: _BrandTokens.textSecondary,
              height: 1.8,
            ),
          ),
        ],
      ),
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
