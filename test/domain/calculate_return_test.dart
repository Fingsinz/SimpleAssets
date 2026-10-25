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
  });
}
