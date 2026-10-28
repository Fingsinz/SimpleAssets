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
import 'package:simple_assets/presentation/providers/settings_providers.dart';

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

class _CountingPriceRepository implements PriceRepository {
  final int updated;
  int calls = 0;

  _CountingPriceRepository({this.updated = 1});

  @override
  Future<Result<Decimal>> fetchPrice({
    required String categoryId,
    required String code,
  }) async => Result.failure('测试不使用单条查询');

  @override
  Future<PriceRefreshReport> refreshAll(List<AssetHolding> holdings) async {
    calls++;
    return PriceRefreshReport(updated: updated);
  }
}

class _FixedSettingsNotifier extends SettingsNotifier {
  final AppSettings settings;
  int markCalls = 0;

  _FixedSettingsNotifier(this.settings);

  @override
  Future<AppSettings> build() async => settings;

  @override
  Future<void> markRefreshed() async {
    markCalls++;
  }
}

Future<ProviderContainer> _refreshContainer({
  required PriceRepository repository,
  required AppSettings settings,
}) async {
  final container = ProviderContainer(
    overrides: [
      allHoldingsProvider.overrideWith((ref) => Stream.value([_holding()])),
      refreshPricesProvider.overrideWithValue(RefreshPrices(repository)),
      settingsProvider.overrideWith(() => _FixedSettingsNotifier(settings)),
    ],
  );
  await container.read(allHoldingsProvider.future);
  await container.read(settingsProvider.future);
  return container;
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
        settingsProvider.overrideWith(
          () => _FixedSettingsNotifier(const AppSettings(autoRefresh: true)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(allHoldingsProvider.future);
    await container.read(settingsProvider.future);

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

  test('距上次刷新不足 2 小时时跳过刷新', () async {
    final repository = _CountingPriceRepository();
    final container = await _refreshContainer(
      repository: repository,
      settings: AppSettings(
        autoRefresh: true,
        lastRefreshAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    );
    addTearDown(container.dispose);

    final report =
        await container.read(priceRefreshProvider.notifier).refreshAll();

    expect(repository.calls, 0);
    expect(report.throttled, isTrue);
    expect(report.message, contains('2 小时'));
  });

  test('距上次刷新超过 2 小时后执行刷新', () async {
    final repository = _CountingPriceRepository();
    final container = await _refreshContainer(
      repository: repository,
      settings: AppSettings(
        autoRefresh: true,
        lastRefreshAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    );
    addTearDown(container.dispose);

    final report =
        await container.read(priceRefreshProvider.notifier).refreshAll();

    expect(repository.calls, 1);
    expect(report.throttled, isFalse);
    expect(report.updated, 1);
  });

  test('从未刷新过时直接执行，更新到价格才记录刷新时间', () async {
    final repository = _CountingPriceRepository();
    final container = await _refreshContainer(
      repository: repository,
      settings: const AppSettings(autoRefresh: true),
    );
    addTearDown(container.dispose);

    await container.read(priceRefreshProvider.notifier).refreshAll();

    expect(repository.calls, 1);
    final notifier =
        container.read(settingsProvider.notifier) as _FixedSettingsNotifier;
    expect(notifier.markCalls, 1);
  });

  test('没有更新到价格时不记录刷新时间', () async {
    final repository = _CountingPriceRepository(updated: 0);
    final container = await _refreshContainer(
      repository: repository,
      settings: const AppSettings(autoRefresh: true),
    );
    addTearDown(container.dispose);

    await container.read(priceRefreshProvider.notifier).refreshAll();

    expect(repository.calls, 1);
    final notifier =
        container.read(settingsProvider.notifier) as _FixedSettingsNotifier;
    expect(notifier.markCalls, 0);
  });
}
