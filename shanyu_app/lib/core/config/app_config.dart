/// 應用程式 Flavor 列舉
enum AppFlavor {
  development,
  production,
}

/// 應用程式全域設定
///
/// 透過 Flavor 機制區分不同環境的設定值，
/// 在 main_dev.dart 或 main_prod.dart 中注入。
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.firebaseProjectId,
    required this.apiBaseUrl,
    required this.appDisplayName,
  });

  /// 目前執行環境
  final AppFlavor flavor;

  /// Firebase 專案 ID
  final String firebaseProjectId;

  /// API 基礎 URL
  final String apiBaseUrl;

  /// 顯示用 App 名稱（含環境標示）
  final String appDisplayName;

  /// 是否為開發環境
  bool get isDevelopment => flavor == AppFlavor.development;

  /// 是否為正式環境
  bool get isProduction => flavor == AppFlavor.production;

  @override
  String toString() =>
      'AppConfig(flavor: $flavor, projectId: $firebaseProjectId)';
}
