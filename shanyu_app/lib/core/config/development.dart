import 'app_config.dart';

/// Development 環境設定
///
/// 指向 shayu-staging Firebase 專案，
/// 供本地開發與測試使用。
const developmentConfig = AppConfig(
  flavor: AppFlavor.development,
  firebaseProjectId: 'shayu-staging',
  apiBaseUrl: 'https://us-central1-shayu-staging.cloudfunctions.net',
  appDisplayName: '山裕電商 [DEV]',
);
