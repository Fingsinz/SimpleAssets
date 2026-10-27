import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/domain/usecases/calculate_return.dart';

AssetHolding _holding({
  required String quantity,
  required String costPrice,
  String? currentPrice,
  DateTime? purchaseDate,
}) {
  final now = DateTime.now();
  return AssetHolding(
    id: 1,
    categoryId: 'fund',
    name: '测试基金',
    quantity: Decimal.parse(quantity),
    costPrice: Decimal.parse(costPrice),
    currentPrice: currentPrice == null ? null : Decimal.parse(currentPrice),
    purchaseDate: purchaseDate ?? now.subtract(const Duration(days: 365)),
    createdAt: now,
    updatedAt: now,
  );
}

AssetHolding _cashHolding({required String amount}) {
  final now = DateTime.now();
  return AssetHolding(
    id: 99,
    categoryId: 'cash',
    name: '招商银行',
    quantity: Decimal.zero,
    costPrice: Decimal.zero,
    amount: Decimal.parse(amount),
    purchaseDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

AssetHolding _holdingWithStats({
  String quantity = '100',
  String costPrice = '10',
  String? currentPrice,
  String? totalBuy,
  String? totalSell,
  String? totalDividends,
  String? totalFees,
  String? realizedProfit,
  DateTime? purchaseDate,
  DateTime? firstTransactionDate,
}) {
  final now = DateTime.now();
  return AssetHolding(
    id: 1,
    categoryId: 'fund',
    name: '测试基金',
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
    firstTransactionDate: firstTransactionDate,
    purchaseDate: purchaseDate ?? now.subtract(const Duration(days: 365)),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CalculateReturn', () {
    test('有现价时计算成本、市值、盈亏与收益率', () {
      final result = CalculateReturn.calculate(
        _holding(quantity: '100', costPrice: '10', currentPrice: '12'),
      );

      expect(result.hasPrice, isTrue);
      expect(result.totalCost, Decimal.parse('1000'));
      expect(result.currentValue, Decimal.parse('1200'));
      expect(result.profit, Decimal.parse('200'));
      expect(result.returnRate, closeTo(20.0, 0.0001));
    });

    test('无现价时按成本计算市值且盈亏为 0', () {
      final result = CalculateReturn.calculate(
        _holding(quantity: '50', costPrice: '2.5'),
      );

      expect(result.hasPrice, isFalse);
      expect(result.totalCost, Decimal.parse('125'));
      expect(result.currentValue, Decimal.parse('125'));
      expect(result.profit, Decimal.zero);
      expect(result.returnRate, 0);
    });

    test('亏损时收益率为负', () {
      final result = CalculateReturn.calculate(
        _holding(quantity: '10', costPrice: '100', currentPrice: '80'),
      );

      expect(result.profit, Decimal.parse('-200'));
      expect(result.returnRate, closeTo(-20.0, 0.0001));
    });

    test('成本为 0 时收益率不出现除零', () {
      final result = CalculateReturn.calculate(
        _holding(quantity: '10', costPrice: '0', currentPrice: '5'),
      );

      expect(result.returnRate, 0);
      expect(result.profit, Decimal.parse('50'));
    });

    test('年化收益率在持有满一年时接近普通收益率', () {
      final result = CalculateReturn.calculate(
        _holding(
          quantity: '1',
          costPrice: '100',
          currentPrice: '110',
          purchaseDate: DateTime.now().subtract(const Duration(days: 365)),
        ),
      );

      expect(result.annualizedRate, isNotNull);
      expect(result.annualizedRate!, closeTo(10.0, 0.2));
    });

    test('现金按金额计入市值且无收益', () {
      final result = CalculateReturn.calculate(_cashHolding(amount: '5000'));

      expect(result.hasPrice, isFalse);
      expect(result.totalCost, Decimal.parse('5000'));
      expect(result.currentValue, Decimal.parse('5000'));
      expect(result.profit, Decimal.zero);
      expect(result.returnRate, 0);
      expect(result.annualizedRate, isNull);
    });

    test('部分卖出后累计收益包含已实现收益', () {
      final result = CalculateReturn.calculate(
        _holdingWithStats(
          quantity: '50',
          costPrice: '10',
          currentPrice: '12',
          totalBuy: '1000',
          totalSell: '500',
          totalDividends: '20',
          realizedProfit: '100',
        ),
      );

      expect(result.totalCost, Decimal.parse('500'));
      expect(result.totalInvested, Decimal.parse('1000'));
      expect(result.currentValue, Decimal.parse('600'));
      expect(result.profit, Decimal.parse('120'));
      expect(result.returnRate, closeTo(12, 0.0001));
      expect(result.realizedProfit, Decimal.parse('100'));
    });

    test('清仓后累计收益不为零', () {
      final result = CalculateReturn.calculate(
        _holdingWithStats(
          quantity: '0',
          costPrice: '0',
          totalBuy: '1000',
          totalSell: '1200',
          totalDividends: '0',
          realizedProfit: '200',
          firstTransactionDate:
              DateTime.now().subtract(const Duration(days: 730)),
        ),
      );

      expect(result.currentValue, Decimal.zero);
      expect(result.profit, Decimal.parse('200'));
      expect(result.returnRate, closeTo(20, 0.0001));
      expect(result.annualizedRate, isNotNull);
    });

    test('手续费降低累计收益', () {
      final result = CalculateReturn.calculate(
        _holdingWithStats(
          currentPrice: '12',
          totalBuy: '1010',
          totalSell: '0',
          totalDividends: '0',
          totalFees: '10',
        ),
      );

      expect(result.totalInvested, Decimal.parse('1010'));
      expect(result.profit, Decimal.parse('190'));
      expect(result.totalFees, Decimal.parse('10'));
    });
  });
}
