import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_transaction.dart';
import '../../domain/entities/balance_record.dart';
import '../../domain/entities/performance.dart';
import '../../domain/entities/price_point.dart';
import '../../domain/usecases/build_performance.dart';
import '../../domain/usecases/valuate_portfolio.dart';
import 'asset_providers.dart';
import 'transaction_providers.dart';

final priceHistoryProvider = StreamProvider<List<PricePoint>>(
  (ref) => ref.watch(assetRepositoryProvider).watchAllPriceHistory(),
);

final allBalanceRecordsProvider = StreamProvider<List<BalanceRecord>>(
  (ref) => ref.watch(assetRepositoryProvider).watchAllBalanceRecords(),
);

/// 收益细节数据：持仓、流水、价格历史与余额记录的组合。
///
/// 现金与负债不参与分析；自定义产品的投入 / 卖出来自余额记录。
final performanceResultProvider = Provider<AsyncValue<PerformanceResult>>(
  (ref) {
    final holdingsAsync = ref.watch(allHoldingsProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final pricesAsync = ref.watch(priceHistoryProvider);
    final balanceAsync = ref.watch(allBalanceRecordsProvider);

    for (final value in [
      holdingsAsync,
      transactionsAsync,
      pricesAsync,
      balanceAsync,
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
        balanceAsync.isLoading) {
      return const AsyncLoading<PerformanceResult>();
    }

    final holdings =
        holdingsAsync.valueOrNull ?? const <AssetHolding>[];
    final transactions =
        transactionsAsync.valueOrNull ?? const <AssetTransaction>[];
    final prices = pricesAsync.valueOrNull ?? const <PricePoint>[];
    final balanceRecords =
        balanceAsync.valueOrNull ?? const <BalanceRecord>[];

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
        balanceRecords: balanceRecords,
        today: DateTime.now(),
      ),
    );
  },
);

/// 单个持仓的收益细节，供分析页统计曲线按单品查看。
///
/// 只取该持仓自己的流水、价格历史与余额记录，口径与组合曲线一致。
final holdingPerformanceProvider = Provider.autoDispose
    .family<AsyncValue<PerformanceResult>, int>((ref, holdingId) {
  final holdingsAsync = ref.watch(allHoldingsProvider);
  final transactionsAsync = ref.watch(allTransactionsProvider);
  final pricesAsync = ref.watch(priceHistoryProvider);
  final balancesAsync = ref.watch(allBalanceRecordsProvider);

  for (final value in [
    holdingsAsync,
    transactionsAsync,
    pricesAsync,
    balancesAsync,
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
      balancesAsync.isLoading) {
    return const AsyncLoading<PerformanceResult>();
  }

  AssetHolding? holding;
  for (final item in holdingsAsync.valueOrNull ?? const <AssetHolding>[]) {
    if (item.id == holdingId) {
      holding = item;
      break;
    }
  }
  if (holding == null) return AsyncData(PerformanceResult.empty());

  final transactions = [
    for (final transaction
        in transactionsAsync.valueOrNull ?? const <AssetTransaction>[])
      if (transaction.holdingId == holdingId) transaction,
  ];
  final prices = [
    for (final price in pricesAsync.valueOrNull ?? const <PricePoint>[])
      if (price.holdingId == holdingId) price,
  ];
  final balances = [
    for (final record
        in balancesAsync.valueOrNull ?? const <BalanceRecord>[])
      if (record.holdingId == holdingId) record,
  ];

  return AsyncData(
    BuildPerformance.build(
      holdings: [
        HoldingPerformanceInput(holding: holding, transactions: transactions),
      ],
      priceHistory: prices,
      balanceRecords: balances,
      today: DateTime.now(),
    ),
  );
});
