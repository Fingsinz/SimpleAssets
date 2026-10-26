import 'dart:io';

import 'package:decimal/decimal.dart';
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
    expect(gold.unit, '10克');
    expect(gold.quantity, Decimal.parse('10'));
    expect(gold.costPrice, Decimal.parse('600'));
    expect(gold.currentPrice, Decimal.parse('700'));
  });
}
