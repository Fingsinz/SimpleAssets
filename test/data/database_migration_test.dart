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
}
