import 'package:flutter/material.dart';

import '../../../../shared/theme/app_design_tokens.dart';

/// 首頁底部行動呼籲（CTA）區塊。
///
/// 引導使用者前往商品分類頁，搭配品牌色漸層背景營造收尾視覺。
class CtaSection extends StatelessWidget {
  const CtaSection({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDesignTokens.mobileBreakpoint;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFAEDED),
            Color(0xFFF5EBE8),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDesignTokens.contentMaxWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDesignTokens.pagePadding,
              vertical: isDesktop ? 72.0 : 56.0,
            ),
            child: Column(
              children: [
                // 裝飾線
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 1.5,
                      color: AppDesignTokens.brandRed.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppDesignTokens.brandRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 32,
                      height: 1.5,
                      color: AppDesignTokens.brandRed.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '探索當季好果',
                  style: TextStyle(
                    fontSize: isDesktop ? 30 : 24,
                    fontWeight: FontWeight.w700,
                    color: AppDesignTokens.textPrimary,
                    height: 1.3,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '從梨山到您的餐桌，每一口都是大自然的恩賜',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    color: AppDesignTokens.textSecondary,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: isDesktop ? null : double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignTokens.brandRed,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppDesignTokens.brandRed
                          .withValues(alpha: 0.4),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48 : 36,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radiusMd,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    child: const Text('立即選購'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
