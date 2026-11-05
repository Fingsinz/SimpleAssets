import 'package:decimal/decimal.dart';

import '../entities/asset_transaction.dart';

/// 交易流水校验失败。
class TransactionValidationException implements Exception {
  final String message;

  const TransactionValidationException(this.message);

  @override
  String toString() => message;
}

/// 一个持仓在某个时点的重放结果。
class HoldingPosition {
  final Decimal quantity;

  /// 毛成本均价：移动加权平均，用于无现价时的估值兜底与已实现收益计算，
  /// 不作为对外的成本单价。
  final Decimal averageCost;

  /// 摊薄成本单价 = (累计买入投入 − 累计卖出回金) / 剩余数量。
  ///
  /// 清仓后归零，再买入重新起算。卖出手续费计入回金扣减，分红不计入。
  final Decimal costPrice;

  final Decimal realizedProfit;
  final Decimal totalBuy;
  final Decimal totalSell;
  final Decimal totalDividends;
  final Decimal totalFees;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const HoldingPosition({
    required this.quantity,
    required this.averageCost,
    required this.costPrice,
    required this.realizedProfit,
    required this.totalBuy,
    required this.totalSell,
    required this.totalDividends,
    required this.totalFees,
    this.firstDate,
    this.lastDate,
  });

  static HoldingPosition empty() => HoldingPosition(
        quantity: Decimal.zero,
        averageCost: Decimal.zero,
        costPrice: Decimal.zero,
        realizedProfit: Decimal.zero,
        totalBuy: Decimal.zero,
        totalSell: Decimal.zero,
        totalDividends: Decimal.zero,
        totalFees: Decimal.zero,
      );
}

/// 可增量推进的重放状态。
///
/// 校验规则集中在这里，`replaySorted` 与 [ReplayCursor] 共用同一套逻辑。
class _ReplayState {
  Decimal quantity = Decimal.zero;
  Decimal averageCost = Decimal.zero;
  // 净投入：累计买入（含费用）− 累计卖出净所得。卖出时摊薄到剩余数量。
  Decimal netCost = Decimal.zero;
  Decimal realizedProfit = Decimal.zero;
  Decimal totalBuy = Decimal.zero;
  Decimal totalSell = Decimal.zero;
  Decimal totalDividends = Decimal.zero;
  Decimal totalFees = Decimal.zero;

  void apply(AssetTransaction transaction) {
    final fee = transaction.feeValue;
    if (fee < Decimal.zero) {
      throw const TransactionValidationException('手续费不能为负数');
    }

    switch (transaction.type) {
      case TransactionType.buy:
        final buyQuantity = transaction.quantity;
        final price = transaction.price;
        if (buyQuantity == null || buyQuantity <= Decimal.zero) {
          throw const TransactionValidationException('买入数量必须大于 0');
        }
        if (price == null || price < Decimal.zero) {
          throw const TransactionValidationException('买入单价不能为负数');
        }
        final gross = buyQuantity * price;
        final cost = gross + fee;
        averageCost = ((quantity * averageCost + cost) /
                (quantity + buyQuantity))
            .toDecimal(scaleOnInfinitePrecision: 20);
        quantity += buyQuantity;
        netCost += cost;
        totalBuy += cost;
        totalFees += fee;
        break;
      case TransactionType.sell:
        final sellQuantity = transaction.quantity;
        final price = transaction.price;
        if (sellQuantity == null || sellQuantity <= Decimal.zero) {
          throw const TransactionValidationException('卖出数量必须大于 0');
        }
        if (price == null || price <= Decimal.zero) {
          throw const TransactionValidationException('卖出单价必须大于 0');
        }
        if (sellQuantity > quantity) {
          throw const TransactionValidationException('卖出数量超过该日期持有数量');
        }
        final gross = sellQuantity * price;
        if (fee >= gross) {
          throw const TransactionValidationException('卖出手续费必须小于成交金额');
        }
        final net = gross - fee;
        realizedProfit += net - averageCost * sellQuantity;
        quantity -= sellQuantity;
        netCost -= net;
        totalSell += net;
        totalFees += fee;
        if (quantity == Decimal.zero) {
          averageCost = Decimal.zero;
          netCost = Decimal.zero;
        }
        break;
      case TransactionType.dividend:
        final amount = transaction.amount;
        if (amount == null || amount <= Decimal.zero) {
          throw const TransactionValidationException('分红金额必须大于 0');
        }
        if (fee >= amount) {
          throw const TransactionValidationException('分红手续费必须小于分红金额');
        }
        totalDividends += amount - fee;
        totalFees += fee;
        break;
      case TransactionType.split:
        final ratio = transaction.ratio;
        if (ratio == null || ratio <= Decimal.zero || ratio == Decimal.one) {
          throw const TransactionValidationException(
            '折算比例必须大于 0 且不等于 1',
          );
        }
        if (quantity <= Decimal.zero) {
          throw const TransactionValidationException('折算时没有持仓');
        }
        averageCost =
            (averageCost / ratio).toDecimal(scaleOnInfinitePrecision: 20);
        quantity *= ratio;
        break;
    }
  }

  HoldingPosition toPosition({
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return HoldingPosition(
      quantity: quantity,
      averageCost: averageCost,
      costPrice: quantity > Decimal.zero
          ? (netCost / quantity).toDecimal(scaleOnInfinitePrecision: 20)
          : Decimal.zero,
      realizedProfit: realizedProfit,
      totalBuy: totalBuy,
      totalSell: totalSell,
      totalDividends: totalDividends,
      totalFees: totalFees,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
}

/// 按日期升序增量重放流水。
///
/// 逐月估值时复用同一个游标：日期前进只应用新增流水，日期回退才从头重放。
/// 避免每个估值点都从第一笔流水开始累积（估值点数 × 流水数 → 流水数）。
class ReplayCursor {
  final List<AssetTransaction> _sorted;
  _ReplayState _state = _ReplayState();
  int _index = 0;
  int? _cutoff;

  ReplayCursor(this._sorted);

  /// 应用到 [date]（含）为止的流水。
  void seek(DateTime date) {
    final cutoff = ReplayTransactions._dayKey(date);
    if (_cutoff != null && cutoff < _cutoff!) {
      _state = _ReplayState();
      _index = 0;
    }
    _cutoff = cutoff;
    while (_index < _sorted.length &&
        ReplayTransactions._dayKey(_sorted[_index].date) <= cutoff) {
      _state.apply(_sorted[_index]);
      _index++;
    }
  }

  Decimal get quantity => _state.quantity;
  Decimal get averageCost => _state.averageCost;
}

/// 按 (date, id) 升序重放一个持仓的全部流水。
class ReplayTransactions {
  ReplayTransactions._();

  static HoldingPosition replay(List<AssetTransaction> transactions) {
    if (transactions.isEmpty) return HoldingPosition.empty();

    final sorted = List<AssetTransaction>.from(transactions)
      ..sort((a, b) {
        final byDate = _dayKey(a.date).compareTo(_dayKey(b.date));
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });
    return replaySorted(sorted);
  }

  /// 假定 [sorted] 已按 (date, id) 升序，避免重复估值时反复排序。
  static HoldingPosition replaySorted(List<AssetTransaction> sorted) {
    if (sorted.isEmpty) return HoldingPosition.empty();

    final state = _ReplayState();
    for (final transaction in sorted) {
      state.apply(transaction);
    }
    return state.toPosition(
      firstDate: sorted.first.date,
      lastDate: sorted.last.date,
    );
  }

  static HoldingPosition replayUntil(
    List<AssetTransaction> transactions,
    DateTime date,
  ) {
    final cutoff = _dayKey(date);
    final filtered = transactions
        .where((transaction) => _dayKey(transaction.date) <= cutoff)
        .toList();
    return replay(filtered);
  }

  /// [sorted] 已按 (date, id) 升序，只重放截止日及之前的流水。
  static HoldingPosition replayUntilSorted(
    List<AssetTransaction> sorted,
    DateTime date,
  ) {
    final cutoff = _dayKey(date);
    final state = _ReplayState();
    DateTime? firstDate;
    DateTime? lastDate;
    for (final transaction in sorted) {
      if (_dayKey(transaction.date) > cutoff) break;
      state.apply(transaction);
      firstDate ??= transaction.date;
      lastDate = transaction.date;
    }
    final first = firstDate;
    final last = lastDate;
    if (first == null || last == null) return HoldingPosition.empty();
    return state.toPosition(firstDate: first, lastDate: last);
  }

  /// (fromExclusive, toInclusive] 内所有折算比例的乘积。
  static Decimal cumulativeSplitFactor(
    List<AssetTransaction> transactions,
    DateTime fromExclusive,
    DateTime toInclusive,
  ) {
    final splits = <AssetTransaction>[
      for (final transaction in transactions)
        if (transaction.type == TransactionType.split) transaction,
    ];
    return cumulativeSplitFactorFromSplits(
      splits,
      fromExclusive,
      toInclusive,
    );
  }

  /// [splits] 只包含折算流水，避免每次估值扫描全部流水。
  static Decimal cumulativeSplitFactorFromSplits(
    List<AssetTransaction> splits,
    DateTime fromExclusive,
    DateTime toInclusive,
  ) {
    final from = _dayKey(fromExclusive);
    final to = _dayKey(toInclusive);
    var factor = Decimal.one;
    for (final transaction in splits) {
      final day = _dayKey(transaction.date);
      if (day > from && day <= to) {
        final ratio = transaction.ratio;
        if (ratio != null && ratio > Decimal.zero) {
          factor *= ratio;
        }
      }
    }
    return factor;
  }

  /// 以整数日键比较日期，避免每次比较都分配 DateTime。
  static int _dayKey(DateTime value) =>
      value.year * 10000 + value.month * 100 + value.day;
}
