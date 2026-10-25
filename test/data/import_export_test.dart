import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/core/import_limits.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/data/repositories/import_export_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/domain/repositories/import_export_repository.dart';

void main() {
  late AppDatabase database;
  late AssetRepositoryImpl assets;
  late ImportExportRepository importExport;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    assets = AssetRepositoryImpl(database);
    importExport = ImportExportRepositoryImpl(database);
  });

  tearDown(() => database.close());

  Future<void> seed() async {
    await assets.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '沪深300ETF',
        code: '510300',
        quantity: Decimal.parse('1000'),
        costPrice: Decimal.parse('3.5'),
        currentPrice: Decimal.parse('3.8'),
        purchaseDate: DateTime(2025, 3, 1),
        notes: '长期持有',
      ),
    );
    await assets.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '活期现金',
        quantity: Decimal.parse('5000'),
        costPrice: Decimal.one,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
  }

  test('JSON 导出后可以完整导入', () async {
    await seed();

    final exported = await importExport.exportJson();
    expect(exported.isSuccess, isTrue);
    expect(exported.data, isNotNull);

    await assets.clearAllData();
    expect(await assets.watchHoldings().first, isEmpty);

    final imported = await importExport.importJson(exported.data!);
    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 2);
    expect(imported.data!.skipped, 0);

    final holdings = await assets.watchHoldings().first;
    expect(holdings, hasLength(2));
    final fund = holdings.firstWhere((item) => item.categoryId == 'fund');
    expect(fund.name, '沪深300ETF');
    expect(fund.code, '510300');
    expect(fund.quantity, Decimal.parse('1000'));
    expect(fund.currentPrice, Decimal.parse('3.8'));
    expect(fund.notes, '长期持有');
  });

  test('JSON 导入跳过非法品类与缺失字段', () async {
    final result = await importExport.importJson(
      ImportExportRepositoryTestData.invalidJson(),
    );

    expect(result.isSuccess, isTrue);
    final summary = result.data!;
    expect(summary.imported, 1);
    expect(summary.skipped, 2);
    expect(summary.errors, hasLength(2));
  });

  test('Excel 导出后可以完整导入', () async {
    await seed();

    final exported = await importExport.exportExcel();
    expect(exported.isSuccess, isTrue);
    expect(exported.data, isNotNull);

    await assets.clearAllData();

    final imported = await importExport.importExcel(exported.data!);
    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 2);
    expect(imported.data!.skipped, 0);

    final holdings = await assets.watchHoldings().first;
    expect(holdings, hasLength(2));
    final fund = holdings.firstWhere((item) => item.categoryId == 'fund');
    expect(fund.name, '沪深300ETF');
    expect(fund.code, '510300');
    expect(fund.quantity, Decimal.parse('1000'));
    expect(fund.costPrice, Decimal.parse('3.5'));
    expect(fund.currentPrice, Decimal.parse('3.8'));
    expect(fund.notes, '长期持有');
  });

  test('JSON 重复导入默认跳过重复持仓', () async {
    await seed();
    final exported = await importExport.exportJson();

    final imported = await importExport.importJson(exported.data!);

    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 0);
    expect(imported.data!.updated, 0);
    expect(imported.data!.skipped, 2);
    expect(await assets.watchHoldings().first, hasLength(2));
  });

  test('JSON 重复导入可覆盖更新已有持仓', () async {
    await seed();
    final exported = await importExport.exportJson();
    final payload =
        jsonDecode(utf8.decode(exported.data!)) as Map<String, dynamic>;
    for (final item
        in (payload['holdings'] as List).cast<Map<String, dynamic>>()) {
      item['quantity'] = '99';
      item['costPrice'] = '2';
      item['notes'] = '覆盖更新';
    }
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final imported = await importExport.importJson(
      bytes,
      duplicates: DuplicatePolicy.overwrite,
    );

    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 0);
    expect(imported.data!.updated, 2);
    expect(imported.data!.skipped, 0);
    final holdings = await assets.watchHoldings().first;
    expect(holdings, hasLength(2));
    for (final holding in holdings) {
      expect(holding.quantity, Decimal.parse('99'));
      expect(holding.costPrice, Decimal.parse('2'));
      expect(holding.notes, '覆盖更新');
    }
  });

  test('Excel 重复导入默认跳过重复持仓', () async {
    await seed();
    final exported = await importExport.exportExcel();

    final imported = await importExport.importExcel(exported.data!);

    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 0);
    expect(imported.data!.skipped, 2);
    expect(await assets.watchHoldings().first, hasLength(2));
  });

  test('导入拒绝超过大小上限的文件', () async {
    final bytes = Uint8List(ImportLimits.maxBytes + 1);

    final result = await importExport.importJson(bytes);

    expect(result.isFailure, isTrue);
    expect(result.error, contains('10MB'));
    expect(await assets.watchHoldings().first, isEmpty);
  });

  test('JSON 导入拒绝超过行数上限的文件', () async {
    final holdings = List.generate(
      ImportLimits.maxRows + 1,
      (index) => {
        'categoryId': 'cash',
        'name': '现金$index',
        'quantity': '1',
        'costPrice': '1',
      },
    );
    final bytes = Uint8List.fromList(
      utf8.encode(jsonEncode({'holdings': holdings})),
    );

    final result = await importExport.importJson(bytes);

    expect(result.isFailure, isTrue);
    expect(result.error, contains('${ImportLimits.maxRows}'));
    expect(await assets.watchHoldings().first, isEmpty);
  });
}

class ImportExportRepositoryTestData {
  static Uint8List invalidJson() {
    const text = '''
{
  "app": "SimpleAssets",
  "version": 1,
  "holdings": [
    {"categoryId": "fund", "name": "有效基金", "quantity": "10", "costPrice": "1.2", "purchaseDate": "2025-01-01T00:00:00.000"},
    {"categoryId": "unknown", "name": "未知品类", "quantity": "10", "costPrice": "1.2"},
    {"categoryId": "stock", "name": "", "quantity": "10", "costPrice": "1.2"}
  ]
}
''';
    return Uint8List.fromList(utf8.encode(text));
  }
}
