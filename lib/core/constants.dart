/// 应用级常量。
class AppConstants {
  AppConstants._();

  static const String appName = '方寸有数';
  static const String appTitle = appName;
  static const String appSlogan = '方寸有数，资产有底';
  static const String appAuthor = 'Fingsinz';
  static const String appAiAssistant = 'DeepSeek';

  /// 随应用版本更新，需与 pubspec.yaml 的 version 保持一致。
  static const String appVersion = '1.1.0';

  /// 数据库名保持原名：改名会导致已有用户数据无法读取。
  static const String databaseName = 'simple_assets';
  static const String defaultCurrency = 'CNY';

  static const String prefAutoRefresh = 'auto_refresh';
  static const String prefLastRefreshAt = 'last_refresh_at';
}
