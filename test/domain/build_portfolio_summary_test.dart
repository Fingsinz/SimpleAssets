import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/domain/usecases/build_portfolio_summary.dart';

AssetHolding _holding({
  required int id,
  required String categoryId,
  required String quantity,
  required String costPrice,
  String? currentPrice,
}) {
  final now = DateTime.now();
  return AssetHolding(
    id: id,
    categoryId: categoryId,
    categoryName: categoryId == 'fund' ? '基金' : '股票',
    name: '资产$id',
    quantity: Decimal.parse(quantity),
    costPrice: Decimal.parse(costPrice),
    currentPrice: currentPrice == null ? null : Decimal.parse(currentPrice),
    purchaseDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('BuildPortfolioSummary', () {
    test('空列表返回空总览', () {
      final summary = BuildPortfolioSummary.build(const []);

      expect(summary.isEmpty, isTrue);
      expect(summary.allocations, isEmpty);
    });

    test('汇总成本、市值、盈亏与品类占比', () {
      final summary = BuildPortfolioSummary.build([
        _holding(
          id: 1,
          categoryId: 'fund',
          quantity: '100',
          costPrice: '10',
          currentPrice: '12',
        ),
        _holding(
          id: 2,
          categoryId: 'stock',
          quantity: '10',
          costPrice: '50',
          currentPrice: '40',
        ),
      ]);

      // 基金：成本 1000，市值 1200；股票：成本 500，市值 400。
      expect(summary.totalCost, Decimal.parse('1500'));
      expect(summary.totalMarketValue, Decimal.parse('1600'));
      expect(summary.totalProfit, Decimal.parse('100'));
      expect(summary.totalReturnRate, closeTo(6.6667, 0.001));
      expect(summary.allocations, hasLength(2));
      // 按市值降序：基金 1200 > 股票 400
      expect(summary.allocations.first.categoryId, 'fund');
      expect(summary.allocations.first.percentage, closeTo(75, 0.001));
      expect(summary.allocations.last.percentage, closeTo(25, 0.001));
    });

    test('缺少现价时以成本计入市值', () {
      final summary = BuildPortfolioSummary.build([
        _holding(
          id: 1,
          categoryId: 'fund',
          quantity: '100',
          costPrice: '10',
        ),
        _holding(
          id: 2,
          categoryId: 'stock',
          quantity: '10',
          costPrice: '50',
          currentPrice: '60',
        ),
      ]);

      expect(summary.totalMarketValue, Decimal.parse('1600'));
      expect(summary.totalProfit, Decimal.parse('100'));
    });
  });
}
