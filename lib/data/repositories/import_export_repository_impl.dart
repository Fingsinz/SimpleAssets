import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';

import '../../core/date_formatter.dart';
import '../../core/decimal_utils.dart';
import '../../core/result.dart';
import '../../domain/repositories/import_export_repository.dart';
import '../local/database.dart';

/// 导入/导出策略：新增格式只需实现该接口并在仓库中注册。
abstract class ImportExportStrategy {
  String get formatName;

  Future<Result<Uint8List>> exportData(AppDatabase db);

  Future<Result<ImportResult>> importData(AppDatabase db, Uint8List bytes);
}

class ImportExportRepositoryImpl implements ImportExportRepository {
  final AppDatabase _db;
  final ImportExportStrategy _json;
  final ImportExportStrategy _excel;

  ImportExportRepositoryImpl(this._db)
      : _json = JsonImportExportStrategy(),
        _excel = ExcelImportExportStrategy();

  @override
  Future<Result<Uint8List>> exportJson() => _json.exportData(_db);

  @override
  Future<Result<Uint8List>> exportExcel() => _excel.exportData(_db);

  @override
  Future<Result<ImportResult>> importJson(Uint8List bytes) =>
      _json.importData(_db, bytes);

  @override
  Future<Result<ImportResult>> importExcel(Uint8List bytes) =>
      _excel.importData(_db, bytes);
}

// ---------------------------------------------------------------------------
// JSON
// ---------------------------------------------------------------------------

class JsonImportExportStrategy implements ImportExportStrategy {
  @override
  String get formatName => 'JSON';

  @override
  Future<Result<Uint8List>> exportData(AppDatabase db) async {
    try {
      final rows = await db.assetDao.getAllHoldings();
      final payload = {
        'app': 'SimpleAssets',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'holdings': [
          for (final item in rows)
            {
              'categoryId': item.holding.categoryId,
              'categoryName': item.category?.name,
              'name': item.holding.name,
              'code': item.holding.code,
              'quantity': item.holding.quantity,
              'costPrice': item.holding.costPrice,
              'currentPrice': item.holding.currentPrice,
              'purchaseDate': item.holding.purchaseDate.toIso8601String(),
              'notes': item.holding.notes,
            },
        ],
      };
      final text = const JsonEncoder.withIndent('  ').convert(payload);
      return Result.success(Uint8List.fromList(utf8.encode(text)));
    } catch (e) {
      return Result.failure('导出 JSON 失败：$e');
    }
  }

  @override
  Future<Result<ImportResult>> importData(
    AppDatabase db,
    Uint8List bytes,
  ) async {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        return Result.failure('JSON 格式不正确');
      }
      final holdings = decoded['holdings'];
      if (holdings is! List) {
        return Result.failure('JSON 中缺少 holdings 数组');
      }

      final categories = await db.assetDao.getCategories();
      final validIds = categories.map((c) => c.id).toSet();

      var imported = 0;
      var skipped = 0;
      final errors = <String>[];

      for (var i = 0; i < holdings.length; i++) {
        final item = holdings[i];
        if (item is! Map<String, dynamic>) {
          skipped++;
          errors.add('第 ${i + 1} 条格式错误');
          continue;
        }
        final error = await _insertFromMap(db, item, validIds);
        if (error == null) {
          imported++;
        } else {
          skipped++;
          errors.add(error);
        }
      }

      return Result.success(ImportResult(
        imported: imported,
        skipped: skipped,
        errors: errors,
      ));
    } catch (e) {
      return Result.failure('导入 JSON 失败：$e');
    }
  }

  Future<String?> _insertFromMap(
    AppDatabase db,
    Map<String, dynamic> item,
    Set<String> validCategoryIds,
  ) async {
    final categoryId = item['categoryId']?.toString().trim() ?? '';
    final name = item['name']?.toString().trim() ?? '';
    if (!validCategoryIds.contains(categoryId)) {
      return '「$name」的品类 $categoryId 不存在';
    }
    if (name.isEmpty) return '存在名称为空的记录';

    final quantity = DecimalUtils.tryParse(item['quantity']?.toString());
    final costPrice = DecimalUtils.tryParse(item['costPrice']?.toString());
    if (quantity == null || costPrice == null) {
      return '「$name」的数量或成本价无效';
    }
    if (quantity <= Decimal.zero) return '「$name」的数量必须大于 0';

    final currentPrice = DecimalUtils.tryParse(item['currentPrice']?.toString());
    final purchaseDate =
        DateTime.tryParse(item['purchaseDate']?.toString() ?? '') ??
            DateTime.now();
    final code = item['code']?.toString().trim();
    final notes = item['notes']?.toString().trim();

    await db.assetDao.insertHolding(
      AssetHoldingsCompanion.insert(
        categoryId: categoryId,
        name: name,
        quantity: quantity.toString(),
        costPrice: costPrice.toString(),
        purchaseDate: purchaseDate,
        code: Value(code?.isEmpty == true ? null : code),
        currentPrice: Value(currentPrice?.toString()),
        notes: Value(notes?.isEmpty == true ? null : notes),
      ),
    );
    return null;
  }
}

// ---------------------------------------------------------------------------
// Excel
// ---------------------------------------------------------------------------

class ExcelImportExportStrategy implements ImportExportStrategy {
  static const _headers = [
    '品类',
    '名称',
    '代码',
    '数量',
    '成本价',
    '现价',
    '买入日期',
    '备注',
  ];

  @override
  String get formatName => 'Excel';

  @override
  Future<Result<Uint8List>> exportData(AppDatabase db) async {
    try {
      final rows = await db.assetDao.getAllHoldings();
      final excel = Excel.createExcel();
      final sheet = excel['持仓'];
      excel.delete('Sheet1');

      sheet.appendRow([
        for (final header in _headers) TextCellValue(header),
      ]);

      for (final item in rows) {
        final holding = item.holding;
        sheet.appendRow([
          TextCellValue(item.category?.name ?? holding.categoryId),
          TextCellValue(holding.name),
          TextCellValue(holding.code ?? ''),
          TextCellValue(holding.quantity),
          TextCellValue(holding.costPrice),
          TextCellValue(holding.currentPrice ?? ''),
          TextCellValue(DateFormatter.date(holding.purchaseDate)),
          TextCellValue(holding.notes ?? ''),
        ]);
      }

      final bytes = excel.save();
      if (bytes == null) return Result.failure('生成 Excel 失败');
      return Result.success(Uint8List.fromList(bytes));
    } catch (e) {
      return Result.failure('导出 Excel 失败：$e');
    }
  }

  @override
  Future<Result<ImportResult>> importData(
    AppDatabase db,
    Uint8List bytes,
  ) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return Result.failure('Excel 中没有工作表');
      }
      final sheet = excel.tables['持仓'] ?? excel.tables.values.first;
      final rows = sheet.rows;
      if (rows.isEmpty) {
        return Result.success(
          const ImportResult(imported: 0, skipped: 0, errors: []),
        );
      }

      final header = rows.first.map(_cellText).toList();
      final nameIndex = header.indexOf('名称');
      if (nameIndex < 0) {
        return Result.failure('Excel 缺少「名称」列，请使用导出的模板');
      }
      final categoryIndex = header.indexOf('品类');
      final codeIndex = header.indexOf('代码');
      final quantityIndex = header.indexOf('数量');
      final costIndex = header.indexOf('成本价');
      final priceIndex = header.indexOf('现价');
      final dateIndex = header.indexOf('买入日期');
      final notesIndex = header.indexOf('备注');

      final categories = await db.assetDao.getCategories();
      final categoryByName = <String, String>{};
      for (final category in categories) {
        categoryByName[category.id] = category.id;
        categoryByName[category.name] = category.id;
      }

      var imported = 0;
      var skipped = 0;
      final errors = <String>[];

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        String cell(int index) =>
            index >= 0 && index < row.length ? _cellText(row[index]) : '';

        final name = cell(nameIndex);
        final categoryRaw = cell(categoryIndex);
        final quantityRaw = cell(quantityIndex);
        final costRaw = cell(costIndex);

        if (name.isEmpty &&
            categoryRaw.isEmpty &&
            quantityRaw.isEmpty &&
            costRaw.isEmpty) {
          continue;
        }

        final categoryId = categoryByName[categoryRaw];
        final quantity = DecimalUtils.tryParse(quantityRaw);
        final costPrice = DecimalUtils.tryParse(costRaw);

        if (categoryId == null) {
          skipped++;
          errors.add('第 ${i + 1} 行：未知品类「$categoryRaw」');
          continue;
        }
        if (name.isEmpty || quantity == null || costPrice == null) {
          skipped++;
          errors.add('第 ${i + 1} 行：名称/数量/成本价无效');
          continue;
        }
        if (quantity <= Decimal.zero) {
          skipped++;
          errors.add('第 ${i + 1} 行：数量必须大于 0');
          continue;
        }

        final priceRaw = cell(priceIndex);
        final dateRaw = cell(dateIndex);
        final codeRaw = cell(codeIndex);
        final notesRaw = cell(notesIndex);

        await db.assetDao.insertHolding(
          AssetHoldingsCompanion.insert(
            categoryId: categoryId,
            name: name,
            quantity: quantity.toString(),
            costPrice: costPrice.toString(),
            purchaseDate:
                DateTime.tryParse(dateRaw) ?? DateTime.now(),
            code: Value(codeRaw.isEmpty ? null : codeRaw),
            currentPrice: Value(
              priceRaw.isEmpty
                  ? null
                  : DecimalUtils.tryParse(priceRaw)?.toString(),
            ),
            notes: Value(notesRaw.isEmpty ? null : notesRaw),
          ),
        );
        imported++;
      }

      return Result.success(ImportResult(
        imported: imported,
        skipped: skipped,
        errors: errors,
      ));
    } catch (e) {
      return Result.failure('导入 Excel 失败：$e');
    }
  }

  String _cellText(Data? data) {
    final value = data?.value;
    if (value == null) return '';
    return value.toString().trim();
  }
}
