import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/constants.dart';
import '../../domain/entities/asset_category.dart';
import 'dao/asset_dao.dart';
import 'dao/price_snapshot_dao.dart';
import 'dao/transaction_dao.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// 表定义
// ---------------------------------------------------------------------------

@DataClassName('AssetCategoryRow')
class AssetCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currency => text().withDefault(const Constant('CNY'))();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AssetHoldingRow')
class AssetHoldings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get categoryId => text().references(AssetCategories, #id)();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get quantity => text()(); // Decimal 存为字符串，避免精度丢失
  TextColumn get costPrice => text()();
  TextColumn get currentPrice => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get holdingId =>
      integer().references(AssetHoldings, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // buy, sell, dividend, interest
  TextColumn get amount => text().nullable()();
  TextColumn get price => text().nullable()();
  TextColumn get quantity => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('PriceSnapshotRow')
class PriceSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text()();
  TextColumn get source => text()();
  TextColumn get price => text()();
  TextColumn get currency => text().withDefault(const Constant('CNY'))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

// ---------------------------------------------------------------------------
// 数据库
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [AssetCategories, AssetHoldings, Transactions, PriceSnapshots],
  daos: [AssetDao, TransactionDao, PriceSnapshotDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: AppConstants.databaseName));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          await _seedCategories();
        },
        onUpgrade: (migrator, from, to) async {
          // 当前只有 v1。未来提升 schemaVersion 时，在这里按 from / to 逐级迁移，
          // 例如：
          //   if (from < 2) {
          //     await migrator.addColumn(assetHoldings, assetHoldings.xxx);
          //   }
          // 未补齐迁移就提升版本会直接抛错，避免在结构不匹配时继续读写。
          throw StateError('缺少数据库迁移：v$from → v$to，请勿直接提升 schemaVersion');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seedCategories() async {
    await batch((batch) {
      batch.insertAll(
        assetCategories,
        [
          for (final category in AssetCategory.builtIn)
            AssetCategoriesCompanion.insert(
              id: category.id,
              name: category.displayName,
              currency: Value(category.currencyCode),
              icon: Value(category.icon),
              sortOrder: Value(category.sortOrder),
            ),
        ],
      );
    });
  }

  /// 清空用户数据，保留品类字典。
  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(priceSnapshots).go();
      await delete(assetHoldings).go();
    });
  }
}
