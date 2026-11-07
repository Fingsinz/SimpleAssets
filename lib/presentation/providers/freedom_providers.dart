import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/prefs.dart';
import '../../domain/entities/freedom_days.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/square_inch_jar.dart';
import '../../domain/usecases/build_freedom_days.dart';
import '../../domain/usecases/build_square_inch_jar.dart';
import 'performance_providers.dart';
import 'portfolio_providers.dart';

/// 方寸罐与自由天数使用的资产口径。
enum FreedomAssetBasis {
  net('net', '净资产'),
  total('total', '总资产');

  final String id;
  final String label;

  const FreedomAssetBasis(this.id, this.label);

  static FreedomAssetBasis fromId(String? id) {
    for (final basis in values) {
      if (basis.id == id) return basis;
    }
    return FreedomAssetBasis.net;
  }
}

/// 自由页的本地配置。
class FreedomConfig {
  final FreedomAssetBasis assetBasis;
  final Decimal unitValue;
  final Decimal? minimumMonthlyCost;
  final Decimal? currentMonthlyCost;
  final Decimal? idealMonthlyCost;

  const FreedomConfig({
    required this.assetBasis,
    required this.unitValue,
    this.minimumMonthlyCost,
    this.currentMonthlyCost,
    this.idealMonthlyCost,
  });

  static FreedomConfig initial() => FreedomConfig(
        assetBasis: FreedomAssetBasis.net,
        unitValue: Decimal.fromInt(100),
      );
}

final freedomConfigProvider =
    AsyncNotifierProvider<FreedomConfigNotifier, FreedomConfig>(
  FreedomConfigNotifier.new,
);

/// 首帧也有一份可渲染的配置，避免页面闪烁。
final freedomConfigValueProvider = Provider<FreedomConfig>(
  (ref) =>
      ref.watch(freedomConfigProvider).valueOrNull ?? FreedomConfig.initial(),
);

final buildSquareInchJarProvider =
    Provider<BuildSquareInchJar>((ref) => const BuildSquareInchJar());

final buildFreedomDaysProvider =
    Provider<BuildFreedomDays>((ref) => const BuildFreedomDays());

Decimal _assetFor(PortfolioSummary summary, FreedomAssetBasis basis) =>
    basis == FreedomAssetBasis.net ? summary.netAssets : summary.totalAssets;

/// 方寸罐：资产随持仓与口径自动重算。
final squareInchJarProvider = Provider<SquareInchJar>((ref) {
  final summary = ref.watch(overviewSummaryProvider);
  final config = ref.watch(freedomConfigValueProvider);
  return ref.watch(buildSquareInchJarProvider)(
    asset: _assetFor(summary, config.assetBasis),
    unitValue: config.unitValue,
  );
});

/// 自由天数与被动收入覆盖率。
final freedomDaysProvider = Provider<FreedomDaysSnapshot>((ref) {
  final summary = ref.watch(overviewSummaryProvider);
  final config = ref.watch(freedomConfigValueProvider);
  final annualizedRate = ref
      .watch(performanceResultProvider)
      .valueOrNull
      ?.sinceInception
      ?.annualizedRate;

  return ref.watch(buildFreedomDaysProvider)(
    asset: _assetFor(summary, config.assetBasis),
    usesNetAssets: config.assetBasis == FreedomAssetBasis.net,
    minimumMonthlyCost: config.minimumMonthlyCost,
    currentMonthlyCost: config.currentMonthlyCost,
    idealMonthlyCost: config.idealMonthlyCost,
    annualizedRate: annualizedRate,
  );
});

class FreedomConfigNotifier extends AsyncNotifier<FreedomConfig> {
  AppPreferences? _preferences;

  Future<AppPreferences> _prefs() async {
    return _preferences ??= await AppPreferences.load();
  }

  @override
  Future<FreedomConfig> build() async {
    return _fromPreferences(await _prefs());
  }

  static FreedomConfig _fromPreferences(AppPreferences prefs) {
    return FreedomConfig(
      assetBasis: FreedomAssetBasis.fromId(prefs.freedomAssetBasis),
      unitValue:
          _parsePositive(prefs.freedomUnitValue) ?? Decimal.fromInt(100),
      minimumMonthlyCost: _parsePositive(prefs.freedomCostMin),
      currentMonthlyCost: _parsePositive(prefs.freedomCostCurrent),
      idealMonthlyCost: _parsePositive(prefs.freedomCostIdeal),
    );
  }

  static Decimal? _parsePositive(String? raw) {
    if (raw == null) return null;
    final value = Decimal.tryParse(raw);
    return value != null && value > Decimal.zero ? value : null;
  }

  FreedomConfig get _current => state.valueOrNull ?? FreedomConfig.initial();

  Future<void> setAssetBasis(FreedomAssetBasis value) async {
    final prefs = await _prefs();
    await prefs.setFreedomAssetBasis(value.id);
    final current = _current;
    state = AsyncData(
      FreedomConfig(
        assetBasis: value,
        unitValue: current.unitValue,
        minimumMonthlyCost: current.minimumMonthlyCost,
        currentMonthlyCost: current.currentMonthlyCost,
        idealMonthlyCost: current.idealMonthlyCost,
      ),
    );
  }

  Future<void> setUnitValue(Decimal value) async {
    if (value <= Decimal.zero) return;
    final prefs = await _prefs();
    await prefs.setFreedomUnitValue(value.toString());
    final current = _current;
    state = AsyncData(
      FreedomConfig(
        assetBasis: current.assetBasis,
        unitValue: value,
        minimumMonthlyCost: current.minimumMonthlyCost,
        currentMonthlyCost: current.currentMonthlyCost,
        idealMonthlyCost: current.idealMonthlyCost,
      ),
    );
  }

  Future<void> setCosts({
    required Decimal? minimum,
    required Decimal? current,
    required Decimal? ideal,
  }) async {
    final prefs = await _prefs();
    await prefs.setFreedomCostMin(minimum?.toString());
    await prefs.setFreedomCostCurrent(current?.toString());
    await prefs.setFreedomCostIdeal(ideal?.toString());
    final config = _current;
    state = AsyncData(
      FreedomConfig(
        assetBasis: config.assetBasis,
        unitValue: config.unitValue,
        minimumMonthlyCost: minimum,
        currentMonthlyCost: current,
        idealMonthlyCost: ideal,
      ),
    );
  }
}
