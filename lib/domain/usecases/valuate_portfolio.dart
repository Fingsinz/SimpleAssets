import 'package:decimal/decimal.dart';

import '../entities/asset_holding.dart';
import '../entities/asset_transaction.dart';
import '../entities/cash_record.dart';
import '../entities/price_point.dart';
import 'replay_transactions.dart';

/// 估值所需的单个持仓输入。
class HoldingPerformanceInput {
  final AssetHolding holding;
  final List<AssetTransaction> transactions;

  const HoldingPerformanceInput({
    required this.holding,
    required this.transactions,
  });
}

/// 某个日期上的组合估值。
class PortfolioValuation {
  final DateTime date;
  final Decimal value;
  final bool estimated;

  const PortfolioValuation({
    required this.date,
    required this.value,
    required this.estimated,
  });
}

/// 按历史价格与流水重放出某个日期的组合市值。
class ValuatePortfolio {
  ValuatePortfolio._();

  static PortfolioValuation at({
    required List<HoldingPerformanceInput> holdings,
    required List<PricePoint> priceHistory,
    required List<CashRecord> cashRecords,
    required bool includeCash,
    required DateTime date,
  }) {
    var value = Decimal.zero;
    var estimated = false;

    for (final input in holdings) {
      if (input.holding.isCash) continue;
      final position = ReplayTransactions.replayUntil(
        input.transactions,
        date,
      );
      if (position.quantity <= Decimal.zero) continue;

      final price = priceAt(
        holding: input,
        history: priceHistory,
        date: date,
      );
      if (price == null) {
        value += position.quantity * position.averageCost;
        estimated = true;
      } else {
        value += position.quantity * price;
      }
    }

    if (includeCash) {
      value += cashValueAt(
        holdings: holdings,
        cashRecords: cashRecords,
        date: date,
      );
    }

    return PortfolioValuation(
      date: date,
      value: value,
      estimated: estimated,
    );
  }

  static Decimal? priceAt({
    required HoldingPerformanceInput holding,
    required List<PricePoint> history,
    required DateTime date,
  }) {
    final cutoff = _day(date);
    PricePoint? latest;
    for (final point in history) {
      if (point.holdingId != holding.holding.id) continue;
      if (_day(point.observedAt).isAfter(cutoff)) continue;
      if (latest == null || !point.observedAt.isBefore(latest.observedAt)) {
        latest = point;
      }
    }
    if (latest == null) return null;

    final factor = ReplayTransactions.cumulativeSplitFactor(
      holding.transactions,
      latest.observedAt,
      date,
    );
    if (factor == Decimal.one || factor <= Decimal.zero) {
      return latest.price;
    }
    return (latest.price / factor).toDecimal(scaleOnInfinitePrecision: 20);
  }

  static Decimal cashValueAt({
    required List<HoldingPerformanceInput> holdings,
    required List<CashRecord> cashRecords,
    required DateTime date,
  }) {
    final cutoff = _day(date);
    var total = Decimal.zero;
    for (final input in holdings) {
      if (!input.holding.isCash) continue;
      CashRecord? latest;
      for (final record in cashRecords) {
        if (record.holdingId != input.holding.id) continue;
        if (_day(record.recordDate).isAfter(cutoff)) continue;
        if (latest == null ||
            record.recordDate.isAfter(latest.recordDate) ||
            (record.recordDate == latest.recordDate && record.id > latest.id)) {
          latest = record;
        }
      }
      if (latest != null) total += latest.amount;
    }
    return total;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
