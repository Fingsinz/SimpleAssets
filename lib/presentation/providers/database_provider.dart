import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/dao/asset_dao.dart';
import '../../data/local/dao/price_snapshot_dao.dart';
import '../../data/local/dao/transaction_dao.dart';
import '../../data/local/database.dart';

/// 数据库实例由 main.dart 覆盖注入，测试时可注入内存数据库。
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider 必须在 main.dart 中覆盖');
});

final assetDaoProvider = Provider<AssetDao>(
  (ref) => ref.watch(databaseProvider).assetDao,
);

final transactionDaoProvider = Provider<TransactionDao>(
  (ref) => ref.watch(databaseProvider).transactionDao,
);

final priceSnapshotDaoProvider = Provider<PriceSnapshotDao>(
  (ref) => ref.watch(databaseProvider).priceSnapshotDao,
);
