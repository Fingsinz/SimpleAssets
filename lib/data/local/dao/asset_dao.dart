import 'package:drift/drift.dart';

import '../database.dart';

part 'asset_dao.g.dart';

/// 联表查询结果：持仓 + 品类字典行。
class HoldingWithCategory {
  final AssetHoldingRow holding;
  final AssetCategoryRow? category;

  const HoldingWithCategory(this.holding, this.category);
}

@DriftAccessor(tables: [AssetHoldings, AssetCategories])
class AssetDao extends DatabaseAccessor<AppDatabase> with _$AssetDaoMixin {
  AssetDao(super.attachedDatabase);

  Stream<List<HoldingWithCategory>> watchAllHoldings() {
    final query = select(assetHoldings).join([
      leftOuterJoin(
        assetCategories,
        assetCategories.id.equalsExp(assetHoldings.categoryId),
      ),
    ]);
    // 按创建时间排序，避免刷新价格后列表顺序跳动。
    query.orderBy([OrderingTerm.desc(assetHoldings.createdAt)]);
    return query.watch().map(_mapRows);
  }

  Stream<List<HoldingWithCategory>> watchHoldingsByCategory(String categoryId) {
    final query = select(assetHoldings).join([
      leftOuterJoin(
        assetCategories,
        assetCategories.id.equalsExp(assetHoldings.categoryId),
      ),
    ]);
    query
      ..where(assetHoldings.categoryId.equals(categoryId))
      ..orderBy([OrderingTerm.desc(assetHoldings.updatedAt)]);
    return query.watch().map(_mapRows);
  }

  Future<HoldingWithCategory?> getHoldingById(int id) async {
    final query = select(assetHoldings).join([
      leftOuterJoin(
        assetCategories,
        assetCategories.id.equalsExp(assetHoldings.categoryId),
      ),
    ]);
    query.where(assetHoldings.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  Future<List<HoldingWithCategory>> getAllHoldings() async {
    final query = select(assetHoldings).join([
      leftOuterJoin(
        assetCategories,
        assetCategories.id.equalsExp(assetHoldings.categoryId),
      ),
    ]);
    query.orderBy([OrderingTerm.desc(assetHoldings.createdAt)]);
    final rows = await query.get();
    return _mapRows(rows);
  }

  Future<int> insertHolding(AssetHoldingsCompanion companion) =>
      into(assetHoldings).insert(companion);

  Future<void> updateHolding(int id, AssetHoldingsCompanion companion) async {
    await (update(assetHoldings)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<int> deleteHolding(int id) =>
      (delete(assetHoldings)..where((t) => t.id.equals(id))).go();

  Future<void> updateCurrentPrice(int id, String price) async {
    await (update(assetHoldings)..where((t) => t.id.equals(id))).write(
      AssetHoldingsCompanion(
        currentPrice: Value(price),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<AssetCategoryRow>> watchCategories() {
    final query = select(assetCategories)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.watch();
  }

  Future<List<AssetCategoryRow>> getCategories() {
    final query = select(assetCategories)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return query.get();
  }

  Future<AssetCategoryRow?> getCategory(String id) {
    return (select(assetCategories)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> deleteAllHoldings() => delete(assetHoldings).go();

  List<HoldingWithCategory> _mapRows(List<TypedResult> rows) =>
      rows.map(_mapRow).toList();

  HoldingWithCategory _mapRow(TypedResult row) => HoldingWithCategory(
        row.readTable(assetHoldings),
        row.readTableOrNull(assetCategories),
      );
}
