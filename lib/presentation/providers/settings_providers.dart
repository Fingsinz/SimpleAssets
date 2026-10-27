import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/prefs.dart';

class AppSettings {
  final bool autoRefresh;
  final DateTime? lastRefreshAt;
  final bool includeCashInStats;

  const AppSettings({
    required this.autoRefresh,
    this.lastRefreshAt,
    this.includeCashInStats = false,
  });

  AppSettings copyWith({
    bool? autoRefresh,
    DateTime? lastRefreshAt,
    bool? includeCashInStats,
  }) {
    return AppSettings(
      autoRefresh: autoRefresh ?? this.autoRefresh,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      includeCashInStats: includeCashInStats ?? this.includeCashInStats,
    );
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// 收益 / 回撤统计是否包含现金，默认 false。
final includeCashInStatsProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).valueOrNull?.includeCashInStats ?? false,
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
    );
  }

  Future<void> setIncludeCashInStats(bool value) async {
    final prefs = await _prefs();
    await prefs.setIncludeCashInStats(value);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(includeCashInStats: value));
    }
  }

  Future<void> setAutoRefresh(bool value) async {
    final prefs = await _prefs();
    await prefs.setAutoRefresh(value);
    final current = state.valueOrNull ??
        AppSettings(autoRefresh: value, lastRefreshAt: prefs.lastRefreshAt);
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
