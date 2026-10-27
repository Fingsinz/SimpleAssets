import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_transaction.dart';
import '../../domain/entities/cash_record.dart';
import '../../domain/entities/performance.dart';
import '../../domain/entities/price_point.dart';
import '../../domain/usecases/build_performance.dart';
import '../../domain/usecases/valuate_portfolio.dart';
import 'asset_providers.dart';
import 'settings_providers.dart';
import 'transaction_providers.dart';

final priceHistoryProvider = StreamProvider<List<PricePoint>>(
  (ref) => ref.watch(assetRepositoryProvider).watchAllPriceHistory(),
);

final allCashRecordsProvider = StreamProvider<List<CashRecord>>(
  (ref) => ref.watch(assetRepositoryProvider).watchAllCashRecords(),
);

/// 收益细节数据：持仓、流水、价格历史、现金记录与含现金开关的组合。
final performanceResultProvider = Provider<AsyncValue<PerformanceResult>>(
  (ref) {
    final holdingsAsync = ref.watch(allHoldingsProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final pricesAsync = ref.watch(priceHistoryProvider);
    final cashAsync = ref.watch(allCashRecordsProvider);
    final includeCash = ref.watch(includeCashInStatsProvider);

    for (final value in [
      holdingsAsync,
      transactionsAsync,
      pricesAsync,
      cashAsync,
    ]) {
      if (value.hasError) {
        return AsyncError<PerformanceResult>(
          value.error!,
          value.stackTrace ?? StackTrace.empty,
        );
      }
    }
    if (holdingsAsync.isLoading ||
        transactionsAsync.isLoading ||
        pricesAsync.isLoading ||
        cashAsync.isLoading) {
      return const AsyncLoading<PerformanceResult>();
    }

    final holdings =
        holdingsAsync.valueOrNull ?? const <AssetHolding>[];
    final transactions =
        transactionsAsync.valueOrNull ?? const <AssetTransaction>[];
    final prices = pricesAsync.valueOrNull ?? const <PricePoint>[];
    final cashRecords =
        cashAsync.valueOrNull ?? const <CashRecord>[];

    final transactionsByHolding = <int, List<AssetTransaction>>{};
    for (final transaction in transactions) {
      (transactionsByHolding[transaction.holdingId] ??= []).add(transaction);
    }

    final inputs = [
      for (final holding in holdings)
        HoldingPerformanceInput(
          holding: holding,
          transactions: transactionsByHolding[holding.id] ?? const [],
        ),
    ];

    return AsyncData(
      BuildPerformance.build(
        holdings: inputs,
        priceHistory: prices,
        cashRecords: cashRecords,
        includeCash: includeCash,
        today: DateTime.now(),
      ),
    );
  },
);
