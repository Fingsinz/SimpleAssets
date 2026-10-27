import 'package:drift/drift.dart';

import '../../domain/usecases/replay_transactions.dart';
import '../local/database.dart';
import '../mappers/entity_mappers.dart';

/// 把交易流水重放结果写回持仓缓存。
///
/// 流水是唯一事实来源；这里只在流水变化后同步 `quantity` / `cost_price` /
/// `purchase_date`。校验失败会抛 [TransactionValidationException]，由调用方的
/// 数据库事务整体回滚。
class HoldingStatsWriter {
  HoldingStatsWriter._();

  static Future<HoldingPosition> recompute(
    AppDatabase db,
    int holdingId,
  ) async {
    final rows = await db.transactionDao.getForHoldingAsc(holdingId);
    final transactions = rows.map((row) => row.toDomain()).toList();
    final position = ReplayTransactions.replay(transactions);

    final existing = await db.assetDao.getHoldingById(holdingId);
    if (existing == null) return position;

    await db.assetDao.updateHolding(
      holdingId,
      AssetHoldingsCompanion(
        quantity: Value(position.quantity.toString()),
        costPrice: Value(position.averageCost.toString()),
        purchaseDate: Value(
          position.firstDate ?? existing.holding.purchaseDate,
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return position;
  }
}
