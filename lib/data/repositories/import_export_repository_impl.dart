import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';

import '../../core/constants.dart';
import '../../core/date_formatter.dart';
import '../../core/decimal_utils.dart';
import '../../core/import_limits.dart';
import '../../core/result.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/repositories/import_export_repository.dart';
import '../../domain/usecases/parse_quantity_from_unit.dart';
import '../local/database.dart';

/// 导入/导出策略：新增格式只需实现该接口并在仓库中注册。
abstract class ImportExportStrategy {
  String get formatName;

  Future<Result<Uint8List>> exportData(AppDatabase db);

  Future<Result<ImportResult>> importData(
    AppDatabase db,
    Uint8List bytes, {
    DuplicatePolicy duplicates = DuplicatePolicy.skip,
  });
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
  Future<Result<ImportResult>> importJson(
    Uint8List bytes, {
    DuplicatePolicy duplicates = DuplicatePolicy.skip,
  }) => _json.importData(_db, bytes, duplicates: duplicates);

  @override
  Future<Result<ImportResult>> importExcel(
    Uint8List bytes, {
    DuplicatePolicy duplicates = DuplicatePolicy.skip,
  }) => _excel.importData(_db, bytes, duplicates: duplicates);
}

/// 重复持仓的判定键：品类 + 名称 + 代码。
String _holdingKey(String categoryId, String name, String? code) =>
    '$categoryId\u0000$name\u0000${code ?? ''}';

class _ImportedCashRecord {
  final Decimal amount;
  final DateTime recordDate;

  const _ImportedCashRecord({required this.amount, required this.recordDate});
}

/// 单次导入的累计状态，同时保存已存在/已插入持仓的 ID 以支持覆盖。
class _ImportState {
  _ImportState._(this._holdingIds);

  static Future<_ImportState> load(AppDatabase db) async {
    final rows = await db.assetDao.getAllHoldings();
    return _ImportState._({
      for (final row in rows)
        _holdingKey(row.holding.categoryId, row.holding.name, row.holding.code):
            row.holding.id,
    });
  }

  final Map<String, int> _holdingIds;
  int imported = 0;
  int updated = 0;
  int skipped = 0;
  final errors = <String>[];

  ImportResult toResult() => ImportResult(
    imported: imported,
    updated: updated,
    skipped: skipped,
    errors: errors,
  );

  /// 按重复策略写入一条已通过校验的持仓。
  Future<void> apply(
    AppDatabase db, {
    required String categoryId,
    required String name,
    required String? code,
    required String quantity,
    required String costPrice,
    required String? currentPrice,
    required DateTime purchaseDate,
    required String? notes,
    required String? unit,
    required String? amount,
    required List<_ImportedCashRecord> cashRecords,
    required DuplicatePolicy duplicates,
  }) async {
    final key = _holdingKey(categoryId, name, code);
    final existingId = _holdingIds[key];

    if (categoryId == AssetCategoryIds.cash) {
      final records = cashRecords.isEmpty
          ? <_ImportedCashRecord>[
              _ImportedCashRecord(
                amount: DecimalUtils.parseOrZero(amount ?? quantity),
                recordDate: purchaseDate,
              ),
            ]
          : (List<_ImportedCashRecord>.from(cashRecords)
            ..sort((a, b) => a.recordDate.compareTo(b.recordDate)));
      final latest = records.last;

      if (existingId != null) {
        if (duplicates == DuplicatePolicy.skip) {
          skipped++;
          return;
        }
        await db.assetDao.updateHolding(
          existingId,
          AssetHoldingsCompanion(
            name: Value(name),
            quantity: const Value('0'),
            costPrice: const Value('0'),
            currentPrice: const Value<String?>(null),
            unit: const Value<String?>(null),
            amount: Value(latest.amount.toString()),
            purchaseDate: Value(latest.recordDate),
            notes: Value(notes),
            updatedAt: Value(DateTime.now()),
          ),
        );
        await db.cashRecordDao.deleteForHolding(existingId);
        for (final record in records) {
          await db.cashRecordDao.insertRecord(
            CashRecordsCompanion.insert(
              holdingId: existingId,
              amount: record.amount.toString(),
              recordDate: record.recordDate,
            ),
          );
        }
        updated++;
        return;
      }

      final id = await db.assetDao.insertHolding(
        AssetHoldingsCompanion.insert(
          categoryId: categoryId,
          name: name,
          quantity: '0',
          costPrice: '0',
          purchaseDate: latest.recordDate,
          code: Value(code),
          amount: Value(latest.amount.toString()),
          notes: Value(notes),
        ),
      );
      for (final record in records) {
        await db.cashRecordDao.insertRecord(
          CashRecordsCompanion.insert(
            holdingId: id,
            amount: record.amount.toString(),
            recordDate: record.recordDate,
          ),
        );
      }
      _holdingIds[key] = id;
      imported++;
      return;
    }

    if (existingId != null) {
      if (duplicates == DuplicatePolicy.skip) {
        skipped++;
        return;
      }
      await db.assetDao.updateHolding(
        existingId,
        AssetHoldingsCompanion(
          quantity: Value(quantity),
          costPrice: Value(costPrice),
          currentPrice: Value(currentPrice),
          unit: Value(unit),
          purchaseDate: Value(purchaseDate),
          notes: Value(notes),
          updatedAt: Value(DateTime.now()),
        ),
      );
      updated++;
      return;
    }

    final id = await db.assetDao.insertHolding(
      AssetHoldingsCompanion.insert(
        categoryId: categoryId,
        name: name,
        quantity: quantity,
        costPrice: costPrice,
        purchaseDate: purchaseDate,
        code: Value(code),
        unit: Value(unit),
        currentPrice: Value(currentPrice),
        notes: Value(notes),
      ),
    );
    _holdingIds[key] = id;
    imported++;
  }
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
      final cashRecords = await db.cashRecordDao.getAllRecords();
      final recordsByHolding = <int, List<CashRecordRow>>{};
      for (final record in cashRecords) {
        (recordsByHolding[record.holdingId] ??= []).add(record);
      }

      final payload = {
        'app': AppConstants.appName,
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'holdings': [
          for (final item in rows)
            {
              'categoryId': item.holding.categoryId,
              'categoryName': item.category?.name,
              'name': item.holding.name,
              'code': item.holding.code,
              'unit': item.holding.unit,
              'amount': item.holding.amount,
              'quantity': item.holding.quantity,
              'costPrice': item.holding.costPrice,
              'currentPrice': item.holding.currentPrice,
              'purchaseDate': item.holding.purchaseDate.toIso8601String(),
              'notes': item.holding.notes,
              'cashRecords': [
                for (final record
                    in recordsByHolding[item.holding.id] ?? const [])
                  {
                    'amount': record.amount,
                    'recordDate': record.recordDate.toIso8601String(),
                  },
              ],
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
    Uint8List bytes, {
    DuplicatePolicy duplicates = DuplicatePolicy.skip,
  }) async {
    final sizeError = ImportLimits.validateBytes(bytes.lengthInBytes);
    if (sizeError != null) return Result.failure(sizeError);

    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        return Result.failure('JSON 格式不正确');
      }
      final holdings = decoded['holdings'];
      if (holdings is! List) {
        return Result.failure('JSON 中缺少 holdings 数组');
      }
      final rowError = ImportLimits.validateRows(holdings.length);
      if (rowError != null) return Result.failure(rowError);

      final categories = await db.assetDao.getCategories();
      final validIds = categories.map((c) => c.id).toSet();
      final state = await _ImportState.load(db);

      // 导入整体处于一个事务中：任何未预期异常都会回滚已写入的记录。
      await db.transaction(() async {
        for (var i = 0; i < holdings.length; i++) {
          final item = holdings[i];
          if (item is! Map<String, dynamic>) {
            state.skipped++;
            state.errors.add('第 ${i + 1} 条格式错误');
            continue;
          }
          final error = await _insertFromMap(
            db,
            state,
            item,
            validIds,
            duplicates,
          );
          if (error != null) {
            state.skipped++;
            state.errors.add(error);
          }
        }
      });

      return Result.success(state.toResult());
    } catch (e) {
      return Result.failure('导入 JSON 失败：$e');
    }
  }

  Future<String?> _insertFromMap(
    AppDatabase db,
    _ImportState state,
    Map<String, dynamic> item,
    Set<String> validCategoryIds,
    DuplicatePolicy duplicates,
  ) async {
    final categoryId = item['categoryId']?.toString().trim() ?? '';
    final name = item['name']?.toString().trim() ?? '';
    if (!validCategoryIds.contains(categoryId)) {
      return '「$name」的品类 $categoryId 不存在';
    }
    if (name.isEmpty) return '存在名称为空的记录';

    final code = item['code']?.toString().trim();
    final notes = item['notes']?.toString().trim();
    final purchaseDate =
        DateTime.tryParse(item['purchaseDate']?.toString() ?? '') ??
        DateTime.now();
    final rawUnit = item['unit']?.toString().trim();

    if (categoryId == AssetCategoryIds.cash) {
      final amount = DecimalUtils.tryParse(item['amount']?.toString()) ??
          DecimalUtils.tryParse(item['quantity']?.toString());
      if (amount == null || amount <= Decimal.zero) {
        return '「$name」的金额无效';
      }

      final records = <_ImportedCashRecord>[];
      final rawRecords = item['cashRecords'];
      if (rawRecords is List) {
        for (final raw in rawRecords) {
          if (raw is! Map) {
            state.errors.add('「$name」的现金记录格式错误');
            continue;
          }
          final recordAmount =
              DecimalUtils.tryParse(raw['amount']?.toString());
          final recordDate =
              DateTime.tryParse(raw['recordDate']?.toString() ?? '');
          if (recordAmount == null ||
              recordAmount <= Decimal.zero ||
              recordDate == null ||
              recordDate.isAfter(DateTime.now())) {
            state.errors.add('「$name」的现金记录无效');
            continue;
          }
          records.add(
            _ImportedCashRecord(
              amount: recordAmount,
              recordDate: recordDate,
            ),
          );
        }
      }

      await state.apply(
        db,
        categoryId: categoryId,
        name: name,
        code: code?.isEmpty == true ? null : code,
        quantity: '0',
        costPrice: '0',
        currentPrice: null,
        purchaseDate: purchaseDate,
        notes: notes?.isEmpty == true ? null : notes,
        unit: null,
        amount: amount.toString(),
        cashRecords: records,
        duplicates: duplicates,
      );
      return null;
    }

    final costPrice = DecimalUtils.tryParse(item['costPrice']?.toString());
    if (costPrice == null) {
      return '「$name」的数量或成本价无效';
    }

    final quantityRaw = DecimalUtils.tryParse(item['quantity']?.toString());
    Decimal? quantity;
    String? unit;
    if (categoryId == AssetCategoryIds.preciousMetal) {
      unit = (rawUnit == null || rawUnit.isEmpty)
          ? (quantityRaw != null ? '$quantityRaw克' : null)
          : rawUnit;
      quantity = ParseQuantityFromUnit.parse(unit) ?? quantityRaw;
    } else {
      quantity = quantityRaw;
    }
    if (quantity == null || quantity <= Decimal.zero) {
      return '「$name」的数量或成本价无效';
    }

    final currentPrice = DecimalUtils.tryParse(
      item['currentPrice']?.toString(),
    );

    await state.apply(
      db,
      categoryId: categoryId,
      name: name,
      code: code?.isEmpty == true ? null : code,
      quantity: quantity.toString(),
      costPrice: costPrice.toString(),
      currentPrice: currentPrice?.toString(),
      purchaseDate: purchaseDate,
      notes: notes?.isEmpty == true ? null : notes,
      unit: unit,
      amount: null,
      cashRecords: const [],
      duplicates: duplicates,
    );
    return null;
  }
}

// ---------------------------------------------------------------------------
// Excel
// ---------------------------------------------------------------------------

class ExcelImportExportStrategy implements ImportExportStrategy {
  static const _headers = ['品类', '名称', '代码', '数量', '成本价', '现价', '买入日期', '备注'];

  @override
  String get formatName => 'Excel';

  @override
  Future<Result<Uint8List>> exportData(AppDatabase db) async {
    try {
      final rows = await db.assetDao.getAllHoldings();
      final excel = Excel.createExcel();
      final sheet = excel['持仓'];
      excel.delete('Sheet1');

      sheet.appendRow([for (final header in _headers) TextCellValue(header)]);

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
    Uint8List bytes, {
    DuplicatePolicy duplicates = DuplicatePolicy.skip,
  }) async {
    final sizeError = ImportLimits.validateBytes(bytes.lengthInBytes);
    if (sizeError != null) return Result.failure(sizeError);

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
      final rowError = ImportLimits.validateRows(rows.length - 1);
      if (rowError != null) return Result.failure(rowError);

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
      final state = await _ImportState.load(db);

      await db.transaction(() async {
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
            state.skipped++;
            state.errors.add('第 ${i + 1} 行：未知品类「$categoryRaw」');
            continue;
          }
          if (name.isEmpty || quantity == null || costPrice == null) {
            state.skipped++;
            state.errors.add('第 ${i + 1} 行：名称/数量/成本价无效');
            continue;
          }
          if (quantity <= Decimal.zero) {
            state.skipped++;
            state.errors.add('第 ${i + 1} 行：数量必须大于 0');
            continue;
          }

          final priceRaw = cell(priceIndex);
          final dateRaw = cell(dateIndex);
          final codeRaw = cell(codeIndex);
          final notesRaw = cell(notesIndex);

          await state.apply(
            db,
            categoryId: categoryId,
            name: name,
            code: codeRaw.isEmpty ? null : codeRaw,
            quantity: quantity.toString(),
            costPrice: costPrice.toString(),
            currentPrice: priceRaw.isEmpty
                ? null
                : DecimalUtils.tryParse(priceRaw)?.toString(),
            purchaseDate: DateTime.tryParse(dateRaw) ?? DateTime.now(),
            notes: notesRaw.isEmpty ? null : notesRaw,
            unit: null,
            amount: null,
            cashRecords: const [],
            duplicates: duplicates,
          );
        }
      });

      return Result.success(state.toResult());
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
