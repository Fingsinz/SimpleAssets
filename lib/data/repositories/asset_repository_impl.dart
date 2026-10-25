import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_holding_draft.dart';
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
    return _dao.insertHolding(
      AssetHoldingsCompanion.insert(
        categoryId: draft.categoryId,
        name: draft.name,
        quantity: draft.quantity.toString(),
        costPrice: draft.costPrice.toString(),
        purchaseDate: draft.purchaseDate,
        code: Value(draft.code),
        currentPrice: Value(draft.currentPrice?.toString()),
        notes: Value(draft.notes),
      ),
    );
  }

  @override
  Future<void> updateHolding(int id, AssetHoldingDraft draft) {
    return _dao.updateHolding(
      id,
      AssetHoldingsCompanion(
        categoryId: Value(draft.categoryId),
        name: Value(draft.name),
        code: Value(draft.code),
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
  Future<void> clearAllData() => _db.clearUserData();
}
