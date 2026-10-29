import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

/// SharedPreferences 封装，集中管理键名。
class AppPreferences {
  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  bool get autoRefresh => _prefs.getBool(AppConstants.prefAutoRefresh) ?? true;

  Future<bool> setAutoRefresh(bool value) =>
      _prefs.setBool(AppConstants.prefAutoRefresh, value);

  DateTime? get lastRefreshAt {
    final value = _prefs.getString(AppConstants.prefLastRefreshAt);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<bool> setLastRefreshAt(DateTime value) =>
      _prefs.setString(AppConstants.prefLastRefreshAt, value.toIso8601String());

  bool get includeCashInStats =>
      _prefs.getBool(AppConstants.prefIncludeCashInStats) ?? false;

  Future<bool> setIncludeCashInStats(bool value) =>
      _prefs.setBool(AppConstants.prefIncludeCashInStats, value);

  /// 主题模式：system / light / dark。
  String get themeMode =>
      _prefs.getString(AppConstants.prefThemeMode) ?? 'system';

  Future<bool> setThemeMode(String value) =>
      _prefs.setString(AppConstants.prefThemeMode, value);

  /// 主题配色：indigo / celadon / gilt。
  String get themePreset =>
      _prefs.getString(AppConstants.prefThemePreset) ?? 'indigo';

  Future<bool> setThemePreset(String value) =>
      _prefs.setString(AppConstants.prefThemePreset, value);

  static Future<AppPreferences> load() async =>
      AppPreferences(await SharedPreferences.getInstance());
}
