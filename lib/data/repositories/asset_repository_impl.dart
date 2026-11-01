import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../core/decimal_utils.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_holding_draft.dart';
import '../../domain/entities/asset_transaction.dart';
import '../../domain/entities/asset_transaction_draft.dart';
import '../../domain/entities/balance_record.dart';
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
        _db.balanceRecords,
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
    final balanceRows = await _db.balanceRecordDao.getAllRecords();

    final transactionsByHolding = <int, List<AssetTransaction>>{};
    for (final row in transactionRows) {
      (transactionsByHolding[row.holdingId] ??= []).add(row.toDomain());
    }
    final pricesByHolding = <int, List<PriceHistoryRow>>{};
    for (final row in priceRows) {
      (pricesByHolding[row.holdingId] ??= []).add(row);
    }
    final balancesByHolding = <int, List<BalanceRecordRow>>{};
    for (final row in balanceRows) {
      (balancesByHolding[row.holdingId] ??= []).add(row);
    }

    final now = DateTime.now();
    return [
      for (final row in rows)
        _toHolding(
          row,
          transactionsByHolding[row.holding.id] ?? const [],
          pricesByHolding[row.holding.id] ?? const [],
          balancesByHolding[row.holding.id] ?? const [],
          now,
        ),
    ];
  }

  AssetHolding _toHolding(
    HoldingWithCategory row,
    List<AssetTransaction> transactions,
    List<PriceHistoryRow> prices,
    List<BalanceRecordRow> balances,
    DateTime now,
  ) {
    final holding = row.holding;
    final categoryName = row.category?.name ?? holding.categoryId;

    if (holding.categoryId == AssetCategoryIds.cash ||
        holding.categoryId == AssetCategoryIds.liability) {
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

    if (holding.categoryId == AssetCategoryIds.custom) {
      var totalBuy = Decimal.zero;
      var totalSell = Decimal.zero;
      var totalFees = Decimal.zero;
      DateTime? firstDate;
      for (final record in balances) {
        final flowAmount = DecimalUtils.parseOrZero(record.flowAmount);
        final fee = DecimalUtils.parseOrZero(record.fee);
        totalFees += fee;
        if (firstDate == null || record.recordDate.isBefore(firstDate)) {
          firstDate = record.recordDate;
        }
        switch (BalanceFlowKind.fromStorage(record.flowKind)) {
          case BalanceFlowKind.invest:
            totalBuy += flowAmount + fee;
            break;
          case BalanceFlowKind.sell:
            totalSell += flowAmount - fee;
            break;
          case BalanceFlowKind.none:
            break;
        }
      }
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
        purchaseDate: firstDate ?? holding.purchaseDate,
        notes: holding.notes,
        createdAt: holding.createdAt,
        updatedAt: holding.updatedAt,
        totalBuy: totalBuy,
        totalSell: totalSell,
        totalDividends: Decimal.zero,
        totalFees: totalFees,
        realizedProfit: Decimal.zero,
        firstTransactionDate: firstDate,
      );
    }

    // 兼容尚未写入流水的导入 / 旧数据；任务 14 起导入会生成期初流水。
    final cachedQuantity = DecimalUtils.parseOrZero(holding.quantity);
    final cachedCostPrice = DecimalUtils.parseOrZero(holding.costPrice);
    final position = transactions.isEmpty && cachedQuantity > Decimal.zero
        ? HoldingPosition(
            quantity: cachedQuantity,
            averageCost: cachedCostPrice,
            costPrice: cachedCostPrice,
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
      costPrice: position.costPrice,
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

  static bool _isAmountBasedCategory(String categoryId) =>
      categoryId == AssetCategoryIds.cash ||
      categoryId == AssetCategoryIds.liability ||
      categoryId == AssetCategoryIds.custom;

  Future<void> _ensureUniqueName(
    AssetHoldingDraft draft, {
    int? excludeId,
  }) async {
    if (!_isAmountBasedCategory(draft.categoryId)) return;
    final name = draft.name.trim();
    final rows = await _dao.getAllHoldings();
    for (final row in rows) {
      final holding = row.holding;
      if (holding.id == excludeId) continue;
      if (holding.categoryId == draft.categoryId &&
          holding.name.trim() == name) {
        throw ArgumentError('该品类下已存在同名资产');
      }
    }
  }

  @override
  Future<int> addHolding(AssetHoldingDraft draft) async {
    await _ensureUniqueName(draft);

    if (draft.categoryId == AssetCategoryIds.cash ||
        draft.categoryId == AssetCategoryIds.liability) {
      final amount = draft.amount ?? draft.quantity;
      if (draft.categoryId == AssetCategoryIds.cash &&
          amount <= Decimal.zero) {
        throw ArgumentError.value(amount, 'amount', '现金金额必须大于 0');
      }
      if (draft.categoryId == AssetCategoryIds.liability &&
          amount >= Decimal.zero) {
        throw ArgumentError.value(amount, 'amount', '负债金额必须小于 0');
      }
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
        await _db.balanceRecordDao.insertRecord(
          BalanceRecordsCompanion.insert(
            holdingId: id,
            amount: amount.toString(),
            recordDate: draft.purchaseDate,
          ),
        );
        return id;
      });
    }

    if (draft.categoryId == AssetCategoryIds.custom) {
      final buyAmount = draft.amount;
      if (buyAmount == null || buyAmount <= Decimal.zero) {
        throw ArgumentError.value(
          buyAmount,
          'amount',
          '自定义产品买入金额必须大于 0',
        );
      }
      final fee = draft.fee ?? Decimal.zero;
      if (fee < Decimal.zero) {
        throw ArgumentError.value(fee, 'fee', '手续费不能为负数');
      }
      return _db.transaction(() async {
        final id = await _dao.insertHolding(
          AssetHoldingsCompanion.insert(
            categoryId: draft.categoryId,
            name: draft.name,
            quantity: '0',
            costPrice: '0',
            purchaseDate: draft.purchaseDate,
            amount: Value(buyAmount.toString()),
            notes: Value(draft.notes),
          ),
        );
        await _db.balanceRecordDao.insertRecord(
          BalanceRecordsCompanion.insert(
            holdingId: id,
            amount: buyAmount.toString(),
            flowKind: Value(BalanceFlowKind.invest.storageValue),
            flowAmount: Value(buyAmount.toString()),
            fee: Value(fee.toString()),
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
  Future<void> updateHolding(int id, AssetHoldingDraft draft) async {
    await _ensureUniqueName(draft, excludeId: id);
    if (_isAmountBasedCategory(draft.categoryId)) {
      await _dao.updateHolding(
        id,
        AssetHoldingsCompanion(
          name: Value(draft.name),
          notes: Value(draft.notes),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return;
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
  Future<void> saveMonthEndPrice(
    int holdingId,
    DateTime month,
    Decimal price,
  ) async {
    if (price <= Decimal.zero) {
      throw ArgumentError.value(price, 'price', '价格必须大于 0');
    }
    final period = _monthKey(month);
    // 当月价格走「更新现价」，否则会与自动刷新争抢同一行记录。
    if (period.compareTo(_monthKey(DateTime.now())) >= 0) {
      throw ArgumentError.value(month, 'month', '只能补录已结束月份的价格');
    }
    await _db.priceHistoryDao.upsertMonth(
      holdingId: holdingId,
      period: period,
      price: price.toString(),
      observedAt: DateTime(month.year, month.month + 1, 0),
    );
  }

  @override
  Stream<List<BalanceRecord>> watchBalanceRecords(int holdingId) =>
      _db.balanceRecordDao
          .watchForHolding(holdingId)
          .map((rows) => rows.map((row) => row.toDomain()).toList());

  @override
  Stream<List<BalanceRecord>> watchAllBalanceRecords() =>
      _db.balanceRecordDao
          .watchAllRecords()
          .map((rows) => rows.map((row) => row.toDomain()).toList());

  @override
  Future<List<BalanceRecord>> getBalanceRecords(int holdingId) async {
    final rows = await _db.balanceRecordDao.getForHolding(holdingId);
    return rows.map((row) => row.toDomain()).toList();
  }

  void _validateBalanceRecord(
    String categoryId,
    BalanceRecordDraft draft,
  ) {
    final fee = draft.feeValue;
    if (fee < Decimal.zero) {
      throw ArgumentError.value(fee, 'fee', '手续费不能为负数');
    }

    switch (categoryId) {
      case AssetCategoryIds.cash:
        if (draft.amount <= Decimal.zero) {
          throw ArgumentError.value(draft.amount, 'amount', '现金金额必须大于 0');
        }
        if (draft.flowKind != BalanceFlowKind.none) {
          throw ArgumentError('现金记录不支持投入 / 卖出流水');
        }
        break;
      case AssetCategoryIds.liability:
        if (draft.amount >= Decimal.zero) {
          throw ArgumentError.value(draft.amount, 'amount', '负债金额必须小于 0');
        }
        if (draft.flowKind != BalanceFlowKind.none) {
          throw ArgumentError('负债记录不支持投入 / 卖出流水');
        }
        break;
      case AssetCategoryIds.custom:
        if (draft.amount < Decimal.zero) {
          throw ArgumentError.value(
            draft.amount,
            'amount',
            '持有金额不能为负数',
          );
        }
        if (draft.flowKind != BalanceFlowKind.none) {
          final flow = draft.flowAmount;
          if (flow == null || flow <= Decimal.zero) {
            throw ArgumentError.value(
              flow,
              'flowAmount',
              '操作金额必须大于 0',
            );
          }
        }
        break;
      default:
        throw ArgumentError('该资产不支持余额记录');
    }
  }

  @override
  Future<int> addBalanceRecord(
    int holdingId,
    BalanceRecordDraft draft,
  ) async {
    final holding = await _dao.getHoldingById(holdingId);
    if (holding == null) throw StateError('资产不存在');
    _validateBalanceRecord(holding.holding.categoryId, draft);
    return _db.transaction(() async {
      final id = await _db.balanceRecordDao.insertRecord(
        BalanceRecordsCompanion.insert(
          holdingId: holdingId,
          amount: draft.amount.toString(),
          flowKind: Value(draft.flowKind.storageValue),
          flowAmount: Value(draft.flowAmount?.toString()),
          fee: Value(draft.feeValue.toString()),
          recordDate: draft.recordDate,
        ),
      );
      await _syncLatestBalance(holdingId);
      return id;
    });
  }

  @override
  Future<void> updateBalanceRecord(
    int recordId,
    BalanceRecordDraft draft,
  ) async {
    final record = await _db.balanceRecordDao.getById(recordId);
    if (record == null) {
      throw StateError('余额记录不存在');
    }
    final holding = await _dao.getHoldingById(record.holdingId);
    if (holding == null) throw StateError('资产不存在');
    _validateBalanceRecord(holding.holding.categoryId, draft);
    await _db.transaction(() async {
      await _db.balanceRecordDao.updateRecord(
        recordId,
        BalanceRecordsCompanion(
          amount: Value(draft.amount.toString()),
          flowKind: Value(draft.flowKind.storageValue),
          flowAmount: Value(draft.flowAmount?.toString()),
          fee: Value(draft.feeValue.toString()),
          recordDate: Value(draft.recordDate),
        ),
      );
      await _syncLatestBalance(record.holdingId);
    });
  }

  @override
  Future<void> deleteBalanceRecord(int recordId) async {
    final record = await _db.balanceRecordDao.getById(recordId);
    if (record == null) return;
    final holding = await _dao.getHoldingById(record.holdingId);
    final categoryId = holding?.holding.categoryId;
    final isCashLike = categoryId == AssetCategoryIds.cash ||
        categoryId == AssetCategoryIds.liability;
    if (isCashLike) {
      final count =
          await _db.balanceRecordDao.countForHolding(record.holdingId);
      if (count <= 1) {
        throw StateError('至少保留一条记录');
      }
    }
    await _db.transaction(() async {
      await _db.balanceRecordDao.deleteRecord(recordId);
      await _syncLatestBalance(record.holdingId);
    });
  }

  Future<void> _syncLatestBalance(int holdingId) async {
    final holding = await _dao.getHoldingById(holdingId);
    final isCustom = holding?.holding.categoryId == AssetCategoryIds.custom;
    final latest = await _db.balanceRecordDao.latestForHolding(holdingId);
    if (latest == null) {
      if (isCustom) {
        await _dao.updateHolding(
          holdingId,
          AssetHoldingsCompanion(
            amount: const Value('0'),
            quantity: const Value('0'),
            costPrice: const Value('0'),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      return;
    }
    final earliest =
        await _db.balanceRecordDao.earliestForHolding(holdingId);
    await _dao.updateHolding(
      holdingId,
      AssetHoldingsCompanion(
        amount: Value(latest.amount),
        purchaseDate: Value(
          isCustom
              ? (earliest?.recordDate ?? latest.recordDate)
              : latest.recordDate,
        ),
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

  Future<void> _ensureInvestmentHolding(int holdingId) async {
    final holding = await _dao.getHoldingById(holdingId);
    if (holding == null) throw StateError('资产不存在');
    if (_isAmountBasedCategory(holding.holding.categoryId)) {
      throw ArgumentError('金额型资产不支持交易流水');
    }
  }

  @override
  Future<int> addTransaction(AssetTransactionDraft draft) async {
    await _ensureInvestmentHolding(draft.holdingId);
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
  Future<void> updateTransaction(int id, AssetTransactionDraft draft) async {
    await _ensureInvestmentHolding(draft.holdingId);
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
