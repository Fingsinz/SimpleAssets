import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';

void main() {
  group('AssetHolding 品类语义', () {
    test('现金按金额计市值且不产生收益', () {
      final cash = AssetHolding(
        id: 1,
        categoryId: 'cash',
        name: '招商银行',
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        amount: Decimal.parse('5000'),
        purchaseDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(cash.isCash, isTrue);
      expect(cash.isPreciousMetal, isFalse);
      expect(cash.costValue, Decimal.parse('5000'));
      expect(cash.effectiveValue, Decimal.parse('5000'));
      expect(cash.profit, Decimal.zero);
      expect(cash.returnRate, 0.0);
      expect(cash.hasCurrentPrice, isFalse);
    });

    test('贵金属按单位解析出的数量计算成本与市值', () {
      final gold = AssetHolding(
        id: 2,
        categoryId: 'gold',
        name: '黄金',
        unit: '10克',
        quantity: Decimal.parse('10'),
        costPrice: Decimal.parse('600'),
        currentPrice: Decimal.parse('700'),
        purchaseDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(gold.isPreciousMetal, isTrue);
      expect(gold.isCash, isFalse);
      expect(gold.costValue, Decimal.parse('6000'));
      expect(gold.effectiveValue, Decimal.parse('7000'));
      expect(gold.hasCurrentPrice, isTrue);
    });

    test('有流水统计时 profit 使用累计口径', () {
      final holding = AssetHolding(
        id: 1,
        categoryId: 'fund',
        name: '基金',
        quantity: Decimal.parse('50'),
        costPrice: Decimal.parse('10'),
        currentPrice: Decimal.parse('12'),
        totalBuy: Decimal.parse('1000'),
        totalSell: Decimal.parse('500'),
        totalDividends: Decimal.parse('20'),
        realizedProfit: Decimal.parse('100'),
        purchaseDate: DateTime(2025, 1, 1),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      expect(holding.costValue, Decimal.parse('500'));
      expect(holding.investedCost, Decimal.parse('1000'));
      expect(holding.profit, Decimal.parse('120'));
      expect(holding.returnRate, closeTo(12.0, 0.0001));
    });
  });
}
