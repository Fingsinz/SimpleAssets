import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/prefs.dart';

class AppSettings {
  final bool autoRefresh;
  final DateTime? lastRefreshAt;

  const AppSettings({required this.autoRefresh, this.lastRefreshAt});

  AppSettings copyWith({bool? autoRefresh, DateTime? lastRefreshAt}) {
    return AppSettings(
      autoRefresh: autoRefresh ?? this.autoRefresh,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
    );
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

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
    );
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
