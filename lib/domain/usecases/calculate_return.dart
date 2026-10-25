import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../entities/asset_holding.dart';
import '../entities/return_result.dart';

/// 纯函数收益计算，无 Flutter 依赖，方便单元测试。
class CalculateReturn {
  const CalculateReturn();

  ReturnResult call(AssetHolding holding) => calculate(holding);

  static ReturnResult calculate(AssetHolding holding) {
    final costValue = holding.costPrice * holding.quantity;
    if (!holding.hasCurrentPrice) {
      return ReturnResult(
        totalCost: costValue,
        currentValue: costValue,
        profit: Decimal.zero,
        returnRate: 0,
        hasPrice: false,
      );
    }

    final currentValue = holding.currentPrice! * holding.quantity;
    final profit = currentValue - costValue;
    final returnRate = costValue > Decimal.zero
        ? ((profit * Decimal.fromInt(100)) / costValue).toDouble()
        : 0.0;

    final holdingDays = holding.holdingDays;
    double? annualizedRate;
    if (holdingDays > 0) {
      final base = 1 + returnRate / 100;
      if (base > 0) {
        annualizedRate =
            ((math.pow(base, 365 / holdingDays) - 1) * 100).toDouble();
      }
    }

    return ReturnResult(
      totalCost: costValue,
      currentValue: currentValue,
      profit: profit,
      returnRate: returnRate,
      annualizedRate: annualizedRate,
      hasPrice: true,
    );
  }
}
