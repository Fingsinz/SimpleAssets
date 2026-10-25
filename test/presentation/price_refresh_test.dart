import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/core/result.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/domain/repositories/price_repository.dart';
import 'package:simple_assets/domain/usecases/refresh_prices.dart';
import 'package:simple_assets/presentation/providers/asset_providers.dart';
import 'package:simple_assets/presentation/providers/price_providers.dart';

class _GatePriceRepository implements PriceRepository {
  final completer = Completer<PriceRefreshReport>();
  int calls = 0;

  @override
  Future<Result<Decimal>> fetchPrice({
    required String categoryId,
    required String code,
  }) async => Result.failure('测试不使用单条查询');

  @override
  Future<PriceRefreshReport> refreshAll(List<AssetHolding> holdings) {
    calls++;
    return completer.future;
  }
}

AssetHolding _holding() {
  final now = DateTime.now();
  return AssetHolding(
    id: 1,
    categoryId: 'fund',
    name: '测试基金',
    code: '000001',
    quantity: Decimal.parse('100'),
    costPrice: Decimal.parse('10'),
    purchaseDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('并发刷新只执行一次，结束后可再次刷新', () async {
    final repository = _GatePriceRepository();
    final container = ProviderContainer(
      overrides: [
        allHoldingsProvider.overrideWith((ref) => Stream.value([_holding()])),
        refreshPricesProvider.overrideWithValue(RefreshPrices(repository)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(allHoldingsProvider.future);

    final notifier = container.read(priceRefreshProvider.notifier);
    final first = notifier.refreshAll();
    final second = notifier.refreshAll();

    expect(repository.calls, 1);

    repository.completer.complete(const PriceRefreshReport(updated: 0));
    await Future.wait([first, second]);

    final third = notifier.refreshAll();
    await third;
    expect(repository.calls, 2);
  });
}
