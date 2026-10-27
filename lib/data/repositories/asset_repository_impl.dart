import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../core/decimal_utils.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_holding_draft.dart';
import '../../domain/entities/asset_transaction.dart';
import '../../domain/entities/asset_transaction_draft.dart';
import '../../domain/entities/cash_record.dart';
import '../../domain/entities/price_point.dart';
import '../../domain/repositories/asset_repository.dart';
import '../../domain/usecases/replay_transactions.dart';
import '../local/dao/asset_dao.dart';
import '../local/database.dart';
import '../mappers/entity_mappers.dart';
import 'holding_stats_writer.dart';

class AssetRepositoryImpl implements AssetRepository {
  final AppDatabase _db;

  AssetRepositoryImpl(this._db);

  AssetDao get _dao => _db.assetDao;

  @override
  Stream<List<AssetHolding>> watchHoldings() async* {
    yield await getHoldings();
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.assetHoldings,
        _db.assetCategories,
        _db.transactions,
        _db.priceHistory,
      ]),
    )) {
      yield await getHoldings();
    }
  }

  @override
  Future<List<AssetHolding>> getHoldings() async {
    final rows = await _dao.getAllHoldings();
    final transactionRows = await _db.transactionDao.getAll();
    final priceRows = await _db.priceHistoryDao.getAll();

    final transactionsByHolding = <int, List<AssetTransaction>>{};
    for (final row in transactionRows) {
      (transactionsByHolding[row.holdingId] ??= []).add(row.toDomain());
    }
    final pricesByHolding = <int, List<PriceHistoryRow>>{};
    for (final row in priceRows) {
      (pricesByHolding[row.holdingId] ??= []).add(row);
    }

    final now = DateTime.now();
    return [
      for (final row in rows)
        _toHolding(
          row,
          transactionsByHolding[row.holding.id] ?? const [],
          pricesByHolding[row.holding.id] ?? const [],
          now,
        ),
    ];
  }

  AssetHolding _toHolding(
    HoldingWithCategory row,
    List<AssetTransaction> transactions,
    List<PriceHistoryRow> prices,
    DateTime now,
  ) {
    final holding = row.holding;
    final categoryName = row.category?.name ?? holding.categoryId;

    if (holding.categoryId == AssetCategoryIds.cash) {
      return AssetHolding(
        id: holding.id,
        categoryId: holding.categoryId,
        categoryName: categoryName,
        name: holding.name,
        code: holding.code,
        unit: holding.unit,
        amount: DecimalUtils.tryParse(holding.amount),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: holding.purchaseDate,
        notes: holding.notes,
        createdAt: holding.createdAt,
        updatedAt: holding.updatedAt,
      );
    }

    // 兼容尚未写入流水的导入 / 旧数据；任务 14 起导入会生成期初流水。
    final cachedQuantity = DecimalUtils.parseOrZero(holding.quantity);
    final cachedCostPrice = DecimalUtils.parseOrZero(holding.costPrice);
    final position = transactions.isEmpty && cachedQuantity > Decimal.zero
        ? HoldingPosition(
            quantity: cachedQuantity,
            averageCost: cachedCostPrice,
            realizedProfit: Decimal.zero,
            totalBuy: cachedQuantity * cachedCostPrice,
            totalSell: Decimal.zero,
            totalDividends: Decimal.zero,
            totalFees: Decimal.zero,
            firstDate: holding.purchaseDate,
            lastDate: holding.purchaseDate,
          )
        : ReplayTransactions.replay(transactions);

    final rawCurrent = DecimalUtils.tryParse(holding.currentPrice);
    Decimal? adjustedCurrent = rawCurrent;
    if (rawCurrent != null && prices.isNotEmpty) {
      final latest = prices.reduce(
        (a, b) => a.observedAt.isAfter(b.observedAt) ||
                (a.observedAt == b.observedAt && a.id > b.id)
            ? a
            : b,
      );
      final factor = ReplayTransactions.cumulativeSplitFactor(
        transactions,
        latest.observedAt,
        now,
      );
      if (factor != Decimal.one && factor > Decimal.zero) {
        adjustedCurrent =
            (rawCurrent / factor).toDecimal(scaleOnInfinitePrecision: 20);
      }
    }

    return AssetHolding(
      id: holding.id,
      categoryId: holding.categoryId,
      categoryName: categoryName,
      name: holding.name,
      code: holding.code,
      unit: holding.unit,
      quantity: position.quantity,
      costPrice: position.averageCost,
      currentPrice: adjustedCurrent,
      purchaseDate: position.firstDate ?? holding.purchaseDate,
      notes: holding.notes,
      createdAt: holding.createdAt,
      updatedAt: holding.updatedAt,
      totalBuy: position.totalBuy,
      totalSell: position.totalSell,
      totalDividends: position.totalDividends,
      totalFees: position.totalFees,
      realizedProfit: position.realizedProfit,
      firstTransactionDate: position.firstDate,
    );
  }

  @override
  Future<AssetHolding?> getHoldingById(int id) async {
    final holdings = await getHoldings();
    for (final holding in holdings) {
      if (holding.id == id) return holding;
    }
    return null;
  }

  @override
  Stream<List<AssetCategory>> watchCategories() => _dao
      .watchCategories()
      .map((rows) => rows.map((row) => row.toDomain()).toList());

  @override
  Future<List<AssetCategory>> getCategories() async {
    final rows = await _dao.getCategories();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<int> addHolding(AssetHoldingDraft draft) {
    if (draft.categoryId == AssetCategoryIds.cash) {
      final amount = draft.amount ?? draft.quantity;
      return _db.transaction(() async {
        final id = await _dao.insertHolding(
          AssetHoldingsCompanion.insert(
            categoryId: draft.categoryId,
            name: draft.name,
            quantity: '0',
            costPrice: '0',
            purchaseDate: draft.purchaseDate,
            amount: Value(amount.toString()),
            notes: Value(draft.notes),
          ),
        );
        await _db.cashRecordDao.insertRecord(
          CashRecordsCompanion.insert(
            holdingId: id,
            amount: amount.toString(),
            recordDate: draft.purchaseDate,
          ),
        );
        return id;
      });
    }

    return _db.transaction(() async {
      final id = await _dao.insertHolding(
        AssetHoldingsCompanion.insert(
          categoryId: draft.categoryId,
          name: draft.name,
          quantity: '0',
          costPrice: '0',
          purchaseDate: draft.purchaseDate,
          unit: Value(draft.unit),
          code: Value(draft.code),
          currentPrice: Value(draft.currentPrice?.toString()),
          notes: Value(draft.notes),
        ),
      );
      await _db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          holdingId: id,
          type: TransactionType.buy.storageValue,
          amount: Value((draft.quantity * draft.costPrice).toString()),
          price: Value(draft.costPrice.toString()),
          quantity: Value(draft.quantity.toString()),
          fee: Value((draft.fee ?? Decimal.zero).toString()),
          date: draft.purchaseDate,
        ),
      );
      await HoldingStatsWriter.recompute(_db, id);

      final currentPrice = draft.currentPrice;
      if (currentPrice != null) {
        await _db.priceHistoryDao.upsertMonth(
          holdingId: id,
          period: _monthKey(DateTime.now()),
          price: currentPrice.toString(),
        );
      }
      return id;
    });
  }

  @override
  Future<void> updateHolding(int id, AssetHoldingDraft draft) {
    if (draft.categoryId == AssetCategoryIds.cash) {
      return _dao.updateHolding(
        id,
        AssetHoldingsCompanion(
          name: Value(draft.name),
          notes: Value(draft.notes),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    return _db.transaction(() async {
      final existing = await getHoldingById(id);
      if (existing == null) throw StateError('持仓不存在');
      // 展示价可能已按折算调整；用展示价比较，避免「只改名称」被误判为改价。
      final oldDisplayPrice = existing.currentPrice?.toString();
      final newPrice = draft.currentPrice?.toString();
      final priceChanged = newPrice != oldDisplayPrice;

      await _dao.updateHolding(
        id,
        AssetHoldingsCompanion(
          categoryId: Value(draft.categoryId),
          name: Value(draft.name),
          code: Value(draft.code),
          unit: Value(draft.unit),
          currentPrice: priceChanged
              ? Value(newPrice)
              : const Value<String?>.absent(),
          notes: Value(draft.notes),
          updatedAt: Value(DateTime.now()),
        ),
      );

      if (priceChanged && newPrice != null) {
        await _db.priceHistoryDao.upsertMonth(
          holdingId: id,
          period: _monthKey(DateTime.now()),
          price: newPrice,
        );
      }
    });
  }

  @override
  Future<void> deleteHolding(int id) async {
    await _dao.deleteHolding(id);
  }

  @override
  Future<void> updateCurrentPrice(int id, Decimal price) {
    return _db.transaction(() async {
      await _dao.updateCurrentPrice(id, price.toString());
      await _db.priceHistoryDao.upsertMonth(
        holdingId: id,
        period: _monthKey(DateTime.now()),
        price: price.toString(),
      );
    });
  }

  @override
  Stream<List<CashRecord>> watchCashRecords(int holdingId) => _db.cashRecordDao
      .watchForHolding(holdingId)
      .map((rows) => rows.map((row) => row.toDomain()).toList());

  @override
  Stream<List<CashRecord>> watchAllCashRecords() => _db.cashRecordDao
      .watchAllRecords()
      .map((rows) => rows.map((row) => row.toDomain()).toList());

  @override
  Future<List<CashRecord>> getCashRecords(int holdingId) async {
    final rows = await _db.cashRecordDao.getForHolding(holdingId);
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<int> addCashRecord(
    int holdingId,
    Decimal amount,
    DateTime recordDate,
  ) {
    if (amount <= Decimal.zero) {
      throw ArgumentError.value(amount, 'amount', '金额必须大于 0');
    }
    return _db.transaction(() async {
      final id = await _db.cashRecordDao.insertRecord(
        CashRecordsCompanion.insert(
          holdingId: holdingId,
          amount: amount.toString(),
          recordDate: recordDate,
        ),
      );
      await _syncLatestCash(holdingId);
      return id;
    });
  }

  @override
  Future<void> updateCashRecord(
    int recordId,
    Decimal amount,
    DateTime recordDate,
  ) async {
    if (amount <= Decimal.zero) {
      throw ArgumentError.value(amount, 'amount', '金额必须大于 0');
    }
    await _db.transaction(() async {
      final record = await _db.cashRecordDao.getById(recordId);
      if (record == null) {
        throw StateError('现金记录不存在');
      }
      await _db.cashRecordDao.updateRecord(
        recordId,
        CashRecordsCompanion(
          amount: Value(amount.toString()),
          recordDate: Value(recordDate),
        ),
      );
      await _syncLatestCash(record.holdingId);
    });
  }

  @override
  Future<void> deleteCashRecord(int recordId) async {
    await _db.transaction(() async {
      final record = await _db.cashRecordDao.getById(recordId);
      if (record == null) return;
      final count = await _db.cashRecordDao.countForHolding(record.holdingId);
      if (count <= 1) {
        throw StateError('至少保留一条记录');
      }
      await _db.cashRecordDao.deleteRecord(recordId);
      await _syncLatestCash(record.holdingId);
    });
  }

  Future<void> _syncLatestCash(int holdingId) async {
    final latest = await _db.cashRecordDao.latestForHolding(holdingId);
    if (latest == null) return;
    await _dao.updateHolding(
      holdingId,
      AssetHoldingsCompanion(
        amount: Value(latest.amount),
        purchaseDate: Value(latest.recordDate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Stream<List<AssetTransaction>> watchTransactions(int holdingId) =>
      _db.transactionDao
          .watchForHolding(holdingId)
          .map((rows) => rows.map((row) => row.toDomain()).toList());

  @override
  Stream<List<AssetTransaction>> watchAllTransactions() =>
      _db.transactionDao
          .watchAll()
          .map((rows) => rows.map((row) => row.toDomain()).toList());

  @override
  Future<List<AssetTransaction>> getTransactions(int holdingId) async {
    final rows = await _db.transactionDao.getForHoldingAsc(holdingId);
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<int> addTransaction(AssetTransactionDraft draft) {
    return _db.transaction(() async {
      final id = await _db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          holdingId: draft.holdingId,
          type: draft.type.storageValue,
          amount: Value(draft.amount?.toString()),
          price: Value(draft.price?.toString()),
          quantity: Value(draft.quantity?.toString()),
          fee: Value((draft.fee ?? Decimal.zero).toString()),
          ratio: Value(draft.ratio?.toString()),
          date: draft.date,
          notes: Value(draft.notes),
        ),
      );
      await HoldingStatsWriter.recompute(_db, draft.holdingId);
      return id;
    });
  }

  @override
  Future<void> updateTransaction(int id, AssetTransactionDraft draft) {
    return _db.transaction(() async {
      final existing = await _db.transactionDao.getById(id);
      if (existing == null) throw StateError('交易记录不存在');

      await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          holdingId: Value(draft.holdingId),
          type: Value(draft.type.storageValue),
          amount: Value(draft.amount?.toString()),
          price: Value(draft.price?.toString()),
          quantity: Value(draft.quantity?.toString()),
          fee: Value((draft.fee ?? Decimal.zero).toString()),
          ratio: Value(draft.ratio?.toString()),
          date: Value(draft.date),
          notes: Value(draft.notes),
        ),
      );

      await HoldingStatsWriter.recompute(_db, draft.holdingId);
      if (existing.holdingId != draft.holdingId) {
        await HoldingStatsWriter.recompute(_db, existing.holdingId);
      }
    });
  }

  @override
  Future<void> deleteTransaction(int id) {
    return _db.transaction(() async {
      final existing = await _db.transactionDao.getById(id);
      if (existing == null) return;
      await _db.transactionDao.deleteTransaction(id);
      await HoldingStatsWriter.recompute(_db, existing.holdingId);
    });
  }

  @override
  Stream<List<PricePoint>> watchPriceHistory(int holdingId) =>
      _db.priceHistoryDao
          .watchForHolding(holdingId)
          .map((rows) => rows.map((row) => row.toDomain()).toList());

  @override
  Stream<List<PricePoint>> watchAllPriceHistory() => _db.priceHistoryDao
      .watchAll()
      .map((rows) => rows.map((row) => row.toDomain()).toList());

  @override
  Future<List<PricePoint>> getPriceHistory(int holdingId) async {
    final rows = await _db.priceHistoryDao.getForHolding(holdingId);
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<List<PricePoint>> getAllPriceHistory() async {
    final rows = await _db.priceHistoryDao.getAll();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<void> clearAllData() => _db.clearUserData();

  String _monthKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';
}
