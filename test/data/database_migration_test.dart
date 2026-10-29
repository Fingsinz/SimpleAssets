import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';

void main() {
  test('关闭后重新打开数据库保留数据且不重复初始化品类', () async {
    final directory = await Directory.systemTemp.createTemp(
      'simple_assets_migration',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/simple_assets.sqlite');

    final first = AppDatabase.forTesting(NativeDatabase(file));
    await AssetRepositoryImpl(first).addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '迁移测试基金',
        code: '000001',
        quantity: Decimal.parse('10'),
        costPrice: Decimal.parse('1'),
        purchaseDate: DateTime(2026, 1, 1),
      ),
    );
    await first.close();

    final reopened = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(reopened.close);
    final repository = AssetRepositoryImpl(reopened);

    final holdings = await repository.watchHoldings().first;
    expect(holdings, hasLength(1));
    expect(holdings.single.name, '迁移测试基金');
    expect(await repository.getCategories(), hasLength(6));
  });

  test('v1 数据库迁移到 v2 保留现金与黄金数据', () async {
    final directory = await Directory.systemTemp.createTemp('simple_assets_v1');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/simple_assets.sqlite');
    final openedAt = DateTime(2025, 1, 1).millisecondsSinceEpoch ~/ 1000;

    final database = AppDatabase.forTesting(
      NativeDatabase(file, setup: (db) {
        db.execute('''
          CREATE TABLE asset_categories (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            currency TEXT NOT NULL DEFAULT 'CNY',
            icon TEXT,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
        db.execute('''
          CREATE TABLE asset_holdings (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            category_id TEXT NOT NULL REFERENCES asset_categories (id),
            name TEXT NOT NULL,
            code TEXT,
            quantity TEXT NOT NULL,
            cost_price TEXT NOT NULL,
            current_price TEXT,
            purchase_date INTEGER NOT NULL,
            notes TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        db.execute('''
          CREATE TABLE transactions (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            holding_id INTEGER NOT NULL REFERENCES asset_holdings (id) ON DELETE CASCADE,
            type TEXT NOT NULL,
            amount TEXT,
            price TEXT,
            quantity TEXT,
            date INTEGER NOT NULL,
            notes TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE price_snapshots (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL,
            source TEXT NOT NULL,
            price TEXT NOT NULL,
            currency TEXT NOT NULL DEFAULT 'CNY',
            timestamp INTEGER NOT NULL
          )
        ''');
        db.execute(
          "INSERT INTO asset_categories (id, name, currency, icon, sort_order) "
          "VALUES ('cash','现金','CNY','cash',0), ('gold','黄金','CNY','gold',5)",
        );
        db.execute(
          "INSERT INTO asset_holdings (category_id, name, quantity, cost_price, "
          "purchase_date, created_at, updated_at) "
          "VALUES ('cash','招商银行','5000','1',?,?,?)",
          [openedAt, openedAt, openedAt],
        );
        db.execute(
          "INSERT INTO asset_holdings (category_id, name, quantity, cost_price, "
          "current_price, purchase_date, created_at, updated_at) "
          "VALUES ('gold','黄金','10','600','700',?,?,?)",
          [openedAt, openedAt, openedAt],
        );
        db.execute('PRAGMA user_version = 1');
      }),
    );
    addTearDown(database.close);

    final repository = AssetRepositoryImpl(database);
    final holdings = await repository.watchHoldings().first;
    expect(holdings, hasLength(2));

    final cash = holdings.firstWhere((h) => h.categoryId == 'cash');
    expect(cash.amount, Decimal.parse('5000'));
    expect(cash.quantity, Decimal.zero);
    expect(cash.costPrice, Decimal.zero);
    expect(cash.purchaseDate, DateTime(2025, 1, 1));
    final cashRecords = await database.cashRecordDao.getForHolding(cash.id);
    expect(cashRecords, hasLength(1));
    expect(cashRecords.single.amount, '5000');

    final gold = holdings.firstWhere((h) => h.categoryId == 'gold');
    expect(gold.categoryName, '贵金属');
    expect(gold.unit, '克');
    expect(gold.quantity, Decimal.parse('10'));
    expect(gold.costPrice, Decimal.parse('600'));
    expect(gold.currentPrice, Decimal.parse('700'));
    expect(gold.purchaseDate, DateTime(2025, 1, 1));

    final goldTxns = await database.customSelect(
      'SELECT type, quantity, fee FROM transactions WHERE holding_id = ?',
      variables: [Variable(gold.id)],
    ).get();
    expect(goldTxns, hasLength(1));
    expect(goldTxns.single.read<String>('type'), 'buy');
    expect(goldTxns.single.read<String>('quantity'), '10');
    expect(goldTxns.single.read<String>('fee'), '0');

    final snapshots = await database.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='price_snapshots'",
    ).get();
    expect(snapshots, isEmpty);
  });

  test('v2 数据库迁移到 v3 转换快照、期初流水与单位', () async {
    final directory = await Directory.systemTemp.createTemp('simple_assets_v2');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/simple_assets.sqlite');
    final jan1 = DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;
    final jan15 = DateTime(2026, 1, 15).millisecondsSinceEpoch ~/ 1000;
    final jan20 = DateTime(2026, 1, 20).millisecondsSinceEpoch ~/ 1000;
    final feb20 = DateTime(2026, 2, 20).millisecondsSinceEpoch ~/ 1000;

    final database = AppDatabase.forTesting(
      NativeDatabase(file, setup: (db) {
        db.execute('''
          CREATE TABLE asset_categories (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            currency TEXT NOT NULL DEFAULT 'CNY',
            icon TEXT,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
        db.execute('''
          CREATE TABLE asset_holdings (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            category_id TEXT NOT NULL REFERENCES asset_categories (id),
            name TEXT NOT NULL,
            code TEXT,
            unit TEXT,
            amount TEXT,
            quantity TEXT NOT NULL,
            cost_price TEXT NOT NULL,
            current_price TEXT,
            purchase_date INTEGER NOT NULL,
            notes TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        db.execute('''
          CREATE TABLE cash_records (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            holding_id INTEGER NOT NULL REFERENCES asset_holdings (id) ON DELETE CASCADE,
            amount TEXT NOT NULL,
            record_date INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        db.execute('''
          CREATE TABLE transactions (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            holding_id INTEGER NOT NULL REFERENCES asset_holdings (id) ON DELETE CASCADE,
            type TEXT NOT NULL,
            amount TEXT,
            price TEXT,
            quantity TEXT,
            date INTEGER NOT NULL,
            notes TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE price_snapshots (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL,
            source TEXT NOT NULL,
            price TEXT NOT NULL,
            currency TEXT NOT NULL DEFAULT 'CNY',
            timestamp INTEGER NOT NULL
          )
        ''');
        db.execute(
          "INSERT INTO asset_categories (id, name, currency, icon, sort_order) "
          "VALUES ('cash','现金','CNY','cash',0), ('fund','基金','CNY','fund',2), "
          "('stock','股票','CNY','stock',3), ('gold','贵金属','CNY','gold',5)",
        );
        db.execute(
          "INSERT INTO asset_holdings (id, category_id, name, code, unit, amount, "
          "quantity, cost_price, current_price, purchase_date, notes, created_at, updated_at) "
          "VALUES (1,'fund','测试基金','000001',NULL,NULL,'100','10','12',?,NULL,?,?)",
          [jan1, jan1, feb20],
        );
        db.execute(
          "INSERT INTO asset_holdings (id, category_id, name, code, unit, amount, "
          "quantity, cost_price, current_price, purchase_date, notes, created_at, updated_at) "
          "VALUES (2,'stock','测试股票','000001',NULL,NULL,'10','100','110',?,NULL,?,?)",
          [jan1, jan1, feb20],
        );
        db.execute(
          "INSERT INTO asset_holdings (id, category_id, name, code, unit, amount, "
          "quantity, cost_price, current_price, purchase_date, notes, created_at, updated_at) "
          "VALUES (3,'gold','黄金',NULL,'10克',NULL,'10','600','700',?,NULL,?,?)",
          [jan1, jan1, feb20],
        );
        db.execute(
          "INSERT INTO asset_holdings (id, category_id, name, code, unit, amount, "
          "quantity, cost_price, current_price, purchase_date, notes, created_at, updated_at) "
          "VALUES (4,'cash','活期',NULL,NULL,'5000','0','0',NULL,?,NULL,?,?)",
          [jan1, jan1, jan1],
        );
        db.execute(
          "INSERT INTO price_snapshots (code, source, price, currency, timestamp) "
          "VALUES ('000001','天天基金','11','CNY',?), "
          "('000001','天天基金','12','CNY',?), "
          "('000001','新浪财经','99','CNY',?)",
          [jan15, feb20, jan20],
        );
        db.execute('PRAGMA user_version = 2');
      }),
    );
    addTearDown(database.close);

    final repository = AssetRepositoryImpl(database);
    final holdings = await repository.watchHoldings().first;
    final fund = holdings.firstWhere((item) => item.name == '测试基金');
    final stock = holdings.firstWhere((item) => item.name == '测试股票');
    final gold = holdings.firstWhere((item) => item.name == '黄金');
    final cash = holdings.firstWhere((item) => item.isCash);
    expect(fund.purchaseDate, DateTime(2026, 1, 1));
    expect(gold.purchaseDate, DateTime(2026, 1, 1));

    final fundHistory = await database.priceHistoryDao.getForHolding(fund.id);
    expect(fundHistory.map((row) => row.period), containsAll(['2026-01', '2026-02']));
    expect(fundHistory.any((row) => row.price == '99'), isFalse);
    expect(
      fundHistory.firstWhere((row) => row.period == '2026-01').price,
      '11',
    );
    expect(
      fundHistory.firstWhere((row) => row.period == '2026-02').price,
      '12',
    );

    final stockHistory =
        await database.priceHistoryDao.getForHolding(stock.id);
    expect(stockHistory.any((row) => row.price == '99'), isTrue);
    expect(stockHistory.any((row) => row.price == '11'), isFalse);

    final fundTxns = await database.customSelect(
      'SELECT type, quantity, fee FROM transactions WHERE holding_id = ?',
      variables: [Variable(fund.id)],
    ).get();
    expect(fundTxns, hasLength(1));
    expect(fundTxns.single.read<String>('type'), 'buy');
    expect(fundTxns.single.read<String>('quantity'), '100');
    expect(fundTxns.single.read<String>('fee'), '0');

    final cashTxns = await database.customSelect(
      'SELECT id FROM transactions WHERE holding_id = ?',
      variables: [Variable(cash.id)],
    ).get();
    expect(cashTxns, isEmpty);

    final goldRow = await database.assetDao.getHoldingById(gold.id);
    expect(goldRow!.holding.unit, '克');

    final tableInfo = await database
        .customSelect("PRAGMA table_info('transactions')")
        .get();
    expect(
      tableInfo.map((row) => row.read<String>('name')),
      containsAll(['fee', 'ratio']),
    );

    final snapshots = await database.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='price_snapshots'",
    ).get();
    expect(snapshots, isEmpty);
  });

  test('清空用户数据后压缩数据库，不保留已删除页', () async {
    final directory = await Directory.systemTemp.createTemp(
      'simple_assets_clear',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/simple_assets.sqlite');
    final database = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(database.close);

    final repository = AssetRepositoryImpl(database);
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '清空测试基金',
        code: '000001',
        quantity: Decimal.parse('10'),
        costPrice: Decimal.parse('1'),
        purchaseDate: DateTime(2026, 1, 1),
      ),
    );
    final holdingId = (await repository.watchHoldings().first).single.id;

    await database.batch((batch) {
      batch.insertAll(database.transactions, [
        for (var i = 0; i < 800; i++)
          TransactionsCompanion.insert(
            holdingId: holdingId,
            type: 'buy',
            price: const Value('1'),
            quantity: const Value('1'),
            date: DateTime(2026, 1, 1),
            notes: Value('用于填充数据库页的测试流水 $i'),
          ),
      ]);
    });

    expect(
      await _pageCount(database),
      greaterThan(1),
      reason: '前置条件：数据应占用多页',
    );

    await database.clearUserData();

    expect(
      await _freelistCount(database),
      0,
      reason: '清空后应执行 VACUUM，空闲页不再保留已删除的行',
    );
    for (final table in [
      'transactions',
      'price_history',
      'cash_records',
      'asset_holdings',
    ]) {
      final row = await database
          .customSelect('SELECT COUNT(*) AS total FROM $table')
          .getSingle();
      expect(row.read<int>('total'), 0, reason: '$table 应被清空');
    }
  });
}

Future<int> _pageCount(AppDatabase database) async {
  final row = await database.customSelect('PRAGMA page_count').getSingle();
  return row.read<int>('page_count');
}

Future<int> _freelistCount(AppDatabase database) async {
  final row = await database.customSelect('PRAGMA freelist_count').getSingle();
  return row.read<int>('freelist_count');
}
