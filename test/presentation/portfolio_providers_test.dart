import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/presentation/providers/asset_providers.dart';
import 'package:simple_assets/presentation/providers/portfolio_providers.dart';

AssetHolding _holding({
  required int id,
  required String categoryId,
  Decimal? amount,
  Decimal? currentPrice,
}) {
  final now = DateTime.now();
  final isCash = categoryId == 'cash';
  return AssetHolding(
    id: id,
    categoryId: categoryId,
    name: '资产$id',
    amount: amount,
    quantity: isCash ? Decimal.zero : Decimal.one,
    costPrice: isCash ? Decimal.zero : Decimal.ten,
    currentPrice: currentPrice,
    purchaseDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('stalePriceCountProvider 排除现金', () async {
    final cash = _holding(
      id: 1,
      categoryId: 'cash',
      amount: Decimal.parse('5000'),
    );
    final fundWithoutPrice = _holding(id: 2, categoryId: 'fund');
    final fundWithPrice = _holding(
      id: 3,
      categoryId: 'fund',
      currentPrice: Decimal.parse('2'),
    );

    final container = ProviderContainer(
      overrides: [
        allHoldingsProvider.overrideWith(
          (ref) => Stream.value([cash, fundWithoutPrice, fundWithPrice]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(allHoldingsProvider.future);

    expect(container.read(stalePriceCountProvider), 1);
  });
}
