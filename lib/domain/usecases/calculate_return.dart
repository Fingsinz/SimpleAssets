import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../entities/asset_holding.dart';
import '../entities/return_result.dart';

/// 纯函数收益计算，无 Flutter 依赖，方便单元测试。
class CalculateReturn {
  const CalculateReturn();

  ReturnResult call(AssetHolding holding) => calculate(holding);

  static ReturnResult calculate(AssetHolding holding) {
    final totalCost = holding.costValue;
    final totalInvested = holding.investedCost;
    final firstDate = holding.firstTransactionDate ?? holding.purchaseDate;
    final days = DateTime.now().difference(firstDate).inDays;

    double? annualizedFor(double rate) {
      if (holding.isCash || days <= 0) return null;
      final base = 1 + rate / 100;
      if (base <= 0) return null;
      return ((math.pow(base, 365 / days) - 1) * 100).toDouble();
    }

    // 没有流水统计、也没有现价：保持旧行为，按成本计价、收益为 0。
    if (!holding.hasCurrentPrice && holding.totalBuy == null) {
      return ReturnResult(
        totalCost: totalCost,
        totalInvested: totalInvested,
        currentValue: totalCost,
        profit: Decimal.zero,
        returnRate: 0,
        hasPrice: false,
        realizedProfit: holding.realized,
        totalDividends: holding.totalDividends,
        totalFees: holding.totalFees,
      );
    }

    final currentValue = holding.effectiveValue;
    final profit = holding.profit;
    final returnRate = holding.returnRate;

    return ReturnResult(
      totalCost: totalCost,
      totalInvested: totalInvested,
      currentValue: currentValue,
      profit: profit,
      returnRate: returnRate,
      annualizedRate: annualizedFor(returnRate),
      hasPrice: holding.hasCurrentPrice,
      realizedProfit: holding.realized,
      totalDividends: holding.totalDividends,
      totalFees: holding.totalFees,
    );
  }
}
