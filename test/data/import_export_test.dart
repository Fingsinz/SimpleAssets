import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/core/import_limits.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/data/repositories/import_export_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/entities/asset_transaction_draft.dart';
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
      if (item['categoryId'] == 'cash') {
        item['amount'] = '88';
        item['cashRecords'] = [
          {
            'amount': '88',
            'recordDate': '2025-02-01T00:00:00.000',
          },
        ];
      } else {
        item['quantity'] = '99';
        item['costPrice'] = '2';
        item['transactions'] = [
          {
            'type': 'buy',
            'quantity': '99',
            'price': '2',
            'amount': '198',
            'fee': '0',
            'ratio': null,
            'date': '2025-03-01T00:00:00.000',
            'notes': null,
          },
        ];
        final priceHistory =
            (item['priceHistory'] as List?)?.cast<Map<String, dynamic>>();
        if (priceHistory != null && priceHistory.isNotEmpty) {
          priceHistory.first['price'] = '4.4';
        }
      }
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

    final fund = holdings.firstWhere((h) => h.categoryId == 'fund');
    expect(fund.quantity, Decimal.parse('99'));
    expect(fund.costPrice, Decimal.parse('2'));
    expect(fund.notes, '覆盖更新');
    final fundPoints = await assets.getPriceHistory(fund.id);
    expect(fundPoints, hasLength(1));
    expect(fundPoints.single.price, Decimal.parse('4.4'));

    final cash = holdings.firstWhere((h) => h.isCash);
    expect(cash.amount, Decimal.parse('88'));
    expect(cash.notes, '覆盖更新');
    final cashRecords = await assets.getCashRecords(cash.id);
    expect(cashRecords, hasLength(1));
    expect(cashRecords.single.amount, Decimal.parse('88'));
  });

  test('JSON 导出包含现金金额与历史记录', () async {
    await seed();
    final cash = (await assets.getHoldings()).firstWhere((h) => h.isCash);
    await assets.addCashRecord(
      cash.id,
      Decimal.parse('60000'),
      DateTime(2025, 10, 1),
    );

    final exported = await importExport.exportJson();
    expect(exported.isSuccess, isTrue);
    final payload =
        jsonDecode(utf8.decode(exported.data!)) as Map<String, dynamic>;

    expect(payload['version'], 3);
    final cashItem = (payload['holdings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((item) => item['categoryId'] == 'cash');
    expect(cashItem['amount'], '60000');
    expect(cashItem['cashRecords'], hasLength(2));
  });

  test('JSON 现金记录往返保留', () async {
    await seed();
    final cash = (await assets.getHoldings()).firstWhere((h) => h.isCash);
    await assets.addCashRecord(
      cash.id,
      Decimal.parse('60000'),
      DateTime(2025, 10, 1),
    );

    final exported = await importExport.exportJson();
    await assets.clearAllData();

    final imported = await importExport.importJson(exported.data!);
    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 2);

    final restored = (await assets.getHoldings()).firstWhere((h) => h.isCash);
    expect(restored.amount, Decimal.parse('60000'));
    expect(restored.purchaseDate, DateTime(2025, 10, 1));
    final records = await assets.getCashRecords(restored.id);
    expect(records, hasLength(2));
    expect(records.first.amount, Decimal.parse('60000'));
    expect(records.last.amount, Decimal.parse('5000'));
  });

  test('旧版 JSON 无 amount 与 unit 时兼容', () async {
    final payload = {
      'version': 1,
      'holdings': [
        {
          'categoryId': 'cash',
          'name': '招商银行',
          'quantity': '5000',
          'costPrice': '1',
          'purchaseDate': '2025-01-01T00:00:00.000',
        },
        {
          'categoryId': 'gold',
          'name': '黄金',
          'quantity': '10',
          'costPrice': '600',
          'currentPrice': '700',
          'purchaseDate': '2025-01-01T00:00:00.000',
        },
      ],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final imported = await importExport.importJson(bytes);
    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 2);

    final holdings = await assets.getHoldings();
    final cash = holdings.firstWhere((h) => h.isCash);
    expect(cash.amount, Decimal.parse('5000'));
    final cashRecords = await assets.getCashRecords(cash.id);
    expect(cashRecords, hasLength(1));
    expect(cashRecords.single.amount, Decimal.parse('5000'));

    final gold = holdings.firstWhere((h) => h.isPreciousMetal);
    expect(gold.unit, '克');
    expect(gold.quantity, Decimal.parse('10'));
    expect(gold.currentPrice, Decimal.parse('700'));
    final goldTransactions = await assets.getTransactions(gold.id);
    expect(goldTransactions, hasLength(1));
    expect(goldTransactions.single.type, TransactionType.buy);
    expect(goldTransactions.single.quantity, Decimal.parse('10'));
  });

  test('覆盖导入替换现金历史记录', () async {
    await seed();
    final cash = (await assets.getHoldings()).firstWhere((h) => h.isCash);
    await assets.addCashRecord(
      cash.id,
      Decimal.parse('60000'),
      DateTime(2025, 10, 1),
    );

    final payload = {
      'version': 2,
      'holdings': [
        {
          'categoryId': 'cash',
          'name': '活期现金',
          'quantity': '0',
          'costPrice': '0',
          'amount': '70000',
          'purchaseDate': '2025-11-01T00:00:00.000',
          'cashRecords': [
            {
              'amount': '70000',
              'recordDate': '2025-11-01T00:00:00.000',
            },
          ],
        },
      ],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final imported = await importExport.importJson(
      bytes,
      duplicates: DuplicatePolicy.overwrite,
    );
    expect(imported.isSuccess, isTrue);
    expect(imported.data!.updated, 1);

    final restored = (await assets.getHoldings()).firstWhere((h) => h.isCash);
    expect(restored.amount, Decimal.parse('70000'));
    final records = await assets.getCashRecords(restored.id);
    expect(records, hasLength(1));
    expect(records.single.amount, Decimal.parse('70000'));
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

  test('Excel 导出包含金额单位与现金记录表', () async {
    await seed();
    final cash = (await assets.getHoldings()).firstWhere((h) => h.isCash);
    await assets.addCashRecord(
      cash.id,
      Decimal.parse('60000'),
      DateTime(2025, 10, 1),
    );

    final exported = await importExport.exportExcel();
    expect(exported.isSuccess, isTrue);

    final excel = Excel.decodeBytes(exported.data!);
    final sheet = excel.tables['持仓']!;
    final header =
        sheet.rows.first.map((cell) => cell?.value?.toString()).toList();
    expect(header, containsAll(['金额', '单位']));
    expect(excel.tables.containsKey('现金记录'), isTrue);
  });

  test('Excel 现金记录往返保留', () async {
    await seed();
    final cash = (await assets.getHoldings()).firstWhere((h) => h.isCash);
    await assets.addCashRecord(
      cash.id,
      Decimal.parse('60000'),
      DateTime(2025, 10, 1),
    );

    final exported = await importExport.exportExcel();
    await assets.clearAllData();

    final imported = await importExport.importExcel(exported.data!);
    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 2);

    final restored = (await assets.getHoldings()).firstWhere((h) => h.isCash);
    expect(restored.amount, Decimal.parse('60000'));
    final records = await assets.getCashRecords(restored.id);
    expect(records, hasLength(2));
    expect(records.first.amount, Decimal.parse('60000'));
    expect(records.last.amount, Decimal.parse('5000'));
  });

  test('旧版 Excel 无金额单位列且品类名为黄金时兼容', () async {
    final excel = Excel.createExcel();
    final sheet = excel['持仓'];
    excel.delete('Sheet1');
    sheet.appendRow(
      ['品类', '名称', '代码', '数量', '成本价', '现价', '买入日期', '备注']
          .map((header) => TextCellValue(header))
          .toList(),
    );
    sheet.appendRow([
      TextCellValue('现金'),
      TextCellValue('招商银行'),
      TextCellValue(''),
      TextCellValue('5000'),
      TextCellValue('1'),
      TextCellValue(''),
      TextCellValue('2025-01-01'),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('黄金'),
      TextCellValue('黄金'),
      TextCellValue(''),
      TextCellValue('10'),
      TextCellValue('600'),
      TextCellValue('700'),
      TextCellValue('2025-01-01'),
      TextCellValue(''),
    ]);
    final bytes = Uint8List.fromList(excel.save()!);

    final imported = await importExport.importExcel(bytes);
    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 2);

    final holdings = await assets.getHoldings();
    final cash = holdings.firstWhere((h) => h.isCash);
    expect(cash.amount, Decimal.parse('5000'));
    final cashRecords = await assets.getCashRecords(cash.id);
    expect(cashRecords, hasLength(1));
    expect(cashRecords.single.amount, Decimal.parse('5000'));

    final gold = holdings.firstWhere((h) => h.isPreciousMetal);
    expect(gold.unit, '克');
    expect(gold.quantity, Decimal.parse('10'));
    expect(gold.categoryName, '贵金属');
    final goldTransactions = await assets.getTransactions(gold.id);
    expect(goldTransactions, hasLength(1));
    expect(goldTransactions.single.type, TransactionType.buy);
  });

  test('跳过策略下不覆盖已存在现金平台的记录', () async {
    await seed();
    final cash = (await assets.getHoldings()).firstWhere((h) => h.isCash);
    await assets.addCashRecord(
      cash.id,
      Decimal.parse('60000'),
      DateTime(2025, 10, 1),
    );
    final exported = await importExport.exportExcel();

    final imported = await importExport.importExcel(exported.data!);

    expect(imported.isSuccess, isTrue);
    expect(imported.data!.skipped, 2);
    final records = await assets.getCashRecords(cash.id);
    expect(records, hasLength(2));
  });

  test('JSON 同名现金平台导入时报错且不合并记录', () async {
    final payload = {
      'version': 2,
      'holdings': [
        {
          'categoryId': 'cash',
          'name': '招商银行',
          'code': 'A',
          'amount': '5000',
          'purchaseDate': '2025-01-01T00:00:00.000',
        },
        {
          'categoryId': 'cash',
          'name': '招商银行',
          'code': 'B',
          'amount': '6000',
          'purchaseDate': '2025-02-01T00:00:00.000',
        },
      ],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final imported = await importExport.importJson(bytes);

    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 0);
    expect(imported.data!.errors, isNotEmpty);
    expect(await assets.getHoldings(), isEmpty);
  });

  test('数据库中已有同名现金平台时导入报错', () async {
    await assets.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '招商银行',
        amount: Decimal.parse('5000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    await assets.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '招商银行',
        amount: Decimal.parse('6000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2025, 2, 1),
      ),
    );

    final payload = {
      'version': 2,
      'holdings': [
        {
          'categoryId': 'cash',
          'name': '招商银行',
          'amount': '7000',
          'purchaseDate': '2025-03-01T00:00:00.000',
        },
      ],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final imported = await importExport.importJson(bytes);

    expect(imported.isSuccess, isTrue);
    expect(imported.data!.errors, isNotEmpty);
    expect(await assets.getHoldings(), hasLength(2));
  });

  test('Excel 同名现金平台导入时报错', () async {
    final excel = Excel.createExcel();
    final sheet = excel['持仓'];
    excel.delete('Sheet1');
    sheet.appendRow(
      ['品类', '名称', '代码', '数量', '成本价', '现价', '买入日期', '备注', '金额', '单位']
          .map((header) => TextCellValue(header))
          .toList(),
    );
    sheet.appendRow([
      TextCellValue('现金'),
      TextCellValue('招商银行'),
      TextCellValue('A'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('2025-01-01'),
      TextCellValue(''),
      TextCellValue('5000'),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('现金'),
      TextCellValue('招商银行'),
      TextCellValue('B'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('2025-02-01'),
      TextCellValue(''),
      TextCellValue('6000'),
      TextCellValue(''),
    ]);
    final history = excel['现金记录'];
    history.appendRow([
      TextCellValue('平台'),
      TextCellValue('金额'),
      TextCellValue('记录日期'),
    ]);
    history.appendRow([
      TextCellValue('招商银行'),
      TextCellValue('5000'),
      TextCellValue('2025-01-01'),
    ]);
    history.appendRow([
      TextCellValue('招商银行'),
      TextCellValue('6000'),
      TextCellValue('2025-02-01'),
    ]);
    final bytes = Uint8List.fromList(excel.save()!);

    final imported = await importExport.importExcel(bytes);

    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 0);
    expect(imported.data!.errors, isNotEmpty);
    expect(await assets.getHoldings(), isEmpty);
  });

  test('JSON 导入拒绝未来或无法解析的日期', () async {
    final payload = {
      'version': 2,
      'holdings': [
        {
          'categoryId': 'cash',
          'name': '未来现金',
          'amount': '5000',
          'purchaseDate': '2999-01-01T00:00:00.000',
        },
        {
          'categoryId': 'cash',
          'name': '日期错误现金',
          'amount': '6000',
          'purchaseDate': 'not-a-date',
        },
      ],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final imported = await importExport.importJson(bytes);

    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 0);
    expect(imported.data!.skipped, 2);
    expect(imported.data!.errors, hasLength(2));
    expect(await assets.getHoldings(), isEmpty);
  });

  test('Excel 导入拒绝无法解析的日期', () async {
    final excel = Excel.createExcel();
    final sheet = excel['持仓'];
    excel.delete('Sheet1');
    sheet.appendRow(
      ['品类', '名称', '代码', '数量', '成本价', '现价', '买入日期', '备注', '金额', '单位']
          .map((header) => TextCellValue(header))
          .toList(),
    );
    sheet.appendRow([
      TextCellValue('现金'),
      TextCellValue('招商银行'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('not-a-date'),
      TextCellValue(''),
      TextCellValue('5000'),
      TextCellValue(''),
    ]);
    final bytes = Uint8List.fromList(excel.save()!);

    final imported = await importExport.importExcel(bytes);

    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 0);
    expect(imported.data!.skipped, 1);
    expect(imported.data!.errors, isNotEmpty);
    expect(await assets.getHoldings(), isEmpty);
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

  test('JSON v3 导出包含流水、手续费与价格历史', () async {
    await seed();
    final fund = (await assets.getHoldings()).firstWhere((h) => !h.isCash);
    await assets.addTransaction(
      AssetTransactionDraft(
        holdingId: fund.id,
        type: TransactionType.dividend,
        amount: Decimal.parse('50'),
        fee: Decimal.parse('5'),
        date: DateTime(2025, 4, 1),
      ),
    );

    final exported = await importExport.exportJson();
    expect(exported.isSuccess, isTrue);
    final payload =
        jsonDecode(utf8.decode(exported.data!)) as Map<String, dynamic>;
    expect(payload['version'], 3);
    final item = (payload['holdings'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((row) => row['categoryId'] == 'fund');
    final transactions = item['transactions'] as List;
    expect(transactions, hasLength(2));
    expect(transactions.last['type'], 'dividend');
    expect(transactions.last['fee'], '5');
    expect((item['priceHistory'] as List), isNotEmpty);
  });

  test('JSON v3 往返保留流水与价格历史', () async {
    await seed();
    final fund = (await assets.getHoldings()).firstWhere((h) => !h.isCash);
    await assets.addTransaction(
      AssetTransactionDraft(
        holdingId: fund.id,
        type: TransactionType.dividend,
        amount: Decimal.parse('50'),
        date: DateTime(2025, 4, 1),
      ),
    );
    final exported = await importExport.exportJson();

    await assets.clearAllData();
    final imported = await importExport.importJson(exported.data!);
    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 2);

    final restored = (await assets.getHoldings())
        .firstWhere((h) => !h.isCash);
    expect(restored.quantity, Decimal.parse('1000'));
    final transactions = await assets.getTransactions(restored.id);
    expect(transactions, hasLength(2));
    expect(transactions.map((t) => t.type), contains(TransactionType.buy));
    expect(
      transactions.map((t) => t.type),
      contains(TransactionType.dividend),
    );
    expect(await assets.getPriceHistory(restored.id), isNotEmpty);
  });

  test('Excel 导出包含交易流水与价格历史表', () async {
    await seed();
    final exported = await importExport.exportExcel();
    expect(exported.isSuccess, isTrue);

    final excel = Excel.decodeBytes(exported.data!);
    expect(excel.tables.containsKey('交易流水'), isTrue);
    expect(excel.tables.containsKey('价格历史'), isTrue);
    final header = excel.tables['交易流水']!.rows.first
        .map((cell) => cell?.value?.toString())
        .toList();
    expect(header, containsAll(['类型', '手续费', '折算比例']));
  });

  test('Excel 新格式往返保留交易流水', () async {
    await seed();
    final exported = await importExport.exportExcel();
    await assets.clearAllData();

    final imported = await importExport.importExcel(exported.data!);
    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 2);

    final restored = (await assets.getHoldings())
        .firstWhere((h) => !h.isCash);
    expect(restored.quantity, Decimal.parse('1000'));
    final transactions = await assets.getTransactions(restored.id);
    expect(transactions, hasLength(1));
    expect(transactions.single.type, TransactionType.buy);
    expect(transactions.single.quantity, Decimal.parse('1000'));
  });

  test('旧版 JSON 导入的 currentPrice 写入当月价格历史', () async {
    final payload = {
      'version': 2,
      'holdings': [
        {
          'categoryId': 'fund',
          'name': '旧版基金',
          'quantity': '100',
          'costPrice': '10',
          'currentPrice': '12',
          'purchaseDate': '2025-01-01T00:00:00.000',
        },
      ],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final imported = await importExport.importJson(bytes);
    expect(imported.isSuccess, isTrue);

    final fund = (await assets.getHoldings()).single;
    final points = await assets.getPriceHistory(fund.id);
    expect(points, isNotEmpty);
    expect(points.last.price, Decimal.parse('12'));
  });

  test('JSON v3 非法流水组整组跳过', () async {
    final payload = {
      'version': 3,
      'holdings': [
        {
          'categoryId': 'fund',
          'name': '非法基金',
          'code': '000001',
          'transactions': [
            {
              'type': 'buy',
              'quantity': '100',
              'price': '10',
              'date': '2025-01-01T00:00:00.000',
            },
            {
              'type': 'sell',
              'quantity': '200',
              'price': '12',
              'date': '2025-02-01T00:00:00.000',
            },
          ],
        },
      ],
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

    final imported = await importExport.importJson(bytes);

    expect(imported.isSuccess, isTrue);
    expect(imported.data!.imported, 0);
    expect(imported.data!.skipped, 1);
    expect(imported.data!.errors, isNotEmpty);
    expect(await assets.getHoldings(), isEmpty);
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
