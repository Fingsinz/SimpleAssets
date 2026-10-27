import 'package:decimal/decimal.dart';

/// 一个估值点（月末或今天）。
class ValuationPoint {
  final DateTime date;
  final String label;
  final Decimal value;
  final bool estimated;
  final bool isStart;

  /// 截至该点的累计 TWR 指数（1.0 起）；首月或无效区间为 null。
  final double? twrIndex;

  /// 截至该点的回撤（负数百分数）。
  final double? drawdown;

  const ValuationPoint({
    required this.date,
    required this.label,
    required this.value,
    required this.estimated,
    this.isStart = false,
    this.twrIndex,
    this.drawdown,
  });
}

/// 某个月、某一年或记录以来的收益与回撤。
class PeriodicPerformance {
  final String key;
  final String label;
  final Decimal gain;
  final double? directReturnRate;
  final double? annualizedRate;
  final double? twrRate;
  final double? maxDrawdown;
  final bool estimated;

  const PeriodicPerformance({
    required this.key,
    required this.label,
    required this.gain,
    this.directReturnRate,
    this.annualizedRate,
    this.twrRate,
    this.maxDrawdown,
    this.estimated = false,
  });
}

class CalendarMonthPerformance {
  final int month;
  final double? returnRate;
  final bool estimated;

  const CalendarMonthPerformance({
    required this.month,
    this.returnRate,
    this.estimated = false,
  });
}

class CalendarYearPerformance {
  final int year;
  final List<CalendarMonthPerformance> months;
  final double? annualReturnRate;

  const CalendarYearPerformance({
    required this.year,
    required this.months,
    this.annualReturnRate,
  });
}

/// 收益细节的完整计算结果。
class PerformanceResult {
  final List<ValuationPoint> points;
  final List<PeriodicPerformance> months;
  final List<PeriodicPerformance> years;
  final PeriodicPerformance? sinceInception;
  final List<CalendarYearPerformance> calendar;
  final bool hasEstimatedMonths;

  const PerformanceResult({
    required this.points,
    required this.months,
    required this.years,
    required this.sinceInception,
    required this.calendar,
    required this.hasEstimatedMonths,
  });

  static PerformanceResult empty() => const PerformanceResult(
        points: [],
        months: [],
        years: [],
        sinceInception: null,
        calendar: [],
        hasEstimatedMonths: false,
      );
}
