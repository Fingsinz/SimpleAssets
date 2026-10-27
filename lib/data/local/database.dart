import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/constants.dart';
import '../../core/decimal_utils.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/usecases/parse_quantity_from_unit.dart';
import 'dao/asset_dao.dart';
import 'dao/cash_record_dao.dart';
import 'dao/price_history_dao.dart';
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
  /// 贵金属持有单位原文，如 `10克`。
  TextColumn get unit => text().nullable()();
  /// 现金最新金额。
  TextColumn get amount => text().nullable()();
  TextColumn get quantity => text()(); // Decimal 存为字符串，避免精度丢失
  TextColumn get costPrice => text()();
  TextColumn get currentPrice => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('CashRecordRow')
class CashRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get holdingId =>
      integer().references(AssetHoldings, #id, onDelete: KeyAction.cascade)();
  TextColumn get amount => text()();
  DateTimeColumn get recordDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get holdingId =>
      integer().references(AssetHoldings, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // buy, sell, dividend, split
  TextColumn get amount => text().nullable()();
  TextColumn get price => text().nullable()();
  TextColumn get quantity => text().nullable()();
  TextColumn get fee => text().withDefault(const Constant('0'))();
  TextColumn get ratio => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('PriceHistoryRow')
class PriceHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get holdingId =>
      integer().references(AssetHoldings, #id, onDelete: KeyAction.cascade)();
  /// YYYY-MM，按持仓唯一。
  TextColumn get period => text()();
  TextColumn get price => text()();
  TextColumn get currency => text().withDefault(const Constant('CNY'))();
  DateTimeColumn get observedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {holdingId, period},
      ];
}

// ---------------------------------------------------------------------------
// 数据库
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [
    AssetCategories,
    AssetHoldings,
    Transactions,
    PriceHistory,
    CashRecords,
  ],
  daos: [AssetDao, TransactionDao, PriceHistoryDao, CashRecordDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: AppConstants.databaseName));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          await _seedCategories();
        },
        onUpgrade: (migrator, from, to) async {
          // 未补齐迁移就提升版本会直接抛错，避免在结构不匹配时继续读写。
          if (to > 3) {
            throw StateError(
              '缺少数据库迁移：v$from → v$to，请勿直接提升 schemaVersion',
            );
          }
          if (from < 2) {
            await migrator.addColumn(assetHoldings, assetHoldings.unit);
            await migrator.addColumn(assetHoldings, assetHoldings.amount);
            await migrator.createTable(cashRecords);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS cash_records_holding_date '
              'ON cash_records (holding_id, record_date)',
            );
            await customStatement(
              "UPDATE asset_categories SET name = '贵金属' WHERE id = 'gold'",
            );
            await customStatement(
              'INSERT INTO cash_records (holding_id, amount, record_date, created_at) '
              "SELECT id, quantity, purchase_date, created_at FROM asset_holdings "
              "WHERE category_id = 'cash'",
            );
            await customStatement(
              "UPDATE asset_holdings SET amount = quantity, quantity = '0', "
              "cost_price = '0', current_price = NULL WHERE category_id = 'cash'",
            );
            await customStatement(
              "UPDATE asset_holdings SET unit = quantity || '克' "
              "WHERE category_id = 'gold'",
            );
          }
          if (from < 3) {
            await _migrateToV3(migrator);
          }
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

  /// v2 → v3：价格历史、交易手续费 / 折算比例、期初买入、贵金属单位。
  Future<void> _migrateToV3(Migrator migrator) async {
    await migrator.createTable(priceHistory);
    await migrator.addColumn(transactions, transactions.fee);
    await migrator.addColumn(transactions, transactions.ratio);

    // 旧快照按月折算成每个持仓一行；用 source 隔离同码不同品类。
    final snapshotRows = await customSelect(
      'SELECT code, source, price, timestamp FROM price_snapshots '
      'ORDER BY timestamp ASC',
    ).get();
    final snapshots = <String, _MigratedPrice>{};
    for (final row in snapshotRows) {
      final code = row.read<String>('code');
      final source = row.read<String>('source');
      final observedAt = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('timestamp') * 1000,
      );
      snapshots['$code\u0000$source\u0000${_monthKey(observedAt)}'] =
          _MigratedPrice(row.read<String>('price'), observedAt);
    }

    final holdingRows = await customSelect(
      'SELECT id, category_id, code, current_price, updated_at, '
      'quantity, cost_price, purchase_date FROM asset_holdings',
    ).get();

    const sourceByCategory = {
      'fund': '天天基金',
      'stock': '新浪财经',
      'etf': '新浪财经',
    };
    final inserted = <String>{};

    for (final row in holdingRows) {
      final holdingId = row.read<int>('id');
      final code = row.readNullable<String>('code');
      final source = sourceByCategory[row.read<String>('category_id')];
      if (code == null || code.isEmpty || source == null) continue;

      for (final entry in snapshots.entries) {
        final parts = entry.key.split('\u0000');
        if (parts[0] != code || parts[1] != source) continue;
        final period = parts[2];
        await into(priceHistory).insert(
          PriceHistoryCompanion.insert(
            holdingId: holdingId,
            period: period,
            price: entry.value.price,
            observedAt: entry.value.observedAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
        inserted.add('$holdingId\u0000$period');
      }
    }

    for (final row in holdingRows) {
      final holdingId = row.read<int>('id');
      final currentPrice = row.readNullable<String>('current_price');
      if (currentPrice == null || currentPrice.isEmpty) continue;
      final updatedAt = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('updated_at') * 1000,
      );
      final period = _monthKey(updatedAt);
      final key = '$holdingId\u0000$period';
      if (inserted.contains(key)) continue;
      await into(priceHistory).insert(
        PriceHistoryCompanion.insert(
          holdingId: holdingId,
          period: period,
          price: currentPrice,
          observedAt: updatedAt,
        ),
        mode: InsertMode.insertOrIgnore,
      );
      inserted.add(key);
    }

    for (final row in holdingRows) {
      if (row.read<String>('category_id') == AssetCategoryIds.cash) continue;
      final quantity = DecimalUtils.parseOrZero(row.read<String>('quantity'));
      if (quantity <= Decimal.zero) continue;
      final costPrice =
          DecimalUtils.parseOrZero(row.read<String>('cost_price'));
      final purchaseDate = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('purchase_date') * 1000,
      );
      await into(transactions).insert(
        TransactionsCompanion.insert(
          holdingId: row.read<int>('id'),
          type: 'buy',
          amount: Value((quantity * costPrice).toString()),
          price: Value(costPrice.toString()),
          quantity: Value(quantity.toString()),
          date: purchaseDate,
          notes: const Value('期初持仓'),
          fee: const Value('0'),
        ),
      );
    }

    final goldRows = await customSelect(
      "SELECT id, unit FROM asset_holdings WHERE category_id = 'gold'",
    ).get();
    for (final row in goldRows) {
      final label =
          ParseQuantityFromUnit.unitLabel(row.readNullable<String>('unit'));
      await customStatement(
        'UPDATE asset_holdings SET unit = ? WHERE id = ?',
        [label, row.read<int>('id')],
      );
    }

    await customStatement('DROP TABLE IF EXISTS price_snapshots');
  }

  String _monthKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';

  /// 清空用户数据，保留品类字典。
  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(priceHistory).go();
      await delete(cashRecords).go();
      await delete(assetHoldings).go();
    });
  }
}

class _MigratedPrice {
  final String price;
  final DateTime observedAt;

  const _MigratedPrice(this.price, this.observedAt);
}
