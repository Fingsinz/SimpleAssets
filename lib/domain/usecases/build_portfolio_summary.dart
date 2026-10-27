import 'package:decimal/decimal.dart';

import '../entities/asset_holding.dart';
import '../entities/portfolio_summary.dart';

/// 由持仓列表计算组合总览（纯函数）。
class BuildPortfolioSummary {
  const BuildPortfolioSummary();

  PortfolioSummary call(
    List<AssetHolding> holdings, {
    bool includeCash = false,
  }) =>
      build(holdings, includeCash: includeCash);

  static PortfolioSummary build(
    List<AssetHolding> holdings, {
    bool includeCash = false,
  }) {
    final visible = includeCash
        ? holdings
        : holdings.where((holding) => !holding.isCash).toList();
    if (visible.isEmpty) return PortfolioSummary.empty();

    var totalCost = Decimal.zero;
    var totalInvested = Decimal.zero;
    var totalMarketValue = Decimal.zero;
    var totalProfit = Decimal.zero;
    final values = <String, Decimal>{};
    final invested = <String, Decimal>{};
    final profits = <String, Decimal>{};
    final names = <String, String>{};

    for (final holding in visible) {
      totalCost += holding.costValue;
      totalInvested += holding.investedCost;
      totalMarketValue += holding.effectiveValue;
      totalProfit += holding.profit;

      final categoryId = holding.categoryId;
      values[categoryId] =
          (values[categoryId] ?? Decimal.zero) + holding.effectiveValue;
      invested[categoryId] =
          (invested[categoryId] ?? Decimal.zero) + holding.investedCost;
      profits[categoryId] =
          (profits[categoryId] ?? Decimal.zero) + holding.profit;
      names[categoryId] = holding.categoryName ?? categoryId;
    }

    final totalReturnRate = totalInvested > Decimal.zero
        ? ((totalProfit * Decimal.fromInt(100)) / totalInvested).toDouble()
        : 0.0;

    final allocations = <CategoryAllocation>[];
    for (final entry in values.entries) {
      final marketValue = entry.value;
      final categoryInvested = invested[entry.key] ?? Decimal.zero;
      final categoryProfit = profits[entry.key] ?? Decimal.zero;
      if (marketValue == Decimal.zero && categoryInvested == Decimal.zero) {
        continue;
      }
      final percentage = totalMarketValue > Decimal.zero
          ? ((marketValue * Decimal.fromInt(100)) / totalMarketValue)
              .toDouble()
          : 0.0;
      final rate = categoryInvested > Decimal.zero
          ? ((categoryProfit * Decimal.fromInt(100)) / categoryInvested)
              .toDouble()
          : 0.0;
      allocations.add(
        CategoryAllocation(
          categoryId: entry.key,
          categoryName: names[entry.key] ?? entry.key,
          marketValue: marketValue,
          totalInvested: categoryInvested,
          percentage: percentage,
          profit: categoryProfit,
          returnRate: rate,
        ),
      );
    }

    allocations.sort((a, b) => b.marketValue.compareTo(a.marketValue));

    return PortfolioSummary(
      totalCost: totalCost,
      totalInvested: totalInvested,
      totalMarketValue: totalMarketValue,
      totalProfit: totalProfit,
      totalReturnRate: totalReturnRate,
      allocations: allocations,
    );
  }
}
