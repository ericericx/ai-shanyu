import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_nav_bar.dart';
import '../providers/cms_providers.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/product_timeline.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _HomeTokens {
  static const brandBrown = Color(0xFF5C4033);
  static const brandBrownLight = Color(0xFF8D6E63);
  static const surface = Color(0xFFFAF7F4);
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const divider = Color(0xFFEFEBE9);

  static const pagePadding = 24.0;
  static const sectionGap = 48.0;
  static const contentMaxWidth = 1200.0;
}

// ── HomePage ──────────────────────────────────────────────────────────────────

/// 首頁入口頁面（路由 `/`）。
///
/// 結構：AppNavBar → BannerCarousel → 品牌故事區塊
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _HomeTokens.surface,
      appBar: const AppNavBar(),
      body: const _HomeBody(),
    );
  }
}

// ── 頁面主體（可捲動） ─────────────────────────────────────────────────────────

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner 輪播
          const BannerCarousel(),

          const SizedBox(height: _HomeTokens.sectionGap),

          // 品牌故事區塊
          const _BrandStorySection(),

          const SizedBox(height: _HomeTokens.sectionGap),

          // 季節流水線區塊
          const _ProductTimelineSection(),

          const SizedBox(height: _HomeTokens.sectionGap),
        ],
      ),
    );
  }
}

// ── 品牌故事區塊 ──────────────────────────────────────────────────────────────

class _BrandStorySection extends ConsumerWidget {
  const _BrandStorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cmsAsync = ref.watch(cmsHomepageProvider);

    final title = cmsAsync.valueOrNull?.brandStoryTitle ?? '山裕的故事';
    final content = cmsAsync.valueOrNull?.brandStoryContent ??
        '我們來自梨山，用心栽培每一顆果實，將大自然的恩賜直送到您的餐桌。';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _HomeTokens.contentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _HomeTokens.pagePadding,
          ),
          child: _BrandStoryCard(title: title, content: content),
        ),
      ),
    );
  }
}

class _BrandStoryCard extends StatelessWidget {
  const _BrandStoryCard({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomeTokens.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 裝飾線
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: _HomeTokens.brandBrown,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 標題
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _HomeTokens.textPrimary,
              height: 1.3,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // 內文
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: _HomeTokens.textSecondary,
              height: 1.8,
            ),
          ),

          const SizedBox(height: 28),

          // 瞭解更多按鈕（Placeholder，待後續功能實作）
          OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _HomeTokens.brandBrown),
              foregroundColor: _HomeTokens.brandBrown,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '瞭解更多',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 季節流水線區塊 ─────────────────────────────────────────────────────────────

class _ProductTimelineSection extends StatelessWidget {
  const _ProductTimelineSection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _HomeTokens.contentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _HomeTokens.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 區塊標題
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _HomeTokens.brandBrown,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '季節農產時程',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _HomeTokens.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '依月份掌握各農產品的生長與採收時節',
                style: TextStyle(
                  fontSize: 13,
                  color: _HomeTokens.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              const ProductTimeline(),
            ],
          ),
        ),
      ),
    );
  }
}
