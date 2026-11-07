import 'package:decimal/decimal.dart';

/// 三档月生活成本。
enum FreedomCostKind {
  minimum('最低生存'),
  current('当前生活'),
  ideal('理想生活');

  final String label;

  const FreedomCostKind(this.label);
}

/// 被动收入覆盖率当前处于哪种状态。
enum FreedomCoverageState {
  available,
  noAnnualizedRate,
  negativeAnnualizedRate,
  noCurrentCost,
  noAssets,
}

/// 一档月成本对应的自由天数。
class FreedomDayEntry {
  final FreedomCostKind kind;
  final Decimal? monthlyCost;

  /// 向下取整的天数；null 表示无法计算。
  final int? days;

  /// days / 365，仅用于展示。
  final double? years;

  /// 仅「当前生活」行使用的被动收入覆盖率，百分数。
  final double? coverage;

  const FreedomDayEntry({
    required this.kind,
    required this.monthlyCost,
    required this.days,
    required this.years,
    this.coverage,
  });
}

/// 自由天数与被动收入覆盖率的完整快照。
class FreedomDaysSnapshot {
  final Decimal asset;
  final bool usesNetAssets;
  final List<FreedomDayEntry> entries;
  final double? annualizedRate;
  final Decimal? monthlyPassiveIncome;
  final FreedomCoverageState coverageState;

  const FreedomDaysSnapshot({
    required this.asset,
    required this.usesNetAssets,
    required this.entries,
    required this.annualizedRate,
    required this.monthlyPassiveIncome,
    required this.coverageState,
  });
}
