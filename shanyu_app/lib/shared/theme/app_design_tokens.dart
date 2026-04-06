import 'package:flutter/material.dart';

/// 全站集中化設計 Token。
///
/// 所有色彩、間距、圓角等視覺常數統一在此定義，
/// 各 widget 的 `_XxxTokens` 類別應引用此處常數。
abstract final class AppDesignTokens {
  // ── 品牌色 ──────────────────────────────────────────────────────────────────
  static const brandRed = Color(0xFFB82020);
  static const brandRedDark = Color(0xFF9C1B1B);

  // ── 背景 ────────────────────────────────────────────────────────────────────
  static const surface = Color(0xFFFAF7F4);
  static const surfaceAlt = Color(0xFFFAF8F5);

  // ── 文字 ────────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF2D2118);
  static const textSecondary = Color(0xFF6D4C41);
  static const textMuted = Color(0xFF9E9E9E);

  // ── 分隔線 / 邊框 ──────────────────────────────────────────────────────────
  static const divider = Color(0xFFEFEBE9);
  static const dividerGrey = Color(0xFFE0E0E0);

  // ── 間距 ────────────────────────────────────────────────────────────────────
  static const pagePadding = 24.0;
  static const sectionGap = 48.0;
  static const contentMaxWidth = 1200.0;

  // ── 圓角 ────────────────────────────────────────────────────────────────────
  static const radiusSm = 4.0;
  static const radiusMd = 10.0;

  // ── 斷點 ────────────────────────────────────────────────────────────────────
  static const mobileBreakpoint = 600.0;

  // ── Shimmer ─────────────────────────────────────────────────────────────────
  static const shimmerBase = Color(0xFFEEEEEE);
  static const shimmerHighlight = Color(0xFFF5F5F5);
}
