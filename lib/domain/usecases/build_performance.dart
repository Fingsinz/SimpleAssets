import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../entities/asset_transaction.dart';
import '../entities/cash_record.dart';
import '../entities/performance.dart';
import '../entities/price_point.dart';
import 'valuate_portfolio.dart';

/// 一段相邻估值点之间的收益。
class _Interval {
  final ValuationPoint end;
  final Decimal gain;
  final Decimal buys;
  final Decimal startValue;
  final double? direct;
  final double? r;
  final double drawdown;
  final bool estimated;

  const _Interval({
    required this.end,
    required this.gain,
    required this.buys,
    required this.startValue,
    required this.direct,
    required this.r,
    required this.drawdown,
    required this.estimated,
  });
}

/// 把估值序列聚合成月度、年度、记录以来与年历。
class BuildPerformance {
  const BuildPerformance();

  PerformanceResult call({
    required List<HoldingPerformanceInput> holdings,
    required List<PricePoint> priceHistory,
    required List<CashRecord> cashRecords,
    required bool includeCash,
    required DateTime today,
  }) =>
      build(
        holdings: holdings,
        priceHistory: priceHistory,
        cashRecords: cashRecords,
        includeCash: includeCash,
        today: today,
      );

  static PerformanceResult build({
    required List<HoldingPerformanceInput> holdings,
    required List<PricePoint> priceHistory,
    required List<CashRecord> cashRecords,
    required bool includeCash,
    required DateTime today,
  }) {
    final allTransactions = <AssetTransaction>[
      for (final input in holdings) ...input.transactions,
    ];
    final nonCashTransactions = <AssetTransaction>[
      for (final input in holdings)
        if (!input.holding.isCash) ...input.transactions,
    ];
    if (nonCashTransactions.isEmpty) return PerformanceResult.empty();

    final todayDay = _day(today);
    final firstDate = nonCashTransactions
        .map((transaction) => _day(transaction.date))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    if (firstDate.isAfter(todayDay)) return PerformanceResult.empty();

    final startDate = firstDate.subtract(const Duration(days: 1));
    final points = <ValuationPoint>[
      ValuationPoint(
        date: startDate,
        label: '起始',
        value: Decimal.zero,
        estimated: false,
        isStart: true,
      ),
    ];

    var cursor = DateTime(firstDate.year, firstDate.month, 1);
    final currentMonthStart = DateTime(todayDay.year, todayDay.month, 1);
    while (!cursor.isAfter(currentMonthStart)) {
      final isCurrentMonth =
          cursor.year == todayDay.year && cursor.month == todayDay.month;
      final pointDate = isCurrentMonth
          ? todayDay
          : DateTime(cursor.year, cursor.month + 1, 0);
      if (!pointDate.isBefore(firstDate)) {
        final valuation = ValuatePortfolio.at(
          holdings: holdings,
          priceHistory: priceHistory,
          cashRecords: cashRecords,
          includeCash: includeCash,
          date: pointDate,
        );
        points.add(
          ValuationPoint(
            date: pointDate,
            label: _monthKey(pointDate),
            value: valuation.value,
            estimated: valuation.estimated,
          ),
        );
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    final intervals = <_Interval>[];
    double? twrIndex;
    var drawdownIndex = 1.0;
    var peak = 1.0;

    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final end = points[i];
      final isFirst = i == 1;

      var cf = Decimal.zero;
      var div = Decimal.zero;
      var buys = Decimal.zero;
      for (final transaction in nonCashTransactions) {
        final date = _day(transaction.date);
        final inRange = isFirst
            ? !date.isBefore(prev.date) && !date.isAfter(end.date)
            : date.isAfter(prev.date) && !date.isAfter(end.date);
        if (!inRange) continue;

        switch (transaction.type) {
          case TransactionType.buy:
            final gross = (transaction.quantity ?? Decimal.zero) *
                (transaction.price ?? Decimal.zero);
            final cost = gross + transaction.feeValue;
            cf += cost;
            buys += cost;
            break;
          case TransactionType.sell:
            final gross = (transaction.quantity ?? Decimal.zero) *
                (transaction.price ?? Decimal.zero);
            cf -= gross - transaction.feeValue;
            break;
          case TransactionType.dividend:
            div += (transaction.amount ?? Decimal.zero) - transaction.feeValue;
            break;
          case TransactionType.split:
            break;
        }
      }

      final deltaCash = includeCash
          ? ValuatePortfolio.cashValueAt(
                holdings: holdings,
                cashRecords: cashRecords,
                date: end.date,
              ) -
              ValuatePortfolio.cashValueAt(
                holdings: holdings,
                cashRecords: cashRecords,
                date: prev.date,
              )
          : Decimal.zero;

      final gain = end.value - prev.value - cf - deltaCash + div;
      final double? r =
          prev.value > Decimal.zero ? (gain / prev.value).toDouble() : null;
      final double? direct = r != null
          ? r * 100
          : (buys > Decimal.zero ? (gain / buys).toDouble() * 100 : null);

      if (r != null) {
        twrIndex = (twrIndex ?? 1) * (1 + r);
      }

      final factor = r != null
          ? 1 + r
          : (isFirst && direct != null ? 1 + direct / 100 : 1.0);
      drawdownIndex *= factor;
      if (drawdownIndex > peak) peak = drawdownIndex;
      final drawdown = (drawdownIndex / peak - 1) * 100;

      intervals.add(
        _Interval(
          end: end,
          gain: gain,
          buys: buys,
          startValue: prev.value,
          direct: direct,
          r: r,
          drawdown: drawdown,
          estimated: end.estimated,
        ),
      );
    }

    final months = <PeriodicPerformance>[
      for (final interval in intervals)
        PeriodicPerformance(
          key: _monthKey(interval.end.date),
          label: _monthKey(interval.end.date),
          gain: interval.gain,
          directReturnRate: interval.direct,
          annualizedRate: _annualizeMonthly(interval.direct),
          twrRate: interval.r == null ? null : interval.r! * 100,
          maxDrawdown:
              interval.direct == null ? null : math.min(0.0, interval.direct!),
          estimated: interval.estimated,
        ),
    ];

    final years = <PeriodicPerformance>[];
    final intervalsByYear = <int, List<_Interval>>{};
    for (final interval in intervals) {
      (intervalsByYear[interval.end.date.year] ??= []).add(interval);
    }
    for (final entry in intervalsByYear.entries) {
      years.add(_buildYear(entry.key, entry.value, todayDay));
    }
    years.sort((a, b) => a.key.compareTo(b.key));

    final sinceInception = _buildSinceInception(
      allTransactions: allTransactions,
      intervals: intervals,
      points: points,
      cashToday: includeCash
          ? ValuatePortfolio.cashValueAt(
              holdings: holdings,
              cashRecords: cashRecords,
              date: todayDay,
            )
          : Decimal.zero,
      twrIndex: twrIndex,
      firstDate: firstDate,
      today: todayDay,
    );

    final monthsByKey = {for (final month in months) month.key: month};
    final yearsByKey = {for (final year in years) year.key: year};
    final calendar = <CalendarYearPerformance>[];
    for (var year = firstDate.year; year <= todayDay.year; year++) {
      final cells = <CalendarMonthPerformance>[
        for (var month = 1; month <= 12; month++)
          CalendarMonthPerformance(
            month: month,
            returnRate:
                monthsByKey['$year-${month.toString().padLeft(2, '0')}']
                    ?.directReturnRate,
            estimated:
                monthsByKey['$year-${month.toString().padLeft(2, '0')}']
                    ?.estimated ??
                false,
          ),
      ];
      calendar.add(
        CalendarYearPerformance(
          year: year,
          months: cells,
          annualReturnRate: yearsByKey['$year']?.directReturnRate,
        ),
      );
    }

    return PerformanceResult(
      points: points,
      months: months,
      years: years,
      sinceInception: sinceInception,
      calendar: calendar,
      hasEstimatedMonths: months.any((month) => month.estimated),
    );
  }

  static PeriodicPerformance _buildYear(
    int year,
    List<_Interval> intervals,
    DateTime today,
  ) {
    final totalGain = intervals.fold(
      Decimal.zero,
      (sum, interval) => sum + interval.gain,
    );
    final totalBuys = intervals.fold(
      Decimal.zero,
      (sum, interval) => sum + interval.buys,
    );
    final startValue = intervals.first.startValue;
    final direct = startValue > Decimal.zero
        ? (totalGain / startValue).toDouble() * 100
        : (totalBuys > Decimal.zero
            ? (totalGain / totalBuys).toDouble() * 100
            : null);

    double? product;
    for (final interval in intervals) {
      if (interval.r != null) {
        product = (product ?? 1) * (1 + interval.r!);
      }
    }
    final twr = product == null ? null : (product - 1) * 100;

    final drawdowns = intervals.map((interval) => interval.drawdown);
    final maxDrawdown = drawdowns.reduce((a, b) => a < b ? a : b);

    double? annualized = direct;
    if (year == today.year && direct != null) {
      final days = today.difference(DateTime(year, 1, 1)).inDays + 1;
      final base = 1 + direct / 100;
      if (days > 0 && base > 0) {
        annualized =
            ((math.pow(base, 365 / days) - 1) * 100).toDouble();
      } else {
        annualized = null;
      }
    }

    return PeriodicPerformance(
      key: '$year',
      label: '$year',
      gain: totalGain,
      directReturnRate: direct,
      annualizedRate: annualized,
      twrRate: twr,
      maxDrawdown: maxDrawdown,
      estimated: intervals.any((interval) => interval.estimated),
    );
  }

  static PeriodicPerformance _buildSinceInception({
    required List<AssetTransaction> allTransactions,
    required List<_Interval> intervals,
    required List<ValuationPoint> points,
    required Decimal cashToday,
    required double? twrIndex,
    required DateTime firstDate,
    required DateTime today,
  }) {
    var totalBuy = Decimal.zero;
    var totalSell = Decimal.zero;
    var totalDividends = Decimal.zero;
    for (final transaction in allTransactions) {
      switch (transaction.type) {
        case TransactionType.buy:
          totalBuy += (transaction.quantity ?? Decimal.zero) *
                  (transaction.price ?? Decimal.zero) +
              transaction.feeValue;
          break;
        case TransactionType.sell:
          totalSell += (transaction.quantity ?? Decimal.zero) *
                  (transaction.price ?? Decimal.zero) -
              transaction.feeValue;
          break;
        case TransactionType.dividend:
          totalDividends +=
              (transaction.amount ?? Decimal.zero) - transaction.feeValue;
          break;
        case TransactionType.split:
          break;
      }
    }

    final nonCashValue = points.isEmpty
        ? Decimal.zero
        : points.last.value - cashToday;
    final totalProfit = nonCashValue + totalSell + totalDividends - totalBuy;
    final investedBase = totalBuy + cashToday;
    final double? direct = investedBase > Decimal.zero
        ? (totalProfit / investedBase).toDouble() * 100
        : null;

    final drawdowns = intervals.map((interval) => interval.drawdown);
    final maxDrawdown =
        intervals.isEmpty ? null : drawdowns.reduce((a, b) => a < b ? a : b);

    double? annualized;
    if (direct != null) {
      final days = today.difference(firstDate).inDays;
      final base = 1 + direct / 100;
      if (days > 0 && base > 0) {
        annualized =
            ((math.pow(base, 365 / days) - 1) * 100).toDouble();
      }
    }

    return PeriodicPerformance(
      key: 'all',
      label: '记录以来',
      gain: totalProfit,
      directReturnRate: direct,
      annualizedRate: annualized,
      twrRate: twrIndex == null ? null : (twrIndex - 1) * 100,
      maxDrawdown: maxDrawdown,
      estimated: intervals.any((interval) => interval.estimated),
    );
  }

  static double? _annualizeMonthly(double? rate) {
    if (rate == null) return null;
    final base = 1 + rate / 100;
    if (base <= 0) return null;
    return ((math.pow(base, 12) - 1) * 100).toDouble();
  }

  static String _monthKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
