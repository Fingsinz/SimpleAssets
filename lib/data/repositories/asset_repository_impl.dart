import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_holding_draft.dart';
import '../../domain/entities/cash_record.dart';
import '../../domain/repositories/asset_repository.dart';
import '../local/dao/asset_dao.dart';
import '../local/database.dart';
import '../mappers/entity_mappers.dart';

class AssetRepositoryImpl implements AssetRepository {
  final AppDatabase _db;

  AssetRepositoryImpl(this._db);

  AssetDao get _dao => _db.assetDao;

  @override
  Stream<List<AssetHolding>> watchHoldings() => _dao
      .watchAllHoldings()
      .map((rows) => rows.map((row) => row.toDomain()).toList());

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
  Future<AssetHolding?> getHoldingById(int id) async {
    final row = await _dao.getHoldingById(id);
    return row?.toDomain();
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

    return _dao.insertHolding(
      AssetHoldingsCompanion.insert(
        categoryId: draft.categoryId,
        name: draft.name,
        quantity: draft.quantity.toString(),
        costPrice: draft.costPrice.toString(),
        purchaseDate: draft.purchaseDate,
        unit: Value(draft.unit),
        code: Value(draft.code),
        currentPrice: Value(draft.currentPrice?.toString()),
        notes: Value(draft.notes),
      ),
    );
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

    return _dao.updateHolding(
      id,
      AssetHoldingsCompanion(
        categoryId: Value(draft.categoryId),
        name: Value(draft.name),
        code: Value(draft.code),
        unit: Value(draft.unit),
        quantity: Value(draft.quantity.toString()),
        costPrice: Value(draft.costPrice.toString()),
        currentPrice: Value(draft.currentPrice?.toString()),
        purchaseDate: Value(draft.purchaseDate),
        notes: Value(draft.notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteHolding(int id) async {
    await _dao.deleteHolding(id);
  }

  @override
  Future<void> updateCurrentPrice(int id, Decimal price) =>
      _dao.updateCurrentPrice(id, price.toString());

  @override
  Stream<List<CashRecord>> watchCashRecords(int holdingId) => _db.cashRecordDao
      .watchForHolding(holdingId)
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
  Future<void> clearAllData() => _db.clearUserData();
}
