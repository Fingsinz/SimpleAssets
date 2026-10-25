import 'package:decimal/decimal.dart';

import '../entities/asset_holding.dart';
import '../entities/portfolio_summary.dart';

/// 由持仓列表计算组合总览（纯函数）。
class BuildPortfolioSummary {
  const BuildPortfolioSummary();

  PortfolioSummary call(List<AssetHolding> holdings) => build(holdings);

  static PortfolioSummary build(List<AssetHolding> holdings) {
    if (holdings.isEmpty) return PortfolioSummary.empty();

    var totalCost = Decimal.zero;
    var totalMarketValue = Decimal.zero;
    final values = <String, Decimal>{};
    final costs = <String, Decimal>{};
    final names = <String, String>{};

    for (final holding in holdings) {
      totalCost += holding.costValue;
      totalMarketValue += holding.effectiveValue;
      values[holding.categoryId] =
          (values[holding.categoryId] ?? Decimal.zero) + holding.effectiveValue;
      costs[holding.categoryId] =
          (costs[holding.categoryId] ?? Decimal.zero) + holding.costValue;
      names[holding.categoryId] =
          holding.categoryName ?? holding.categoryId;
    }

    final totalProfit = totalMarketValue - totalCost;
    final totalReturnRate = totalCost > Decimal.zero
        ? ((totalProfit * Decimal.fromInt(100)) / totalCost).toDouble()
        : 0.0;

    final allocations = <CategoryAllocation>[];
    for (final entry in values.entries) {
      final marketValue = entry.value;
      final cost = costs[entry.key] ?? Decimal.zero;
      final profit = marketValue - cost;
      final percentage = totalMarketValue > Decimal.zero
          ? ((marketValue * Decimal.fromInt(100)) / totalMarketValue)
              .toDouble()
          : 0.0;
      final rate = cost > Decimal.zero
          ? ((profit * Decimal.fromInt(100)) / cost).toDouble()
          : 0.0;
      allocations.add(CategoryAllocation(
        categoryId: entry.key,
        categoryName: names[entry.key] ?? entry.key,
        marketValue: marketValue,
        percentage: percentage,
        profit: profit,
        returnRate: rate,
      ));
    }

    allocations.sort((a, b) => b.marketValue.compareTo(a.marketValue));

    return PortfolioSummary(
      totalCost: totalCost,
      totalMarketValue: totalMarketValue,
      totalProfit: totalProfit,
      totalReturnRate: totalReturnRate,
      allocations: allocations,
    );
  }
}
