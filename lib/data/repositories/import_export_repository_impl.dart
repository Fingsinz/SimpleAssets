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
import '../../domain/entities/asset_transaction.dart';
import '../../domain/repositories/import_export_repository.dart';
import '../../domain/usecases/parse_quantity_from_unit.dart';
import '../../domain/usecases/replay_transactions.dart';
import '../local/database.dart';
import 'holding_stats_writer.dart';

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

class _ImportedTransaction {
  final TransactionType type;
  final Decimal? quantity;
  final Decimal? price;
  final Decimal? amount;
  final Decimal? fee;
  final Decimal? ratio;
  final DateTime date;
  final String? notes;

  const _ImportedTransaction({
    required this.type,
    this.quantity,
    this.price,
    this.amount,
    this.fee,
    this.ratio,
    required this.date,
    this.notes,
  });

  AssetTransaction toDomain(int holdingId, int order) => AssetTransaction(
        id: order,
        holdingId: holdingId,
        type: type,
        quantity: quantity,
        price: price,
        amount: amount,
        fee: fee,
        ratio: ratio,
        date: date,
        notes: notes,
      );
}

class _ImportedPricePoint {
  final String period;
  final Decimal price;
  final DateTime observedAt;

  const _ImportedPricePoint({
    required this.period,
    required this.price,
    required this.observedAt,
  });
}

/// 单次导入的累计状态，同时保存已存在/已插入持仓的 ID 以支持覆盖。
class _ImportState {
  _ImportState._(
    this._holdingIds,
    this._cashIdsByName,
    this._existingCashNameCounts,
  );

  static Future<_ImportState> load(AppDatabase db) async {
    final rows = await db.assetDao.getAllHoldings();
    final holdingIds = <String, int>{};
    final cashIdsByName = <String, int>{};
    final existingCashNameCounts = <String, int>{};

    for (final row in rows) {
      final holding = row.holding;
      holdingIds[_holdingKey(
        holding.categoryId,
        holding.name,
        holding.code,
      )] = holding.id;
      if (holding.categoryId == AssetCategoryIds.cash) {
        final name = holding.name.trim();
        cashIdsByName[name] = holding.id;
        existingCashNameCounts[name] =
            (existingCashNameCounts[name] ?? 0) + 1;
      }
    }

    return _ImportState._(
      holdingIds,
      cashIdsByName,
      existingCashNameCounts,
    );
  }

  final Map<String, int> _holdingIds;
  final Map<String, int> _cashIdsByName;
  final Map<String, int> _existingCashNameCounts;

  /// 本次导入文件内现金平台名称的出现次数，用于拒绝同名平台。
  final Map<String, int> fileCashNameCounts = {};

  int imported = 0;
  int updated = 0;
  int skipped = 0;
  final errors = <String>[];

  /// 返回 null 表示可以导入；否则为需要展示给用户的冲突原因。
  String? checkCashName(String name) {
    final trimmed = name.trim();
    if ((fileCashNameCounts[trimmed] ?? 0) > 1) {
      return '现金平台「$name」在导入文件中重复，已跳过';
    }
    if ((_existingCashNameCounts[trimmed] ?? 0) > 1) {
      return '现金平台「$name」存在多个同名持仓，请先重命名后再导入';
    }
    return null;
  }

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
    bool isV3 = false,
    List<_ImportedTransaction> transactions = const [],
    List<_ImportedPricePoint> priceHistory = const [],
  }) async {
    final key = _holdingKey(categoryId, name, code);
    final existingId = categoryId == AssetCategoryIds.cash
        ? _cashIdsByName[name.trim()]
        : _holdingIds[key];

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
      _cashIdsByName[name.trim()] = id;
      imported++;
      return;
    }

    if (isV3) {
      if (transactions.isEmpty) {
        skipped++;
        errors.add('「$name」缺少交易流水');
        return;
      }
      try {
        ReplayTransactions.replay([
          for (var i = 0; i < transactions.length; i++)
            transactions[i].toDomain(0, i),
        ]);
      } on TransactionValidationException catch (e) {
        skipped++;
        errors.add('「$name」的交易流水无效：${e.message}');
        return;
      }
    }

    final effectiveQuantity = isV3 ? '0' : quantity;
    final effectiveCost = isV3 ? '0' : costPrice;
    final effectiveDate = isV3 && transactions.isNotEmpty
        ? transactions.first.date
        : purchaseDate;

    Future<void> writeTransactions(AppDatabase db, int id) async {
      if (isV3) {
        for (final transaction in transactions) {
          await db.transactionDao.insertTransaction(
            TransactionsCompanion.insert(
              holdingId: id,
              type: transaction.type.storageValue,
              amount: Value(transaction.amount?.toString()),
              price: Value(transaction.price?.toString()),
              quantity: Value(transaction.quantity?.toString()),
              fee: Value((transaction.fee ?? Decimal.zero).toString()),
              ratio: Value(transaction.ratio?.toString()),
              date: transaction.date,
              notes: Value(transaction.notes),
            ),
          );
        }
      } else {
        await _insertOpeningBuy(db, id, quantity, costPrice, purchaseDate);
      }
    }

    Future<void> writePriceHistory(AppDatabase db, int id) async {
      for (final point in priceHistory) {
        await db.priceHistoryDao.upsertMonth(
          holdingId: id,
          period: point.period,
          price: point.price.toString(),
          observedAt: point.observedAt,
        );
      }
    }

    if (existingId != null) {
      if (duplicates == DuplicatePolicy.skip) {
        skipped++;
        return;
      }
      await db.assetDao.updateHolding(
        existingId,
        AssetHoldingsCompanion(
          quantity: Value(effectiveQuantity),
          costPrice: Value(effectiveCost),
          currentPrice: Value(currentPrice),
          unit: Value(unit),
          purchaseDate: Value(effectiveDate),
          notes: Value(notes),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await db.transactionDao.deleteForHolding(existingId);
      await db.priceHistoryDao.deleteForHolding(existingId);
      await writeTransactions(db, existingId);
      await HoldingStatsWriter.recompute(db, existingId);
      await writePriceHistory(db, existingId);
      updated++;
      return;
    }

    final id = await db.assetDao.insertHolding(
      AssetHoldingsCompanion.insert(
        categoryId: categoryId,
        name: name,
        quantity: effectiveQuantity,
        costPrice: effectiveCost,
        purchaseDate: effectiveDate,
        code: Value(code),
        unit: Value(unit),
        currentPrice: Value(currentPrice),
        notes: Value(notes),
      ),
    );
    await writeTransactions(db, id);
    await HoldingStatsWriter.recompute(db, id);
    await writePriceHistory(db, id);
    _holdingIds[key] = id;
    imported++;
  }

  Future<void> _insertOpeningBuy(
    AppDatabase db,
    int holdingId,
    String quantity,
    String costPrice,
    DateTime purchaseDate,
  ) async {
    final parsedQuantity = DecimalUtils.parseOrZero(quantity);
    if (parsedQuantity <= Decimal.zero) return;
    final parsedCost = DecimalUtils.parseOrZero(costPrice);
    await db.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        holdingId: holdingId,
        type: 'buy',
        amount: Value((parsedQuantity * parsedCost).toString()),
        price: Value(parsedCost.toString()),
        quantity: Value(parsedQuantity.toString()),
        fee: const Value('0'),
        date: purchaseDate,
        notes: const Value('期初持仓'),
      ),
    );
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
      final transactionRows = await db.transactionDao.getAll();
      final transactionsByHolding = <int, List<TransactionRow>>{};
      for (final row in transactionRows) {
        (transactionsByHolding[row.holdingId] ??= []).add(row);
      }
      final priceRows = await db.priceHistoryDao.getAll();
      final pricesByHolding = <int, List<PriceHistoryRow>>{};
      for (final row in priceRows) {
        (pricesByHolding[row.holdingId] ??= []).add(row);
      }

      final payload = {
        'app': AppConstants.appName,
        'version': 3,
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
              'transactions': [
                for (final transaction
                    in transactionsByHolding[item.holding.id] ?? const [])
                  {
                    'type': transaction.type,
                    'quantity': transaction.quantity,
                    'price': transaction.price,
                    'amount': transaction.amount,
                    'fee': transaction.fee,
                    'ratio': transaction.ratio,
                    'date': transaction.date.toIso8601String(),
                    'notes': transaction.notes,
                  },
              ],
              'priceHistory': [
                for (final point
                    in pricesByHolding[item.holding.id] ?? const [])
                  {
                    'period': point.period,
                    'price': point.price,
                    'observedAt': point.observedAt.toIso8601String(),
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
      final version = (decoded['version'] as num?)?.toInt() ?? 1;
      final isV3 = version >= 3;

      for (final item in holdings) {
        if (item is! Map<String, dynamic>) continue;
        if (item['categoryId']?.toString() != AssetCategoryIds.cash) continue;
        final name = item['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        state.fileCashNameCounts[name] =
            (state.fileCashNameCounts[name] ?? 0) + 1;
      }

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
            isV3: isV3,
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
    DuplicatePolicy duplicates, {
    required bool isV3,
  }) async {
    final categoryId = item['categoryId']?.toString().trim() ?? '';
    final name = item['name']?.toString().trim() ?? '';
    if (!validCategoryIds.contains(categoryId)) {
      return '「$name」的品类 $categoryId 不存在';
    }
    if (name.isEmpty) return '存在名称为空的记录';

    final code = item['code']?.toString().trim();
    final notes = item['notes']?.toString().trim();
    final rawPurchaseDate = item['purchaseDate']?.toString().trim() ?? '';
    final parsedPurchaseDate = rawPurchaseDate.isEmpty
        ? DateTime.now()
        : DateTime.tryParse(rawPurchaseDate);
    if (parsedPurchaseDate == null ||
        parsedPurchaseDate.isAfter(DateTime.now()) ||
        parsedPurchaseDate.isBefore(DateTime(2000))) {
      return '「$name」的日期无效';
    }
    final purchaseDate = parsedPurchaseDate;
    final rawUnit = item['unit']?.toString().trim();

    if (categoryId == AssetCategoryIds.cash) {
      final nameError = state.checkCashName(name);
      if (nameError != null) return nameError;

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
              recordDate.isAfter(DateTime.now()) ||
              recordDate.isBefore(DateTime(2000))) {
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

    List<_ImportedTransaction> importedTransactions = const [];
    List<_ImportedPricePoint> importedPrices = const [];
    if (isV3) {
      final parsedTransactions = _parseTransactions(item['transactions']);
      if (parsedTransactions == null) {
        return '「$name」的交易流水格式错误';
      }
      final parsedPrices = _parsePriceHistory(item['priceHistory']);
      if (parsedPrices == null) {
        return '「$name」的价格历史格式错误';
      }
      importedTransactions = parsedTransactions;
      importedPrices = parsedPrices;
      if (importedTransactions.isEmpty) {
        return '「$name」缺少交易流水';
      }
    }

    Decimal? costPrice;
    Decimal? quantity;
    String? unit;
    if (isV3) {
      costPrice = Decimal.zero;
      quantity = Decimal.zero;
      unit = categoryId == AssetCategoryIds.preciousMetal
          ? (rawUnit == null || rawUnit.isEmpty ? null : rawUnit)
          : null;
    } else {
      costPrice = DecimalUtils.tryParse(item['costPrice']?.toString());
      if (costPrice == null) {
        return '「$name」的数量或成本价无效';
      }
      final quantityRaw = DecimalUtils.tryParse(item['quantity']?.toString());
      if (categoryId == AssetCategoryIds.preciousMetal) {
        unit = (rawUnit == null || rawUnit.isEmpty)
            ? (quantityRaw != null ? '$quantityRaw克' : null)
            : rawUnit;
        quantity = ParseQuantityFromUnit.parse(unit) ?? quantityRaw;
        unit = ParseQuantityFromUnit.unitLabel(unit);
      } else {
        quantity = quantityRaw;
      }
      if (quantity == null || quantity <= Decimal.zero) {
        return '「$name」的数量或成本价无效';
      }
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
      isV3: isV3,
      transactions: importedTransactions,
      priceHistory: importedPrices,
    );
    return null;
  }

  List<_ImportedTransaction>? _parseTransactions(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) return null;
    final result = <_ImportedTransaction>[];
    for (final item in raw) {
      if (item is! Map) return null;
      final type = TransactionType.fromStorage(item['type']?.toString());
      if (type == null) return null;
      final date = DateTime.tryParse(item['date']?.toString() ?? '');
      if (date == null ||
          date.isAfter(DateTime.now()) ||
          date.isBefore(DateTime(2000))) {
        return null;
      }
      result.add(
        _ImportedTransaction(
          type: type,
          quantity: DecimalUtils.tryParse(item['quantity']?.toString()),
          price: DecimalUtils.tryParse(item['price']?.toString()),
          amount: DecimalUtils.tryParse(item['amount']?.toString()),
          fee: DecimalUtils.tryParse(item['fee']?.toString()),
          ratio: DecimalUtils.tryParse(item['ratio']?.toString()),
          date: date,
          notes: item['notes']?.toString(),
        ),
      );
    }
    return result;
  }

  List<_ImportedPricePoint>? _parsePriceHistory(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) return null;
    final result = <_ImportedPricePoint>[];
    for (final item in raw) {
      if (item is! Map) return null;
      final period = item['period']?.toString() ?? '';
      if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(period)) return null;
      final price = DecimalUtils.tryParse(item['price']?.toString());
      if (price == null || price <= Decimal.zero) return null;
      final observedAt =
          DateTime.tryParse(item['observedAt']?.toString() ?? '');
      if (observedAt == null || observedAt.isAfter(DateTime.now())) {
        return null;
      }
      result.add(
        _ImportedPricePoint(
          period: period,
          price: price,
          observedAt: observedAt,
        ),
      );
    }
    return result;
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
    '金额',
    '单位',
  ];

  @override
  String get formatName => 'Excel';

  @override
  Future<Result<Uint8List>> exportData(AppDatabase db) async {
    try {
      final rows = await db.assetDao.getAllHoldings();
      final cashRecords = await db.cashRecordDao.getAllRecords();
      final excel = Excel.createExcel();
      final sheet = excel['持仓'];
      excel.delete('Sheet1');

      sheet.appendRow([for (final header in _headers) TextCellValue(header)]);

      for (final item in rows) {
        final holding = item.holding;
        final isCash = holding.categoryId == AssetCategoryIds.cash;
        sheet.appendRow([
          TextCellValue(item.category?.name ?? holding.categoryId),
          TextCellValue(holding.name),
          TextCellValue(holding.code ?? ''),
          TextCellValue(isCash ? '' : holding.quantity),
          TextCellValue(isCash ? '' : holding.costPrice),
          TextCellValue(isCash ? '' : (holding.currentPrice ?? '')),
          TextCellValue(DateFormatter.date(holding.purchaseDate)),
          TextCellValue(holding.notes ?? ''),
          TextCellValue(isCash ? (holding.amount ?? '') : ''),
          TextCellValue(holding.unit ?? ''),
        ]);
      }

      final cashSheet = excel['现金记录'];
      cashSheet.appendRow([
        TextCellValue('平台'),
        TextCellValue('金额'),
        TextCellValue('记录日期'),
      ]);
      final nameById = {
        for (final item in rows) item.holding.id: item.holding.name,
      };
      for (final record in cashRecords) {
        final platform = nameById[record.holdingId];
        if (platform == null) continue;
        cashSheet.appendRow([
          TextCellValue(platform),
          TextCellValue(record.amount),
          TextCellValue(DateFormatter.date(record.recordDate)),
        ]);
      }

      final holdingById = {
        for (final item in rows) item.holding.id: item,
      };
      final transactionRows = await db.transactionDao.getAll();
      final transactionSheet = excel['交易流水'];
      transactionSheet.appendRow([
        TextCellValue('品类'),
        TextCellValue('名称'),
        TextCellValue('代码'),
        TextCellValue('类型'),
        TextCellValue('日期'),
        TextCellValue('数量'),
        TextCellValue('单价'),
        TextCellValue('金额'),
        TextCellValue('手续费'),
        TextCellValue('折算比例'),
        TextCellValue('备注'),
      ]);
      for (final transaction in transactionRows) {
        final item = holdingById[transaction.holdingId];
        if (item == null) continue;
        final type = TransactionType.fromStorage(transaction.type);
        transactionSheet.appendRow([
          TextCellValue(item.category?.name ?? item.holding.categoryId),
          TextCellValue(item.holding.name),
          TextCellValue(item.holding.code ?? ''),
          TextCellValue(type?.label ?? transaction.type),
          TextCellValue(DateFormatter.date(transaction.date)),
          TextCellValue(transaction.quantity ?? ''),
          TextCellValue(transaction.price ?? ''),
          TextCellValue(transaction.amount ?? ''),
          TextCellValue(transaction.fee),
          TextCellValue(transaction.ratio ?? ''),
          TextCellValue(transaction.notes ?? ''),
        ]);
      }

      final priceRows = await db.priceHistoryDao.getAll();
      final priceSheet = excel['价格历史'];
      priceSheet.appendRow([
        TextCellValue('品类'),
        TextCellValue('名称'),
        TextCellValue('代码'),
        TextCellValue('月份'),
        TextCellValue('价格'),
        TextCellValue('记录时间'),
      ]);
      for (final point in priceRows) {
        final item = holdingById[point.holdingId];
        if (item == null) continue;
        priceSheet.appendRow([
          TextCellValue(item.category?.name ?? item.holding.categoryId),
          TextCellValue(item.holding.name),
          TextCellValue(item.holding.code ?? ''),
          TextCellValue(point.period),
          TextCellValue(point.price),
          TextCellValue(DateFormatter.dateTime(point.observedAt)),
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
      final amountIndex = header.indexOf('金额');
      final unitIndex = header.indexOf('单位');

      final categories = await db.assetDao.getCategories();
      final categoryByName = <String, String>{};
      for (final category in categories) {
        categoryByName[category.id] = category.id;
        categoryByName[category.name] = category.id;
      }
      categoryByName['黄金'] = AssetCategoryIds.preciousMetal;
      categoryByName['贵金属'] = AssetCategoryIds.preciousMetal;
      categoryByName['现金'] = AssetCategoryIds.cash;

      final state = await _ImportState.load(db);

      final recordsByPlatform = <String, List<_ImportedCashRecord>>{};
      final historySheet = excel.tables['现金记录'];
      if (historySheet != null && historySheet.rows.isNotEmpty) {
        final historyRows = historySheet.rows;
        final historyError = ImportLimits.validateRows(historyRows.length - 1);
        if (historyError != null) return Result.failure(historyError);

        final historyHeader = historyRows.first.map(_cellText).toList();
        final platformIndex = historyHeader.indexOf('平台');
        final historyAmountIndex = historyHeader.indexOf('金额');
        final historyDateIndex = historyHeader.indexOf('记录日期');
        if (platformIndex < 0 ||
            historyAmountIndex < 0 ||
            historyDateIndex < 0) {
          return Result.failure('「现金记录」表缺少平台 / 金额 / 记录日期列');
        }

        for (var i = 1; i < historyRows.length; i++) {
          final row = historyRows[i];
          String cell(int index) =>
              index >= 0 && index < row.length ? _cellText(row[index]) : '';
          final platform = cell(platformIndex);
          final amountRaw = cell(historyAmountIndex);
          final dateRaw = cell(historyDateIndex);
          if (platform.isEmpty && amountRaw.isEmpty && dateRaw.isEmpty) {
            continue;
          }
          final amount = DecimalUtils.tryParse(amountRaw);
          final recordDate = DateTime.tryParse(dateRaw);
          if (platform.isEmpty ||
              amount == null ||
              amount <= Decimal.zero ||
              recordDate == null ||
              recordDate.isAfter(DateTime.now()) ||
              recordDate.isBefore(DateTime(2000))) {
            state.errors.add(
              '现金记录第 ${i + 1} 行：平台 / 金额 / 日期无效',
            );
            continue;
          }
          (recordsByPlatform[platform] ??= []).add(
            _ImportedCashRecord(amount: amount, recordDate: recordDate),
          );
        }
      }

      final transactionSheet = excel.tables['交易流水'];
      final isV3 = transactionSheet != null;
      final transactionsByKey = <String, List<_ImportedTransaction>>{};
      final priceHistoryByKey = <String, List<_ImportedPricePoint>>{};

      if (transactionSheet != null && transactionSheet.rows.isNotEmpty) {
        final txRows = transactionSheet.rows;
        final txError = ImportLimits.validateRows(txRows.length - 1);
        if (txError != null) return Result.failure(txError);
        final txHeader = txRows.first.map(_cellText).toList();
        final txCategoryIndex = txHeader.indexOf('品类');
        final txNameIndex = txHeader.indexOf('名称');
        final txCodeIndex = txHeader.indexOf('代码');
        final txTypeIndex = txHeader.indexOf('类型');
        final txDateIndex = txHeader.indexOf('日期');
        final txQuantityIndex = txHeader.indexOf('数量');
        final txPriceIndex = txHeader.indexOf('单价');
        final txAmountIndex = txHeader.indexOf('金额');
        final txFeeIndex = txHeader.indexOf('手续费');
        final txRatioIndex = txHeader.indexOf('折算比例');
        final txNotesIndex = txHeader.indexOf('备注');
        if (txCategoryIndex < 0 ||
            txNameIndex < 0 ||
            txTypeIndex < 0 ||
            txDateIndex < 0) {
          return Result.failure('「交易流水」表缺少品类 / 名称 / 类型 / 日期列');
        }
        for (var i = 1; i < txRows.length; i++) {
          final row = txRows[i];
          String cell(int index) =>
              index >= 0 && index < row.length ? _cellText(row[index]) : '';
          final name = cell(txNameIndex);
          final categoryRaw = cell(txCategoryIndex);
          final typeRaw = cell(txTypeIndex);
          final dateRaw = cell(txDateIndex);
          if (name.isEmpty &&
              categoryRaw.isEmpty &&
              typeRaw.isEmpty &&
              dateRaw.isEmpty) {
            continue;
          }
          final categoryId = categoryByName[categoryRaw];
          final type = _parseType(typeRaw);
          final date = DateTime.tryParse(dateRaw);
          if (categoryId == null ||
              type == null ||
              name.isEmpty ||
              date == null ||
              date.isAfter(DateTime.now()) ||
              date.isBefore(DateTime(2000))) {
            state.errors.add('交易流水第 ${i + 1} 行：品类 / 名称 / 类型 / 日期无效');
            continue;
          }
          final codeRaw = cell(txCodeIndex);
          final key = _holdingKey(
            categoryId,
            name,
            codeRaw.isEmpty ? null : codeRaw,
          );
          (transactionsByKey[key] ??= []).add(
            _ImportedTransaction(
              type: type,
              quantity: DecimalUtils.tryParse(cell(txQuantityIndex)),
              price: DecimalUtils.tryParse(cell(txPriceIndex)),
              amount: DecimalUtils.tryParse(cell(txAmountIndex)),
              fee: DecimalUtils.tryParse(cell(txFeeIndex)),
              ratio: DecimalUtils.tryParse(cell(txRatioIndex)),
              date: date,
              notes: cell(txNotesIndex).isEmpty ? null : cell(txNotesIndex),
            ),
          );
        }
      }

      final priceSheet = excel.tables['价格历史'];
      if (priceSheet != null && priceSheet.rows.isNotEmpty) {
        final priceRows = priceSheet.rows;
        final priceError = ImportLimits.validateRows(priceRows.length - 1);
        if (priceError != null) return Result.failure(priceError);
        final priceHeader = priceRows.first.map(_cellText).toList();
        final priceCategoryIndex = priceHeader.indexOf('品类');
        final priceNameIndex = priceHeader.indexOf('名称');
        final priceCodeIndex = priceHeader.indexOf('代码');
        final pricePeriodIndex = priceHeader.indexOf('月份');
        final priceValueIndex = priceHeader.indexOf('价格');
        final priceObservedIndex = priceHeader.indexOf('记录时间');
        if (priceCategoryIndex < 0 ||
            priceNameIndex < 0 ||
            pricePeriodIndex < 0 ||
            priceValueIndex < 0) {
          return Result.failure('「价格历史」表缺少品类 / 名称 / 月份 / 价格列');
        }
        for (var i = 1; i < priceRows.length; i++) {
          final row = priceRows[i];
          String cell(int index) =>
              index >= 0 && index < row.length ? _cellText(row[index]) : '';
          final name = cell(priceNameIndex);
          final categoryRaw = cell(priceCategoryIndex);
          final period = cell(pricePeriodIndex);
          final priceRaw = cell(priceValueIndex);
          if (name.isEmpty &&
              categoryRaw.isEmpty &&
              period.isEmpty &&
              priceRaw.isEmpty) {
            continue;
          }
          final categoryId = categoryByName[categoryRaw];
          final price = DecimalUtils.tryParse(priceRaw);
          final observedAt = DateTime.tryParse(cell(priceObservedIndex));
          if (categoryId == null ||
              name.isEmpty ||
              !RegExp(r'^\d{4}-\d{2}$').hasMatch(period) ||
              price == null ||
              price <= Decimal.zero ||
              observedAt == null ||
              observedAt.isAfter(DateTime.now())) {
            state.errors.add('价格历史第 ${i + 1} 行：品类 / 名称 / 月份 / 价格无效');
            continue;
          }
          final codeRaw = cell(priceCodeIndex);
          final key = _holdingKey(
            categoryId,
            name,
            codeRaw.isEmpty ? null : codeRaw,
          );
          (priceHistoryByKey[key] ??= []).add(
            _ImportedPricePoint(
              period: period,
              price: price,
              observedAt: observedAt,
            ),
          );
        }
      }

      final cashPlatformsInMain = <String>{};
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        String cell(int index) =>
            index >= 0 && index < row.length ? _cellText(row[index]) : '';
        if (categoryByName[cell(categoryIndex)] != AssetCategoryIds.cash) {
          continue;
        }
        final name = cell(nameIndex).trim();
        if (name.isEmpty) continue;
        state.fileCashNameCounts[name] =
            (state.fileCashNameCounts[name] ?? 0) + 1;
      }

      await db.transaction(() async {
        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];
          String cell(int index) =>
              index >= 0 && index < row.length ? _cellText(row[index]) : '';

          final name = cell(nameIndex);
          final categoryRaw = cell(categoryIndex);
          final quantityRaw = cell(quantityIndex);
          final costRaw = cell(costIndex);
          final amountRaw = cell(amountIndex);
          final unitRaw = cell(unitIndex);

          if (name.isEmpty &&
              categoryRaw.isEmpty &&
              quantityRaw.isEmpty &&
              costRaw.isEmpty &&
              amountRaw.isEmpty &&
              unitRaw.isEmpty) {
            continue;
          }

          final categoryId = categoryByName[categoryRaw];
          if (categoryId == null) {
            state.skipped++;
            state.errors.add('第 ${i + 1} 行：未知品类「$categoryRaw」');
            continue;
          }

          final priceRaw = cell(priceIndex);
          final codeRaw = cell(codeIndex);
          final notesRaw = cell(notesIndex);

          final rawDate = cell(dateIndex).trim();
          DateTime? parsedDate;
          if (rawDate.isNotEmpty) {
            parsedDate = DateTime.tryParse(rawDate);
            if (parsedDate == null ||
                parsedDate.isAfter(DateTime.now()) ||
                parsedDate.isBefore(DateTime(2000))) {
              state.skipped++;
              state.errors.add('第 ${i + 1} 行：日期无效');
              continue;
            }
          }
          final purchaseDate = parsedDate ?? DateTime.now();

          if (categoryId == AssetCategoryIds.cash) {
            cashPlatformsInMain.add(name);
            final nameError = state.checkCashName(name);
            if (nameError != null) {
              state.skipped++;
              state.errors.add(nameError);
              continue;
            }
            final amount = DecimalUtils.tryParse(amountRaw) ??
                DecimalUtils.tryParse(quantityRaw);
            if (name.isEmpty || amount == null || amount <= Decimal.zero) {
              state.skipped++;
              state.errors.add('第 ${i + 1} 行：名称/金额无效');
              continue;
            }
            await state.apply(
              db,
              categoryId: categoryId,
              name: name,
              code: codeRaw.isEmpty ? null : codeRaw,
              quantity: '0',
              costPrice: '0',
              currentPrice: null,
              purchaseDate: purchaseDate,
              notes: notesRaw.isEmpty ? null : notesRaw,
              unit: null,
              amount: amount.toString(),
              cashRecords: recordsByPlatform[name] ?? const [],
              duplicates: duplicates,
            );
            continue;
          }

          final key = _holdingKey(
            categoryId,
            name,
            codeRaw.isEmpty ? null : codeRaw,
          );
          final importedTransactions =
              transactionsByKey[key] ?? const <_ImportedTransaction>[];
          final importedPrices =
              priceHistoryByKey[key] ?? const <_ImportedPricePoint>[];

          if (isV3) {
            if (name.isEmpty) {
              state.skipped++;
              state.errors.add('第 ${i + 1} 行：名称无效');
              continue;
            }
            if (importedTransactions.isEmpty) {
              state.skipped++;
              state.errors.add('第 ${i + 1} 行：缺少交易流水');
              continue;
            }
            final unit = categoryId == AssetCategoryIds.preciousMetal
                ? (unitRaw.isEmpty ? null : unitRaw)
                : null;
            await state.apply(
              db,
              categoryId: categoryId,
              name: name,
              code: codeRaw.isEmpty ? null : codeRaw,
              quantity: '0',
              costPrice: '0',
              currentPrice: priceRaw.isEmpty
                  ? null
                  : DecimalUtils.tryParse(priceRaw)?.toString(),
              purchaseDate: purchaseDate,
              notes: notesRaw.isEmpty ? null : notesRaw,
              unit: unit,
              amount: null,
              cashRecords: const [],
              duplicates: duplicates,
              isV3: true,
              transactions: importedTransactions,
              priceHistory: importedPrices,
            );
            continue;
          }

          final costPrice = DecimalUtils.tryParse(costRaw);
          Decimal? quantity;
          String? unit;
          if (categoryId == AssetCategoryIds.preciousMetal) {
            unit = unitRaw.isEmpty
                ? (quantityRaw.isNotEmpty ? '$quantityRaw克' : null)
                : unitRaw;
            quantity = ParseQuantityFromUnit.parse(unit) ??
                DecimalUtils.tryParse(quantityRaw);
            unit = ParseQuantityFromUnit.unitLabel(unit);
          } else {
            quantity = DecimalUtils.tryParse(quantityRaw);
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
            purchaseDate: purchaseDate,
            notes: notesRaw.isEmpty ? null : notesRaw,
            unit: unit,
            amount: null,
            cashRecords: const [],
            duplicates: duplicates,
            isV3: false,
            transactions: importedTransactions,
            priceHistory: importedPrices,
          );
        }
      });

      for (final platform in recordsByPlatform.keys) {
        if (!cashPlatformsInMain.contains(platform)) {
          state.errors.add('现金记录中的平台「$platform」不在持仓表中');
        }
      }

      return Result.success(state.toResult());
    } catch (e) {
      return Result.failure('导入 Excel 失败：$e');
    }
  }

  TransactionType? _parseType(String raw) {
    final text = raw.trim();
    final byStorage = TransactionType.fromStorage(text);
    if (byStorage != null) return byStorage;
    for (final type in TransactionType.values) {
      if (type.label == text) return type;
    }
    return null;
  }

  String _cellText(Data? data) {
    final value = data?.value;
    if (value == null) return '';
    return value.toString().trim();
  }
}
