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

AssetHolding _holdingWithStats({
  int id = 1,
  String categoryId = 'fund',
  String quantity = '50',
  String costPrice = '10',
  String? currentPrice = '12',
  String? totalBuy = '1000',
  String? totalSell = '500',
  String? totalDividends = '20',
  String? totalFees,
  String? realizedProfit,
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
    totalBuy: totalBuy == null ? null : Decimal.parse(totalBuy),
    totalSell: totalSell == null ? null : Decimal.parse(totalSell),
    totalDividends:
        totalDividends == null ? null : Decimal.parse(totalDividends),
    totalFees: totalFees == null ? null : Decimal.parse(totalFees),
    realizedProfit:
        realizedProfit == null ? null : Decimal.parse(realizedProfit),
    purchaseDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

AssetHolding _cash({String amount = '5000'}) {
  final now = DateTime.now();
  return AssetHolding(
    id: 99,
    categoryId: 'cash',
    categoryName: '现金',
    name: '现金',
    amount: Decimal.parse(amount),
    quantity: Decimal.zero,
    costPrice: Decimal.zero,
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

    test('总投入使用累计买入且部分卖出后不下降', () {
      final summary = BuildPortfolioSummary.build([_holdingWithStats()]);

      expect(summary.totalInvested, Decimal.parse('1000'));
      expect(summary.totalCost, Decimal.parse('500'));
      expect(summary.totalMarketValue, Decimal.parse('600'));
      expect(summary.totalProfit, Decimal.parse('120'));
      expect(summary.totalReturnRate, closeTo(12.0, 0.0001));
      expect(summary.allocations.single.totalInvested, Decimal.parse('1000'));
    });

    test('默认排除现金，includeCash 时计入', () {
      final holdings = [_cash(), _holdingWithStats()];

      final without = BuildPortfolioSummary.build(holdings);
      final withCash = BuildPortfolioSummary.build(
        holdings,
        includeCash: true,
      );

      expect(without.totalInvested, Decimal.parse('1000'));
      expect(without.totalMarketValue, Decimal.parse('600'));
      expect(withCash.totalInvested, Decimal.parse('6000'));
      expect(withCash.totalMarketValue, Decimal.parse('5600'));
      expect(withCash.totalProfit, without.totalProfit);
    });
  });
}
