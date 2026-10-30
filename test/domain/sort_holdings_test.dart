import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/domain/usecases/sort_holdings.dart';

AssetHolding _holding({
  required int id,
  required String name,
  String categoryId = 'fund',
  String? code,
  String value = '1000',
}) {
  final timestamp = DateTime(2025, 1, 1);
  if (categoryId == 'cash') {
    return AssetHolding(
      id: id,
      categoryId: categoryId,
      name: name,
      quantity: Decimal.zero,
      costPrice: Decimal.zero,
      amount: Decimal.parse(value),
      purchaseDate: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
  return AssetHolding(
    id: id,
    categoryId: categoryId,
    name: name,
    code: code,
    quantity: Decimal.one,
    costPrice: Decimal.parse(value),
    purchaseDate: timestamp,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

List<String> _names(List<AssetHolding> holdings) =>
    holdings.map((holding) => holding.name).toList();

void main() {
  group('SortHoldings', () {
    test('默认按市值降序', () {
      final sorted = SortHoldings.apply([
        _holding(id: 1, name: '小', value: '1000'),
        _holding(id: 2, name: '大', value: '3000'),
        _holding(id: 3, name: '中', value: '2000'),
      ], HoldingSortMode.amount);

      expect(_names(sorted), ['大', '中', '小']);
    });

    test('品类排序固定为股票、ETF、基金、债券、贵金属、现金', () {
      final sorted = SortHoldings.apply([
        _holding(id: 1, name: '现金', categoryId: 'cash', value: '10'),
        _holding(id: 2, name: '贵金属', categoryId: 'gold', value: '20'),
        _holding(id: 3, name: '债券', categoryId: 'bond', value: '30'),
        _holding(id: 4, name: '基金', categoryId: 'fund', value: '40'),
        _holding(id: 5, name: 'ETF', categoryId: 'etf', value: '50'),
        _holding(id: 6, name: '股票', categoryId: 'stock', value: '60'),
      ], HoldingSortMode.category);

      expect(_names(sorted), ['股票', 'ETF', '基金', '债券', '贵金属', '现金']);
    });

    test('同一品类内按市值降序', () {
      final sorted = SortHoldings.apply([
        _holding(id: 1, name: '股票小', categoryId: 'stock', value: '500'),
        _holding(id: 2, name: '大基金', categoryId: 'fund', value: '9000'),
        _holding(id: 3, name: '股票大', categoryId: 'stock', value: '800'),
      ], HoldingSortMode.category);

      expect(_names(sorted), ['股票大', '股票小', '大基金']);
    });

    test('未知品类排在全部已知品类之后', () {
      final sorted = SortHoldings.apply([
        _holding(id: 1, name: '未知', categoryId: 'crypto', value: '9999'),
        _holding(id: 2, name: '现金', categoryId: 'cash', value: '10'),
        _holding(id: 3, name: '股票', categoryId: 'stock', value: '20'),
      ], HoldingSortMode.category);

      expect(_names(sorted), ['股票', '现金', '未知']);
    });

    test('市值相同时按名称升序保持稳定', () {
      final sorted = SortHoldings.apply([
        _holding(id: 1, name: 'B', value: '1000'),
        _holding(id: 2, name: 'A', value: '1000'),
      ], HoldingSortMode.amount);

      expect(_names(sorted), ['A', 'B']);
    });
  });
}
