import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/presentation/providers/asset_providers.dart';
import 'package:simple_assets/presentation/providers/portfolio_providers.dart';
import 'package:simple_assets/presentation/providers/settings_providers.dart';

AssetHolding _holding({
  required int id,
  required String categoryId,
  Decimal? amount,
  Decimal? currentPrice,
  Decimal? quantity,
}) {
  final now = DateTime.now();
  final isCash = categoryId == 'cash';
  return AssetHolding(
    id: id,
    categoryId: categoryId,
    name: '资产$id',
    amount: amount,
    quantity: quantity ?? (isCash ? Decimal.zero : Decimal.one),
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

  test('stalePriceCountProvider 排除已清仓持仓', () async {
    final cash = _holding(
      id: 1,
      categoryId: 'cash',
      amount: Decimal.parse('5000'),
    );
    final staleFund = _holding(id: 2, categoryId: 'fund');
    final closedFund = _holding(
      id: 3,
      categoryId: 'fund',
      quantity: Decimal.zero,
    );

    final container = ProviderContainer(
      overrides: [
        allHoldingsProvider.overrideWith(
          (ref) => Stream.value([cash, staleFund, closedFund]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(allHoldingsProvider.future);

    expect(container.read(stalePriceCountProvider), 1);
  });

  test('portfolioSummaryProvider 默认排除现金，开启后包含', () async {
    final cash = _holding(
      id: 1,
      categoryId: 'cash',
      amount: Decimal.parse('5000'),
    );
    final fund = _holding(
      id: 2,
      categoryId: 'fund',
      quantity: Decimal.parse('100'),
      currentPrice: Decimal.parse('12'),
    );

    final without = ProviderContainer(
      overrides: [
        allHoldingsProvider.overrideWith(
          (ref) => Stream.value([cash, fund]),
        ),
        includeCashInStatsProvider.overrideWithValue(false),
      ],
    );
    addTearDown(without.dispose);
    await without.read(allHoldingsProvider.future);
    final withoutSummary = without.read(portfolioSummaryProvider);
    expect(withoutSummary.totalInvested, Decimal.parse('1000'));
    expect(withoutSummary.totalMarketValue, Decimal.parse('1200'));

    final withCash = ProviderContainer(
      overrides: [
        allHoldingsProvider.overrideWith(
          (ref) => Stream.value([cash, fund]),
        ),
        includeCashInStatsProvider.overrideWithValue(true),
      ],
    );
    addTearDown(withCash.dispose);
    await withCash.read(allHoldingsProvider.future);
    final withSummary = withCash.read(portfolioSummaryProvider);
    expect(withSummary.totalInvested, Decimal.parse('6000'));
    expect(withSummary.totalMarketValue, Decimal.parse('6200'));
    expect(withSummary.totalProfit, withoutSummary.totalProfit);
  });
}
