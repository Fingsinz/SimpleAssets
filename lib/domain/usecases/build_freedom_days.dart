import 'package:decimal/decimal.dart';

import '../entities/freedom_days.dart';

/// 由资产、三档月成本与年化收益率计算自由天数（纯函数）。
class BuildFreedomDays {
  const BuildFreedomDays();

  FreedomDaysSnapshot call({
    required Decimal asset,
    required bool usesNetAssets,
    required Decimal? minimumMonthlyCost,
    required Decimal? currentMonthlyCost,
    required Decimal? idealMonthlyCost,
    required double? annualizedRate,
  }) => build(
    asset: asset,
    usesNetAssets: usesNetAssets,
    minimumMonthlyCost: minimumMonthlyCost,
    currentMonthlyCost: currentMonthlyCost,
    idealMonthlyCost: idealMonthlyCost,
    annualizedRate: annualizedRate,
  );

  static FreedomDaysSnapshot build({
    required Decimal asset,
    required bool usesNetAssets,
    required Decimal? minimumMonthlyCost,
    required Decimal? currentMonthlyCost,
    required Decimal? idealMonthlyCost,
    required double? annualizedRate,
  }) {
    final positiveAsset = asset > Decimal.zero ? asset : Decimal.zero;

    FreedomDayEntry entry(FreedomCostKind kind, Decimal? cost) {
      final validCost = cost != null && cost > Decimal.zero ? cost : null;
      final days = _days(positiveAsset, validCost);
      return FreedomDayEntry(
        kind: kind,
        monthlyCost: validCost,
        days: days,
        years: days == null ? null : days / 365,
      );
    }

    final entries = <FreedomDayEntry>[
      entry(FreedomCostKind.minimum, minimumMonthlyCost),
      entry(FreedomCostKind.current, currentMonthlyCost),
      entry(FreedomCostKind.ideal, idealMonthlyCost),
    ];

    final currentCost = entries[FreedomCostKind.current.index].monthlyCost;

    FreedomCoverageState state;
    Decimal? monthlyPassiveIncome;
    double? coverage;

    if (positiveAsset == Decimal.zero) {
      state = FreedomCoverageState.noAssets;
    } else if (currentCost == null) {
      state = FreedomCoverageState.noCurrentCost;
    } else if (annualizedRate == null) {
      state = FreedomCoverageState.noAnnualizedRate;
    } else if (annualizedRate <= 0) {
      state = FreedomCoverageState.negativeAnnualizedRate;
    } else {
      final rate = Decimal.parse(annualizedRate.toString());
      monthlyPassiveIncome = (positiveAsset * rate / Decimal.fromInt(1200))
          .toDecimal();
      coverage = (monthlyPassiveIncome / currentCost).toDouble() * 100;
      state = FreedomCoverageState.available;
    }

    return FreedomDaysSnapshot(
      asset: positiveAsset,
      usesNetAssets: usesNetAssets,
      entries: [
        for (final item in entries)
          item.kind == FreedomCostKind.current
              ? FreedomDayEntry(
                  kind: item.kind,
                  monthlyCost: item.monthlyCost,
                  days: item.days,
                  years: item.years,
                  coverage: coverage,
                )
              : item,
      ],
      annualizedRate: annualizedRate,
      monthlyPassiveIncome: monthlyPassiveIncome,
      coverageState: state,
    );
  }

  static int? _days(Decimal asset, Decimal? monthlyCost) {
    if (asset <= Decimal.zero || monthlyCost == null) return null;
    final days =
        asset * Decimal.fromInt(365) / (monthlyCost * Decimal.fromInt(12));
    return days.toBigInt().toInt();
  }
}
