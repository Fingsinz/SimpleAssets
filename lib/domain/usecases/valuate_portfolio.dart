import 'package:decimal/decimal.dart';

import '../entities/asset_holding.dart';
import '../entities/asset_transaction.dart';
import '../entities/balance_record.dart';
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

/// 按历史价格、流水与余额记录重放出某个日期的组合市值。
///
/// 现金与负债不参与分析；自定义产品取该日期前最新一条余额记录的持有金额。
class ValuatePortfolio {
  ValuatePortfolio._();

  static PortfolioValuation at({
    required List<HoldingPerformanceInput> holdings,
    required List<PricePoint> priceHistory,
    required List<BalanceRecord> balanceRecords,
    required DateTime date,
  }) {
    var value = Decimal.zero;
    var estimated = false;

    for (final input in holdings) {
      final holding = input.holding;
      if (holding.isCashLike) continue;

      if (holding.isCustom) {
        final amount = amountAt(
          holdingId: holding.id,
          records: balanceRecords,
          date: date,
        );
        if (amount != null) value += amount;
        continue;
      }

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

  /// 自定义产品在某个日期之前的持有金额。
  static Decimal? amountAt({
    required int holdingId,
    required List<BalanceRecord> records,
    required DateTime date,
  }) {
    final cutoff = _day(date);
    BalanceRecord? latest;
    for (final record in records) {
      if (record.holdingId != holdingId) continue;
      if (_day(record.recordDate).isAfter(cutoff)) continue;
      if (latest == null ||
          record.recordDate.isAfter(latest.recordDate) ||
          (record.recordDate == latest.recordDate && record.id > latest.id)) {
        latest = record;
      }
    }
    return latest?.amount;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
