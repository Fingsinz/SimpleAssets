import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_summary.freezed.dart';

/// 组合总览。
@freezed
abstract class PortfolioSummary with _$PortfolioSummary {
  const PortfolioSummary._();

  const factory PortfolioSummary({
    required Decimal totalCost,
    required Decimal totalMarketValue,
    required Decimal totalProfit,
    required double totalReturnRate,
    required List<CategoryAllocation> allocations,
  }) = _PortfolioSummary;

  static PortfolioSummary empty() => PortfolioSummary(
        totalCost: Decimal.zero,
        totalMarketValue: Decimal.zero,
        totalProfit: Decimal.zero,
        totalReturnRate: 0,
        allocations: const [],
      );

  bool get isEmpty => totalMarketValue == Decimal.zero && totalCost == Decimal.zero;
}

/// 品类配置占比。
@freezed
abstract class CategoryAllocation with _$CategoryAllocation {
  const CategoryAllocation._();

  const factory CategoryAllocation({
    required String categoryId,
    required String categoryName,
    required Decimal marketValue,
    required double percentage,
    required Decimal profit,
    required double returnRate,
  }) = _CategoryAllocation;
}
