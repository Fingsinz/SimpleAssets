import 'package:decimal/decimal.dart';

import '../entities/asset_holding.dart';
import '../entities/portfolio_summary.dart';

/// 由持仓列表计算组合总览（纯函数）。
class BuildPortfolioSummary {
  const BuildPortfolioSummary();

  PortfolioSummary call(
    List<AssetHolding> holdings, {
    bool includeAmountBasedInValue = false,
  }) =>
      build(
        holdings,
        includeAmountBasedInValue: includeAmountBasedInValue,
      );

  /// [includeAmountBasedInValue] 为 true 时用于总览：
  /// 市值合计与品类配置包含现金、负债与自定义产品；
  /// 为 false 时用于分析：只统计理财产品。
  ///
  /// 无论哪种口径，总投入 / 累计收益 / 收益率都只统计理财产品。
  static PortfolioSummary build(
    List<AssetHolding> holdings, {
    bool includeAmountBasedInValue = false,
  }) {
    final investments =
        holdings.where((holding) => holding.isInvestment).toList();
    final visible =
        includeAmountBasedInValue ? holdings : investments;
    if (visible.isEmpty) return PortfolioSummary.empty();

    var totalCost = Decimal.zero;
    var totalInvested = Decimal.zero;
    var totalMarketValue = Decimal.zero;
    var totalProfit = Decimal.zero;
    final values = <String, Decimal>{};
    final invested = <String, Decimal>{};
    final profits = <String, Decimal>{};
    final names = <String, String>{};

    for (final holding in investments) {
      totalCost += holding.costValue;
      totalInvested += holding.investedCost;
      totalProfit += holding.profit;
    }

    for (final holding in visible) {
      totalMarketValue += holding.effectiveValue;

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

    // 百分比统一以正资产合计为分母；负债等负值品类记 0，图表显示「—」。
    final positiveTotal = values.values
        .where((value) => value > Decimal.zero)
        .fold(Decimal.zero, (sum, value) => sum + value);

    final allocations = <CategoryAllocation>[];
    for (final entry in values.entries) {
      final marketValue = entry.value;
      final categoryInvested = invested[entry.key] ?? Decimal.zero;
      final categoryProfit = profits[entry.key] ?? Decimal.zero;
      if (marketValue == Decimal.zero && categoryInvested == Decimal.zero) {
        continue;
      }
      final percentage =
          marketValue > Decimal.zero && positiveTotal > Decimal.zero
              ? ((marketValue * Decimal.fromInt(100)) / positiveTotal)
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
