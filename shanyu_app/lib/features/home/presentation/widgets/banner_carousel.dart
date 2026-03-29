import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, LaunchMode;

import '../../models/cms_models.dart';
import '../../providers/cms_providers.dart';

// ── 設計 Token ────────────────────────────────────────────────────────────────

abstract final class _BannerTokens {
  static const aspectRatio = 2.5;
  static const autoPlayInterval = Duration(seconds: 4);
  static const animationDuration = Duration(milliseconds: 600);
  static const animationCurve = Curves.easeInOut;

  static const indicatorSize = 8.0;
  static const indicatorActiveWidth = 24.0;
  static const indicatorSpacing = 4.0;
  static const indicatorActiveColor = Colors.white;
  static const indicatorInactiveColor = Color(0x66FFFFFF);

  static const placeholderGradientStart = Color(0xFF5C4033);
  static const placeholderGradientEnd = Color(0xFF8D6E63);

  static const shimmerBase = Color(0xFFEEEEEE);
  static const shimmerHighlight = Color(0xFFF5F5F5);
}

// ── BannerCarousel ────────────────────────────────────────────────────────────

/// 首頁 Banner 輪播元件。
///
/// 從 [cmsHomepageProvider] 取得 Banner 列表，使用 [carousel_slider] 展示。
/// 無資料時顯示品牌色漸層佔位。
class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({super.key});

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cmsAsync = ref.watch(cmsHomepageProvider);

    return cmsAsync.when(
      loading: () => _BannerPlaceholder(isLoading: true),
      error: (_, __) => _BannerPlaceholder(isLoading: false),
      data: (cms) {
        final banners = cms?.banners ?? [];

        if (banners.isEmpty) {
          return _BannerPlaceholder(isLoading: false);
        }

        return _BannerSlider(
          banners: banners,
          currentIndex: _currentIndex,
          onPageChanged: (index) => setState(() => _currentIndex = index),
        );
      },
    );
  }
}

// ── 輪播核心 ──────────────────────────────────────────────────────────────────

class _BannerSlider extends StatelessWidget {
  const _BannerSlider({
    required this.banners,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<BannerItem> banners;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: _BannerTokens.aspectRatio,
          child: CarouselSlider.builder(
            itemCount: banners.length,
            itemBuilder: (context, index, _) {
              return _BannerSlide(banner: banners[index]);
            },
            options: CarouselOptions(
              viewportFraction: 1.0,
              autoPlay: banners.length > 1,
              autoPlayInterval: _BannerTokens.autoPlayInterval,
              autoPlayAnimationDuration: _BannerTokens.animationDuration,
              autoPlayCurve: _BannerTokens.animationCurve,
              enlargeCenterPage: false,
              onPageChanged: (index, _) => onPageChanged(index),
            ),
          ),
        ),

        // 指示器（多於一張時才顯示）
        if (banners.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: _BannerIndicator(
              count: banners.length,
              currentIndex: currentIndex,
            ),
          ),
      ],
    );
  }
}

// ── 單張 Banner ───────────────────────────────────────────────────────────────

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner});

  final BannerItem banner;

  Future<void> _handleTap() async {
    final url = banner.linkUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: banner.linkUrl != null ? _handleTap : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => const _ImageShimmer(),
            errorWidget: (_, __, ___) => const _BannerPlaceholder(
              isLoading: false,
            ),
          ),

          // 底部漸層遮罩（提升指示器可讀性）
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x55000000)],
                ),
              ),
            ),
          ),

          // Banner 標題文字
          if (banner.title != null && banner.title!.isNotEmpty)
            Positioned(
              bottom: 36,
              left: 24,
              right: 24,
              child: Text(
                banner.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 8,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// ── 頁面指示器 ────────────────────────────────────────────────────────────────

class _BannerIndicator extends StatelessWidget {
  const _BannerIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(
            horizontal: _BannerTokens.indicatorSpacing / 2,
          ),
          width: isActive
              ? _BannerTokens.indicatorActiveWidth
              : _BannerTokens.indicatorSize,
          height: _BannerTokens.indicatorSize,
          decoration: BoxDecoration(
            color: isActive
                ? _BannerTokens.indicatorActiveColor
                : _BannerTokens.indicatorInactiveColor,
            borderRadius: BorderRadius.circular(_BannerTokens.indicatorSize / 2),
          ),
        );
      }),
    );
  }
}

// ── 佔位元件 ──────────────────────────────────────────────────────────────────

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _BannerTokens.aspectRatio,
      child: isLoading
          ? const _ImageShimmer()
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _BannerTokens.placeholderGradientStart,
                    _BannerTokens.placeholderGradientEnd,
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '山裕嚴選農產品',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Shimmer 載入動畫 ──────────────────────────────────────────────────────────

class _ImageShimmer extends StatefulWidget {
  const _ImageShimmer();

  @override
  State<_ImageShimmer> createState() => _ImageShimmerState();
}

class _ImageShimmerState extends State<_ImageShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: const [
                _BannerTokens.shimmerBase,
                _BannerTokens.shimmerHighlight,
                _BannerTokens.shimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }
}
