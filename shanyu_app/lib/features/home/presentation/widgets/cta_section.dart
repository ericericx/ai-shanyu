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
            Color(0xFFFDF0F0),
            Color(0xFFFAF7F4),
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
              vertical: isDesktop ? 64.0 : 48.0,
            ),
            child: Column(
              children: [
                Text(
                  '探索當季好果',
                  style: TextStyle(
                    fontSize: isDesktop ? 28 : 22,
                    fontWeight: FontWeight.w700,
                    color: AppDesignTokens.textPrimary,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '從梨山到您的餐桌，每一口都是大自然的恩賜',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    color: AppDesignTokens.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: isDesktop ? null : double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignTokens.brandRed,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 40 : 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radiusMd,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
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
