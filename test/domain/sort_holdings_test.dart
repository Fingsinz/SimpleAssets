import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/domain/usecases/sort_holdings.dart';

AssetHolding _holding({
  required int id,
  required String categoryId,
  required String name,
  String? amount,
  String quantity = '0',
  String costPrice = '0',
  String? currentPrice,
}) {
  final now = DateTime(2026, 1, 1);
  return AssetHolding(
    id: id,
    categoryId: categoryId,
    name: name,
    amount: amount == null ? null : Decimal.parse(amount),
    quantity: Decimal.parse(quantity),
    costPrice: Decimal.parse(costPrice),
    currentPrice: currentPrice == null ? null : Decimal.parse(currentPrice),
    purchaseDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

List<String> _names(List<AssetHolding> holdings) =>
    [for (final holding in holdings) holding.name];

void main() {
  final cash = _holding(
    id: 1,
    categoryId: 'cash',
    name: '现金',
    amount: '5000',
  );
  final fund = _holding(
    id: 2,
    categoryId: 'fund',
    name: '基金',
    quantity: '100',
    costPrice: '10',
    currentPrice: '12',
  );
  final stock = _holding(
    id: 3,
    categoryId: 'stock',
    name: '股票',
    quantity: '10',
    costPrice: '50',
    currentPrice: '45',
  );
  final liability = _holding(
    id: 4,
    categoryId: 'liability',
    name: '信用卡',
    amount: '-3000',
  );

  test('默认按金额降序，负债排最后', () {
    final sorted = SortHoldings.apply(
      [stock, liability, fund, cash],
      HoldingSortMode.amount,
    );

    expect(_names(sorted), ['现金', '基金', '股票', '信用卡']);
  });

  test('品类排序使用固定品类顺序，品类内按金额降序', () {
    final sorted = SortHoldings.apply(
      [cash, fund, stock, liability],
      HoldingSortMode.category,
    );

    // 股票 → 基金 → 现金 → 负债。
    expect(_names(sorted), ['股票', '基金', '现金', '信用卡']);
  });

  test('金额相同时按名称、再按 id 稳定排序', () {
    final a = _holding(
      id: 10,
      categoryId: 'fund',
      name: 'A基金',
      quantity: '1',
      costPrice: '100',
    );
    final b = _holding(
      id: 11,
      categoryId: 'fund',
      name: 'B基金',
      quantity: '1',
      costPrice: '100',
    );

    final sorted = SortHoldings.apply(
      [b, a],
      HoldingSortMode.amount,
    );
    expect(_names(sorted), ['A基金', 'B基金']);
  });
}
