import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/asset_transaction.dart';
import 'asset_providers.dart';

/// 某个持仓的交易流水，按日期倒序。
final holdingTransactionsProvider =
    StreamProvider.autoDispose.family<List<AssetTransaction>, int>(
  (ref, holdingId) =>
      ref.watch(assetRepositoryProvider).watchTransactions(holdingId),
);

/// 全部交易流水，按日期倒序。
final allTransactionsProvider = StreamProvider<List<AssetTransaction>>(
  (ref) => ref.watch(assetRepositoryProvider).watchAllTransactions(),
);
