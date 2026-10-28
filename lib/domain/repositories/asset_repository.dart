import 'package:decimal/decimal.dart';

import '../entities/asset_category.dart';
import '../entities/asset_holding.dart';
import '../entities/asset_holding_draft.dart';
import '../entities/asset_transaction.dart';
import '../entities/asset_transaction_draft.dart';
import '../entities/cash_record.dart';
import '../entities/price_point.dart';

/// 持仓数据仓库抽象。表现层只依赖此接口。
abstract class AssetRepository {
  Stream<List<AssetHolding>> watchHoldings();

  Future<List<AssetHolding>> getHoldings();

  Stream<List<AssetCategory>> watchCategories();

  Future<List<AssetCategory>> getCategories();

  Future<AssetHolding?> getHoldingById(int id);

  Future<int> addHolding(AssetHoldingDraft draft);

  Future<void> updateHolding(int id, AssetHoldingDraft draft);

  Future<void> deleteHolding(int id);

  Future<void> updateCurrentPrice(int id, Decimal price);

  /// 补录某个已结束月份的月末价格；`month` 只取年月，写入该月最后一天。
  Future<void> saveMonthEndPrice(int holdingId, DateTime month, Decimal price);

  Stream<List<CashRecord>> watchCashRecords(int holdingId);

  Future<List<CashRecord>> getCashRecords(int holdingId);

  Future<int> addCashRecord(int holdingId, Decimal amount, DateTime recordDate);

  Future<void> updateCashRecord(
    int recordId,
    Decimal amount,
    DateTime recordDate,
  );

  Future<void> deleteCashRecord(int recordId);

  Stream<List<AssetTransaction>> watchTransactions(int holdingId);

  Stream<List<AssetTransaction>> watchAllTransactions();

  Future<List<AssetTransaction>> getTransactions(int holdingId);

  Future<int> addTransaction(AssetTransactionDraft draft);

  Future<void> updateTransaction(int id, AssetTransactionDraft draft);

  Future<void> deleteTransaction(int id);

  Stream<List<PricePoint>> watchPriceHistory(int holdingId);

  Stream<List<PricePoint>> watchAllPriceHistory();

  Future<List<PricePoint>> getPriceHistory(int holdingId);

  Future<List<PricePoint>> getAllPriceHistory();

  Stream<List<CashRecord>> watchAllCashRecords();

  /// 清空持仓、交易与价格历史，保留品类字典。
  Future<void> clearAllData();
}
