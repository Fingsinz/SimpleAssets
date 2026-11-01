import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_summary.freezed.dart';

/// 组合总览。
@freezed
abstract class PortfolioSummary with _$PortfolioSummary {
  const PortfolioSummary._();

  const factory PortfolioSummary({
    required Decimal totalCost,
    required Decimal totalInvested,
    required Decimal totalMarketValue,
    /// 总资产：全部资产价值之和，不含负债。
    required Decimal totalAssets,
    /// 净资产：总资产扣除负债后的净值。
    required Decimal netAssets,
    required Decimal totalProfit,
    required double totalReturnRate,
    required List<CategoryAllocation> allocations,
  }) = _PortfolioSummary;

  static PortfolioSummary empty() => PortfolioSummary(
        totalCost: Decimal.zero,
        totalInvested: Decimal.zero,
        totalMarketValue: Decimal.zero,
        totalAssets: Decimal.zero,
        netAssets: Decimal.zero,
        totalProfit: Decimal.zero,
        totalReturnRate: 0,
        allocations: const [],
      );

  bool get isEmpty =>
      totalMarketValue == Decimal.zero && totalInvested == Decimal.zero;
}

/// 品类配置占比。
@freezed
abstract class CategoryAllocation with _$CategoryAllocation {
  const CategoryAllocation._();

  const factory CategoryAllocation({
    required String categoryId,
    required String categoryName,
    required Decimal marketValue,
    required Decimal totalInvested,
    required double percentage,
    required Decimal profit,
    required double returnRate,
  }) = _CategoryAllocation;
}
