import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_nav_bar.dart';
import '../providers/cms_providers.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/brand_story_section.dart';
import 'widgets/category_tab_bar.dart';
import 'widgets/product_timeline.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _HomeTokens {
  static const brandRed = Color(0xFFB82020);
  static const brandRedDark = Color(0xFF9C1B1B);
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
          // Banner
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: const BannerCarousel(),
            ),
          ),

          const SizedBox(height: _HomeTokens.sectionGap),

          // 山裕故事
          _BrandStorySectionWrapper(),

          const SizedBox(height: _HomeTokens.sectionGap),

          // 商品分類
          const CategoryTabBar(),

          const SizedBox(height: _HomeTokens.sectionGap),

          // 季節農產時程
          const _ProductTimelineSection(),

          const SizedBox(height: _HomeTokens.sectionGap),
        ],
      ),
    );
  }
}

// ── 品牌故事區塊包裝器 ────────────────────────────────────────────────────────
//
// 從 cmsHomepageProvider 讀取資料後交給 BrandStorySection 渲染。
// BrandStorySection 本身是純 StatelessWidget，便於測試與複用。

class _BrandStorySectionWrapper extends ConsumerWidget {
  const _BrandStorySectionWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cmsAsync = ref.watch(cmsHomepageProvider);

    // 使用預設值讓骨架在資料尚未載入時也能顯示文字
    final cms = cmsAsync.valueOrNull;
    if (cms == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _HomeTokens.contentMaxWidth,
        ),
        child: BrandStorySection(cms: cms),
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
                      color: _HomeTokens.brandRed,
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
