// lib/features/home/models/product_timeline_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 旬期輔助工具。
///
/// Period 定義：1–36，0 = 未設定。
/// Period = (month - 1) * 3 + decade
///   month: 1–12
///   decade: 1 = 上旬, 2 = 中旬, 3 = 下旬
abstract final class PeriodHelper {
  /// 總旬數（12 個月 × 3 旬）
  static const int total = 36;

  /// Period → 月份（1–12）
  static int month(int period) => ((period - 1) ~/ 3) + 1;

  /// Period → 旬（1=上旬, 2=中旬, 3=下旬）
  static int decade(int period) => ((period - 1) % 3) + 1;

  /// 月份 + 旬 → Period
  static int toPeriod(int month, int decade) => (month - 1) * 3 + decade;

  /// 旬的中文名稱
  static String decadeLabel(int decade) => switch (decade) {
        1 => '上旬',
        2 => '中旬',
        _ => '下旬',
      };

  /// Period 的完整標籤，例如「3月中旬」
  static String label(int period) {
    if (period <= 0) return '未設定';
    return '${month(period)}月${decadeLabel(decade(period))}';
  }

  /// 判斷 period 是否在 [start, end] 範圍內（支援跨年）
  static bool inRange(int start, int end, int period) {
    if (start <= 0 || end <= 0) return false;
    if (start <= end) return period >= start && period <= end;
    // 跨年：start > end（例如 11月上旬 ~ 2月下旬）
    return period >= start || period <= end;
  }
}

/// 季節流水線用的商品資料模型。
/// 對應 Firestore `products` 集合中的欄位。
class TimelineProduct {
  const TimelineProduct({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.growingStartPeriod,
    required this.growingEndPeriod,
    required this.harvestStartPeriod,
    required this.harvestEndPeriod,
    required this.status,
  });

  final String id;
  final String categoryId;
  final String name;

  /// 生長期起始旬（1–36，0 = 未設定）
  final int growingStartPeriod;

  /// 生長期結束旬（1–36，0 = 未設定）
  final int growingEndPeriod;

  /// 採收期起始旬（1–36，0 = 未設定）
  final int harvestStartPeriod;

  /// 採收期結束旬（1–36，0 = 未設定）
  final int harvestEndPeriod;

  /// 'active' | 'draft'
  final String status;

  factory TimelineProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimelineProduct(
      id: doc.id,
      categoryId: (data['categoryId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      growingStartPeriod: (data['growingStartPeriod'] as int?) ?? 0,
      growingEndPeriod: (data['growingEndPeriod'] as int?) ?? 0,
      harvestStartPeriod: (data['harvestStartPeriod'] as int?) ?? 0,
      harvestEndPeriod: (data['harvestEndPeriod'] as int?) ?? 0,
      status: (data['status'] as String?) ?? 'draft',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineProduct &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
