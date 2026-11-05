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

/// 预索引后的组合估值器。
///
/// 流水、价格与余额记录只在 [ValuatePortfolio.prepare] 时排序一次；
/// 之后每个估值点用二分查找取价格 / 最新余额，避免逐月重复排序与全表扫描。
class PortfolioValuator {
  final List<_PreparedHolding> _holdings;

  const PortfolioValuator._(this._holdings);

  PortfolioValuation at(DateTime date) {
    var value = Decimal.zero;
    var estimated = false;

    for (final prepared in _holdings) {
      final holdingValue = prepared.valuate(date);
      if (holdingValue == null) continue;
      value += holdingValue.value;
      if (holdingValue.estimated) estimated = true;
    }

    return PortfolioValuation(
      date: date,
      value: value,
      estimated: estimated,
    );
  }
}

class _PreparedHoldingValue {
  final Decimal value;
  final bool estimated;

  const _PreparedHoldingValue(this.value, this.estimated);
}

class _PreparedHolding {
  final AssetHolding holding;
  final List<AssetTransaction> transactions;
  final List<AssetTransaction> splits;
  final List<PricePoint> prices;
  final List<BalanceRecord> balances;

  /// 价格 / 余额记录预先算好整数日键，二分查找时不再分配 DateTime。
  final List<int> priceDays;
  final List<int> balanceDays;

  /// 逐月估值复用同一个游标，只为新增流水付出重放成本。
  final ReplayCursor replay;

  _PreparedHolding({
    required this.holding,
    required this.transactions,
    required this.splits,
    required this.prices,
    required this.balances,
    required this.priceDays,
    required this.balanceDays,
  }) : replay = ReplayCursor(transactions);

  _PreparedHoldingValue? valuate(DateTime date) {
    if (holding.isCustom) {
      final record = _latestBalance(date);
      if (record == null) return null;
      return _PreparedHoldingValue(record.amount, false);
    }

    replay.seek(date);
    final quantity = replay.quantity;
    if (quantity <= Decimal.zero) return null;

    final price = _priceAt(date);
    if (price == null) {
      return _PreparedHoldingValue(quantity * replay.averageCost, true);
    }
    return _PreparedHoldingValue(quantity * price, false);
  }

  PricePoint? _latestPrice(DateTime date) {
    final index = _upperBound(priceDays, _dayKey(date));
    return index == 0 ? null : prices[index - 1];
  }

  Decimal? _priceAt(DateTime date) {
    final latest = _latestPrice(date);
    if (latest == null) return null;

    final factor = ReplayTransactions.cumulativeSplitFactorFromSplits(
      splits,
      latest.observedAt,
      date,
    );
    if (factor == Decimal.one || factor <= Decimal.zero) {
      return latest.price;
    }
    return (latest.price / factor).toDecimal(scaleOnInfinitePrecision: 20);
  }

  BalanceRecord? _latestBalance(DateTime date) {
    final index = _upperBound(balanceDays, _dayKey(date));
    return index == 0 ? null : balances[index - 1];
  }

  /// 返回第一个日键大于 [cutoff] 的下标；前面的元素都 ≤ 目标日期。
  static int _upperBound(List<int> days, int cutoff) {
    var low = 0;
    var high = days.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (days[mid] > cutoff) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return low;
  }
}

/// 按历史价格、流水与余额记录重放出某个日期的组合市值。
///
/// 现金与负债不参与分析；自定义产品取该日期前最新一条余额记录的持有金额。
class ValuatePortfolio {
  ValuatePortfolio._();

  /// 一次性估值（内部会构建索引）。需要逐月估值时请先 [prepare]。
  static PortfolioValuation at({
    required List<HoldingPerformanceInput> holdings,
    required List<PricePoint> priceHistory,
    required List<BalanceRecord> balanceRecords,
    required DateTime date,
  }) {
    return prepare(
      holdings: holdings,
      priceHistory: priceHistory,
      balanceRecords: balanceRecords,
    ).at(date);
  }

  /// 预处理流水、价格与余额记录，供多个估值点复用。
  static PortfolioValuator prepare({
    required List<HoldingPerformanceInput> holdings,
    required List<PricePoint> priceHistory,
    required List<BalanceRecord> balanceRecords,
  }) {
    final pricesByHolding = <int, List<PricePoint>>{};
    for (final point in priceHistory) {
      (pricesByHolding[point.holdingId] ??= []).add(point);
    }
    final balancesByHolding = <int, List<BalanceRecord>>{};
    for (final record in balanceRecords) {
      (balancesByHolding[record.holdingId] ??= []).add(record);
    }

    final prepared = <_PreparedHolding>[];
    for (final input in holdings) {
      if (input.holding.isCashLike) continue;
      final sortedTransactions = _sortTransactions(input.transactions);
      final sortedPrices =
          _sortPrices(pricesByHolding[input.holding.id] ?? const []);
      final sortedBalances =
          _sortBalances(balancesByHolding[input.holding.id] ?? const []);
      prepared.add(
        _PreparedHolding(
          holding: input.holding,
          transactions: sortedTransactions,
          splits: [
            for (final transaction in sortedTransactions)
              if (transaction.type == TransactionType.split) transaction,
          ],
          prices: sortedPrices,
          balances: sortedBalances,
          priceDays: [
            for (final point in sortedPrices) _dayKey(point.observedAt),
          ],
          balanceDays: [
            for (final record in sortedBalances) _dayKey(record.recordDate),
          ],
        ),
      );
    }
    return PortfolioValuator._(prepared);
  }

  static List<AssetTransaction> _sortTransactions(
    List<AssetTransaction> transactions,
  ) {
    final sorted = List<AssetTransaction>.from(transactions)
      ..sort((a, b) {
        final byDate = _dayKey(a.date).compareTo(_dayKey(b.date));
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    return sorted;
  }

  static List<PricePoint> _sortPrices(List<PricePoint> prices) {
    // 同一天的价格保持输入顺序：与原线性扫描「后者覆盖前者」一致。
    final indexed = prices.asMap().entries.toList()
      ..sort((a, b) {
        final byDate = _dayKey(a.value.observedAt)
            .compareTo(_dayKey(b.value.observedAt));
        return byDate != 0 ? byDate : a.key.compareTo(b.key);
      });
    return [for (final entry in indexed) entry.value];
  }

  static List<BalanceRecord> _sortBalances(List<BalanceRecord> records) {
    final sorted = List<BalanceRecord>.from(records)
      ..sort((a, b) {
        final byDate = _dayKey(a.recordDate)
            .compareTo(_dayKey(b.recordDate));
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    return sorted;
  }
}

/// 以整数日键比较日期，避免每次比较都分配 DateTime。
int _dayKey(DateTime value) =>
    value.year * 10000 + value.month * 100 + value.day;
