import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/prefs.dart';
import '../theme/theme_presets.dart';

class AppSettings {
  /// 自动 / 手动 / 下拉刷新共用的最小刷新间隔。
  static const Duration refreshCooldown = Duration(hours: 2);

  final bool autoRefresh;
  final DateTime? lastRefreshAt;
  final bool includeCashInStats;
  final bool hideAmounts;
  final ThemeMode themeMode;
  final AppThemePreset themePreset;

  const AppSettings({
    required this.autoRefresh,
    this.lastRefreshAt,
    this.includeCashInStats = false,
    this.hideAmounts = false,
    this.themeMode = ThemeMode.system,
    this.themePreset = AppThemePreset.indigo,
  });

  /// 距上次成功更新价格是否已超过冷却时间。
  bool canRefresh(DateTime now) {
    final last = lastRefreshAt;
    return last == null || now.difference(last) >= refreshCooldown;
  }

  AppSettings copyWith({
    bool? autoRefresh,
    DateTime? lastRefreshAt,
    bool? includeCashInStats,
    bool? hideAmounts,
    ThemeMode? themeMode,
    AppThemePreset? themePreset,
  }) {
    return AppSettings(
      autoRefresh: autoRefresh ?? this.autoRefresh,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      includeCashInStats: includeCashInStats ?? this.includeCashInStats,
      hideAmounts: hideAmounts ?? this.hideAmounts,
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
    );
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// 收益 / 回撤统计是否包含现金，默认 false。
final includeCashInStatsProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).valueOrNull?.includeCashInStats ?? false,
);

/// 是否隐藏所有金钱金额，默认 false。
final hideAmountsProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).valueOrNull?.hideAmounts ?? false,
);

/// 应用主题模式，默认跟随系统。
final themeModeProvider = Provider<ThemeMode>(
  (ref) =>
      ref.watch(settingsProvider).valueOrNull?.themeMode ?? ThemeMode.system,
);

/// 应用主题配色，默认靛青。
final themePresetProvider = Provider<AppThemePreset>(
  (ref) =>
      ref.watch(settingsProvider).valueOrNull?.themePreset ??
      AppThemePreset.indigo,
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  AppPreferences? _preferences;

  Future<AppPreferences> _prefs() async {
    return _preferences ??= await AppPreferences.load();
  }

  @override
  Future<AppSettings> build() async {
    final prefs = await _prefs();
    return AppSettings(
      autoRefresh: prefs.autoRefresh,
      lastRefreshAt: prefs.lastRefreshAt,
      includeCashInStats: prefs.includeCashInStats,
      hideAmounts: prefs.hideAmounts,
      themeMode: _themeModeFrom(prefs.themeMode),
      themePreset: AppThemePreset.fromId(prefs.themePreset),
    );
  }

  ThemeMode _themeModeFrom(String value) {
    for (final mode in ThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode value) async {
    final prefs = await _prefs();
    await prefs.setThemeMode(value.name);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(themeMode: value));
    }
  }

  Future<void> setThemePreset(AppThemePreset value) async {
    final prefs = await _prefs();
    await prefs.setThemePreset(value.id);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(themePreset: value));
    }
  }

  Future<void> setIncludeCashInStats(bool value) async {
    final prefs = await _prefs();
    await prefs.setIncludeCashInStats(value);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(includeCashInStats: value));
    }
  }

  Future<void> setHideAmounts(bool value) async {
    final prefs = await _prefs();
    await prefs.setHideAmounts(value);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(hideAmounts: value));
    }
  }

  Future<void> setAutoRefresh(bool value) async {
    final prefs = await _prefs();
    await prefs.setAutoRefresh(value);
    final current =
        state.valueOrNull ??
        AppSettings(
          autoRefresh: value,
          lastRefreshAt: prefs.lastRefreshAt,
          themeMode: _themeModeFrom(prefs.themeMode),
          themePreset: AppThemePreset.fromId(prefs.themePreset),
        );
    state = AsyncData(current.copyWith(autoRefresh: value));
  }

  Future<void> markRefreshed() async {
    final now = DateTime.now();
    final prefs = await _prefs();
    await prefs.setLastRefreshAt(now);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(lastRefreshAt: now));
    }
  }
}
