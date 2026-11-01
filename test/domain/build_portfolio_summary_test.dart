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

AssetHolding _liability({String amount = '-3000'}) {
  final now = DateTime.now();
  return AssetHolding(
    id: 100,
    categoryId: 'liability',
    categoryName: '负债',
    name: '信用卡',
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

    List<AssetHolding> allAssets() => [
          _holding(
            id: 1,
            categoryId: 'fund',
            quantity: '100',
            costPrice: '10',
            currentPrice: '12',
          ),
          _cash(),
          _liability(),
        ];

    test('总览口径包含现金与负债', () {
      final summary = BuildPortfolioSummary.build(
        allAssets(),
        includeAmountBasedInValue: true,
      );

      expect(summary.totalMarketValue, Decimal.parse('3200'));
      expect(summary.totalInvested, Decimal.parse('1000'));
      expect(summary.totalCost, Decimal.parse('1000'));
      expect(summary.totalProfit, Decimal.parse('200'));
      expect(summary.allocations, hasLength(3));
    });

    test('负债的百分比为 0，正资产百分比以正资产合计为分母', () {
      final summary = BuildPortfolioSummary.build(
        allAssets(),
        includeAmountBasedInValue: true,
      );
      final byId = {
        for (final allocation in summary.allocations)
          allocation.categoryId: allocation,
      };

      expect(byId['fund']!.percentage, closeTo(19.3548, 0.001));
      expect(byId['cash']!.percentage, closeTo(80.6452, 0.001));
      expect(byId['liability']!.percentage, 0);
      expect(byId['liability']!.marketValue, Decimal.parse('-3000'));
    });

    test('分析口径排除现金与负债', () {
      final summary = BuildPortfolioSummary.build(allAssets());

      expect(summary.totalMarketValue, Decimal.parse('1200'));
      expect(summary.totalInvested, Decimal.parse('1000'));
      expect(summary.totalProfit, Decimal.parse('200'));
      expect(summary.allocations.single.categoryId, 'fund');
    });
  });
}
