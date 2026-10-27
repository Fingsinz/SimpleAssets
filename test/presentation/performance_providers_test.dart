import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/entities/cash_record.dart';
import 'package:simple_assets/domain/entities/price_point.dart';
import 'package:simple_assets/presentation/providers/asset_providers.dart';
import 'package:simple_assets/presentation/providers/performance_providers.dart';
import 'package:simple_assets/presentation/providers/settings_providers.dart';
import 'package:simple_assets/presentation/providers/transaction_providers.dart';

AssetHolding _fund() {
  final now = DateTime(2026, 9, 1);
  return AssetHolding(
    id: 1,
    categoryId: 'fund',
    name: '测试基金',
    quantity: Decimal.parse('100'),
    costPrice: Decimal.parse('10'),
    purchaseDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

AssetTransaction _buy() => AssetTransaction(
      id: 1,
      holdingId: 1,
      type: TransactionType.buy,
      quantity: Decimal.parse('100'),
      price: Decimal.parse('10'),
      date: DateTime(2026, 9, 1),
    );

PricePoint _price() => PricePoint(
      holdingId: 1,
      period: '2026-09',
      price: Decimal.parse('12'),
      observedAt: DateTime(2026, 9, 30),
    );

void main() {
  test('performanceResultProvider 汇总持仓、流水与价格历史', () async {
    final container = ProviderContainer(
      overrides: [
        allHoldingsProvider.overrideWith((ref) => Stream.value([_fund()])),
        allTransactionsProvider.overrideWith(
          (ref) => Stream.value([_buy()]),
        ),
        priceHistoryProvider.overrideWith(
          (ref) => Stream.value([_price()]),
        ),
        allCashRecordsProvider.overrideWith(
          (ref) => Stream.value(const <CashRecord>[]),
        ),
        includeCashInStatsProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await container.read(allHoldingsProvider.future);
    await container.read(allTransactionsProvider.future);
    await container.read(priceHistoryProvider.future);
    await container.read(allCashRecordsProvider.future);

    final result = container.read(performanceResultProvider);
    expect(result.valueOrNull, isNotNull);
    expect(result.valueOrNull!.months, isNotEmpty);
    expect(result.valueOrNull!.sinceInception, isNotNull);
  });
}
