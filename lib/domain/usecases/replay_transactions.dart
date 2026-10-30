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

/// 按 (date, id) 升序重放一个持仓的全部流水。
class ReplayTransactions {
  ReplayTransactions._();

  static HoldingPosition replay(List<AssetTransaction> transactions) {
    if (transactions.isEmpty) return HoldingPosition.empty();

    final sorted = List<AssetTransaction>.from(transactions)
      ..sort((a, b) {
        final byDate = _day(a.date).compareTo(_day(b.date));
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });

    var quantity = Decimal.zero;
    var averageCost = Decimal.zero;
    // 净投入：累计买入（含费用）− 累计卖出净所得。卖出时摊薄到剩余数量。
    var netCost = Decimal.zero;
    var realizedProfit = Decimal.zero;
    var totalBuy = Decimal.zero;
    var totalSell = Decimal.zero;
    var totalDividends = Decimal.zero;
    var totalFees = Decimal.zero;

    for (final transaction in sorted) {
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
      firstDate: sorted.first.date,
      lastDate: sorted.last.date,
    );
  }

  static HoldingPosition replayUntil(
    List<AssetTransaction> transactions,
    DateTime date,
  ) {
    final cutoff = _day(date);
    final filtered = transactions
        .where((transaction) => !_day(transaction.date).isAfter(cutoff))
        .toList();
    return replay(filtered);
  }

  /// (fromExclusive, toInclusive] 内所有折算比例的乘积。
  static Decimal cumulativeSplitFactor(
    List<AssetTransaction> transactions,
    DateTime fromExclusive,
    DateTime toInclusive,
  ) {
    final from = _day(fromExclusive);
    final to = _day(toInclusive);
    var factor = Decimal.one;
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.split) continue;
      final day = _day(transaction.date);
      if (day.isAfter(from) && !day.isAfter(to)) {
        final ratio = transaction.ratio;
        if (ratio != null && ratio > Decimal.zero) {
          factor *= ratio;
        }
      }
    }
    return factor;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
