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
  Decimal? quantity,
}) {
  final now = DateTime.now();
  final isAmountBased = categoryId == 'cash' ||
      categoryId == 'liability' ||
      categoryId == 'custom';
  return AssetHolding(
    id: id,
    categoryId: categoryId,
    name: '资产$id',
    amount: amount,
    quantity: quantity ?? (isAmountBased ? Decimal.zero : Decimal.one),
    costPrice: isAmountBased ? Decimal.zero : Decimal.ten,
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

  test('stalePriceCountProvider 排除负债与自定义产品', () async {
    final liability = _holding(
      id: 1,
      categoryId: 'liability',
      amount: Decimal.parse('-3000'),
    );
    final custom = _holding(
      id: 2,
      categoryId: 'custom',
      amount: Decimal.parse('5000'),
    );
    final staleFund = _holding(id: 3, categoryId: 'fund');

    final container = ProviderContainer(
      overrides: [
        allHoldingsProvider.overrideWith(
          (ref) => Stream.value([liability, custom, staleFund]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(allHoldingsProvider.future);

    expect(container.read(stalePriceCountProvider), 1);
  });

  test('overviewSummaryProvider 的总资产包含现金与负债', () async {
    final cash = _holding(
      id: 1,
      categoryId: 'cash',
      amount: Decimal.parse('5000'),
    );
    final liability = _holding(
      id: 2,
      categoryId: 'liability',
      amount: Decimal.parse('-3000'),
    );
    final fund = _holding(
      id: 3,
      categoryId: 'fund',
      quantity: Decimal.parse('100'),
      currentPrice: Decimal.parse('12'),
    );

    final container = ProviderContainer(
      overrides: [
        allHoldingsProvider.overrideWith(
          (ref) => Stream.value([cash, liability, fund]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(allHoldingsProvider.future);

    final overview = container.read(overviewSummaryProvider);
    expect(overview.totalMarketValue, Decimal.parse('3200'));
    expect(overview.totalAssets, Decimal.parse('6200'));
    expect(overview.netAssets, Decimal.parse('3200'));
    expect(overview.totalInvested, Decimal.parse('1000'));
    expect(overview.totalProfit, Decimal.parse('200'));
    expect(
      overview.allocations.map((allocation) => allocation.categoryId),
      containsAll(['cash', 'liability', 'fund']),
    );
  });

  test('analysisSummaryProvider 只统计理财产品', () async {
    final cash = _holding(
      id: 1,
      categoryId: 'cash',
      amount: Decimal.parse('5000'),
    );
    final liability = _holding(
      id: 2,
      categoryId: 'liability',
      amount: Decimal.parse('-3000'),
    );
    final fund = _holding(
      id: 3,
      categoryId: 'fund',
      quantity: Decimal.parse('100'),
      currentPrice: Decimal.parse('12'),
    );

    final container = ProviderContainer(
      overrides: [
        allHoldingsProvider.overrideWith(
          (ref) => Stream.value([cash, liability, fund]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(allHoldingsProvider.future);

    final analysis = container.read(analysisSummaryProvider);
    expect(analysis.totalMarketValue, Decimal.parse('1200'));
    expect(analysis.totalInvested, Decimal.parse('1000'));
    expect(analysis.totalProfit, Decimal.parse('200'));
    expect(
      analysis.allocations.map((allocation) => allocation.categoryId),
      ['fund'],
    );
  });
}
