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

  static Future<AppPreferences> load() async =>
      AppPreferences(await SharedPreferences.getInstance());
}
