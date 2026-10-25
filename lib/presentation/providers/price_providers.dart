import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/datasources/fund_price_datasource.dart';
import '../../data/remote/datasources/gold_price_datasource.dart';
import '../../data/remote/datasources/price_datasource_registry.dart';
import '../../data/remote/datasources/stock_price_datasource.dart';
import '../../data/remote/dio_client.dart';
import '../../data/repositories/price_repository_impl.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/repositories/price_repository.dart';
import '../../domain/usecases/refresh_prices.dart';
import 'asset_providers.dart';
import 'database_provider.dart';
import 'settings_providers.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = DioClient.create();
  ref.onDispose(dio.close);
  return dio;
});

/// 新增数据源只需在这里注册。
final priceRegistryProvider = Provider<PriceDataSourceRegistry>((ref) {
  final dio = ref.watch(dioProvider);
  return PriceDataSourceRegistry([
    FundPriceDataSource(dio),
    StockPriceDataSource(dio),
    GoldPriceDataSource(dio),
  ]);
});

final priceRepositoryProvider = Provider<PriceRepository>((ref) {
  return PriceRepositoryImpl(
    registry: ref.watch(priceRegistryProvider),
    snapshotDao: ref.watch(priceSnapshotDaoProvider),
    onPriceFetched: (id, price) =>
        ref.read(assetRepositoryProvider).updateCurrentPrice(id, price),
  );
});

final refreshPricesProvider = Provider<RefreshPrices>(
  (ref) => RefreshPrices(ref.watch(priceRepositoryProvider)),
);

final priceRefreshProvider =
    AsyncNotifierProvider<PriceRefreshNotifier, PriceRefreshReport>(
  PriceRefreshNotifier.new,
);

class PriceRefreshNotifier extends AsyncNotifier<PriceRefreshReport> {
  @override
  Future<PriceRefreshReport> build() async => const PriceRefreshReport();

  /// [silent] 为 true 时不展示 loading（用于启动时的自动刷新）。
  Future<PriceRefreshReport> refreshAll({bool silent = false}) async {
    final holdings =
        ref.read(allHoldingsProvider).valueOrNull ?? const <AssetHolding>[];
    if (holdings.isEmpty) {
      const report = PriceRefreshReport();
      state = const AsyncData(report);
      return report;
    }

    if (!silent) state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(refreshPricesProvider)(holdings),
    );
    state = result;

    final report = result.valueOrNull ?? const PriceRefreshReport();
    if (report.updated > 0) {
      await ref.read(settingsProvider.notifier).markRefreshed();
    }
    return report;
  }
}
