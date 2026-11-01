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
import '../../domain/entities/balance_record.dart';
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

class _ImportedBalanceRecord {
  final Decimal amount;
  final BalanceFlowKind flowKind;
  final Decimal? flowAmount;
  final Decimal? fee;
  final DateTime recordDate;

  const _ImportedBalanceRecord({
    required this.amount,
    this.flowKind = BalanceFlowKind.none,
    this.flowAmount,
    this.fee,
    required this.recordDate,
  });

  Decimal get feeValue => fee ?? Decimal.zero;
}

bool _isAmountBasedCategory(String categoryId) =>
    categoryId == AssetCategoryIds.cash ||
    categoryId == AssetCategoryIds.liability ||
    categoryId == AssetCategoryIds.custom;

/// 金额型资产的重复判定键：品类 + 名称。
String _amountKey(String categoryId, String name) =>
    '$categoryId\u0000${name.trim()}';

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
    this._amountIds,
    this._existingAmountNameCounts,
  );

  static Future<_ImportState> load(AppDatabase db) async {
    final rows = await db.assetDao.getAllHoldings();
    final holdingIds = <String, int>{};
    final amountIds = <String, Map<String, int>>{};
    final existingAmountNameCounts = <String, Map<String, int>>{};

    for (final row in rows) {
      final holding = row.holding;
      if (_isAmountBasedCategory(holding.categoryId)) {
        final name = holding.name.trim();
        (amountIds[holding.categoryId] ??= {})[name] = holding.id;
        final counts = existingAmountNameCounts[holding.categoryId] ??= {};
        counts[name] = (counts[name] ?? 0) + 1;
        continue;
      }
      holdingIds[_holdingKey(
        holding.categoryId,
        holding.name,
        holding.code,
      )] = holding.id;
    }

    return _ImportState._(
      holdingIds,
      amountIds,
      existingAmountNameCounts,
    );
  }

  final Map<String, int> _holdingIds;
  final Map<String, Map<String, int>> _amountIds;
  final Map<String, Map<String, int>> _existingAmountNameCounts;

  /// 本次导入文件内金额型资产名称的出现次数，用于拒绝同名资产。
  final Map<String, int> fileAmountNameCounts = {};

  int imported = 0;
  int updated = 0;
  int skipped = 0;
  final errors = <String>[];

  /// 返回 null 表示可以导入；否则为需要展示给用户的冲突原因。
  String? checkAmountName(String categoryId, String name) {
    final key = _amountKey(categoryId, name);
    final label = switch (categoryId) {
      AssetCategoryIds.custom => '自定义产品',
      AssetCategoryIds.liability => '负债',
      _ => '现金平台',
    };
    if ((fileAmountNameCounts[key] ?? 0) > 1) {
      return '$label「$name」在导入文件中重复，已跳过';
    }
    final existingCounts = _existingAmountNameCounts[categoryId];
    final existingCount =
        existingCounts == null ? 0 : (existingCounts[name.trim()] ?? 0);
    if (existingCount > 1) {
      return '$label「$name」存在多个同名资产，请先重命名后再导入';
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
    required List<_ImportedBalanceRecord> balanceRecords,
    required DuplicatePolicy duplicates,
    bool isV3 = false,
    List<_ImportedTransaction> transactions = const [],
    List<_ImportedPricePoint> priceHistory = const [],
  }) async {
    final key = _holdingKey(categoryId, name, code);
    final amountIds = _amountIds[categoryId];
    final existingId = _isAmountBasedCategory(categoryId)
        ? (amountIds == null ? null : amountIds[name.trim()])
        : _holdingIds[key];

    if (_isAmountBasedCategory(categoryId)) {
      await _applyAmountBased(
        db,
        categoryId: categoryId,
        name: name,
        notes: notes,
        amount: amount ?? quantity,
        purchaseDate: purchaseDate,
        balanceRecords: balanceRecords,
        duplicates: duplicates,
      );
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

    /// 旧版文件 / 未带价格历史的 v3 文件：把 currentPrice 落成当月价格行，
    /// 保证总览（用 currentPrice）与收益细节（用 price_history）口径一致。
    Future<void> ensureCurrentPriceHistory(AppDatabase db, int id) async {
      final price = DecimalUtils.tryParse(currentPrice);
      if (price == null || price <= Decimal.zero) return;
      final period = _monthKey(DateTime.now());
      if (priceHistory.any((point) => point.period == period)) return;
      await db.priceHistoryDao.upsertMonth(
        holdingId: id,
        period: period,
        price: price.toString(),
      );
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
      await ensureCurrentPriceHistory(db, existingId);
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
    await ensureCurrentPriceHistory(db, id);
    _holdingIds[key] = id;
    imported++;
  }

  Future<void> _applyAmountBased(
    AppDatabase db, {
    required String categoryId,
    required String name,
    required String? notes,
    required String? amount,
    required DateTime purchaseDate,
    required List<_ImportedBalanceRecord> balanceRecords,
    required DuplicatePolicy duplicates,
  }) async {
    final amountIds = _amountIds[categoryId];
    final existingId = amountIds == null ? null : amountIds[name.trim()];

    final fallbackAmount = DecimalUtils.parseOrZero(amount ?? '0');
    // 自定义产品无记录且金额为 0 是合法状态（用户删空了记录）；
    // 只有在确实有金额时才把差额视为首笔投入，避免 0 金额投入被校验拒绝。
    final fallbackInvest =
        categoryId == AssetCategoryIds.custom && fallbackAmount > Decimal.zero;
    var records = balanceRecords.isEmpty
        ? <_ImportedBalanceRecord>[
            _ImportedBalanceRecord(
              amount: fallbackAmount,
              flowKind: fallbackInvest
                  ? BalanceFlowKind.invest
                  : BalanceFlowKind.none,
              flowAmount: fallbackInvest ? fallbackAmount : null,
              recordDate: purchaseDate,
            ),
          ]
        : List<_ImportedBalanceRecord>.from(balanceRecords);

    // 稳定排序：同一天保持文件中的原始顺序。
    final indexed = records.asMap().entries.toList()
      ..sort((a, b) {
        final byDate = a.value.recordDate.compareTo(b.value.recordDate);
        return byDate != 0 ? byDate : a.key.compareTo(b.key);
      });
    records = [for (final entry in indexed) entry.value];

    for (final record in records) {
      final error = _validateAmountRecord(categoryId, record);
      if (error != null) {
        skipped++;
        errors.add('「$name」的余额记录无效：$error');
        return;
      }
    }

    final latest = records.last;
    final earliest = records.first;
    final holdingDate = categoryId == AssetCategoryIds.custom
        ? earliest.recordDate
        : latest.recordDate;

    Future<void> writeRecords(int holdingId) async {
      for (final record in records) {
        await db.balanceRecordDao.insertRecord(
          BalanceRecordsCompanion.insert(
            holdingId: holdingId,
            amount: record.amount.toString(),
            flowKind: Value(record.flowKind.storageValue),
            flowAmount: Value(record.flowAmount?.toString()),
            fee: Value(record.feeValue.toString()),
            recordDate: record.recordDate,
          ),
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
          name: Value(name),
          quantity: const Value('0'),
          costPrice: const Value('0'),
          currentPrice: const Value<String?>(null),
          unit: const Value<String?>(null),
          amount: Value(latest.amount.toString()),
          purchaseDate: Value(holdingDate),
          notes: Value(notes),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await db.balanceRecordDao.deleteForHolding(existingId);
      await writeRecords(existingId);
      updated++;
      return;
    }

    final id = await db.assetDao.insertHolding(
      AssetHoldingsCompanion.insert(
        categoryId: categoryId,
        name: name,
        quantity: '0',
        costPrice: '0',
        purchaseDate: holdingDate,
        amount: Value(latest.amount.toString()),
        notes: Value(notes),
      ),
    );
    await writeRecords(id);
    (_amountIds[categoryId] ??= {})[name.trim()] = id;
    imported++;
  }

  String? _validateAmountRecord(
    String categoryId,
    _ImportedBalanceRecord record,
  ) {
    if (record.feeValue < Decimal.zero) return '手续费不能为负数';
    switch (categoryId) {
      case AssetCategoryIds.cash:
        if (record.amount <= Decimal.zero) return '现金金额必须大于 0';
        if (record.flowKind != BalanceFlowKind.none) {
          return '现金记录不支持投入 / 卖出';
        }
        break;
      case AssetCategoryIds.liability:
        if (record.amount >= Decimal.zero) return '负债金额必须小于 0';
        if (record.flowKind != BalanceFlowKind.none) {
          return '负债记录不支持投入 / 卖出';
        }
        break;
      case AssetCategoryIds.custom:
        if (record.amount < Decimal.zero) return '持有金额不能为负数';
        if (record.flowKind != BalanceFlowKind.none) {
          final flow = record.flowAmount;
          if (flow == null || flow <= Decimal.zero) {
            return '操作金额必须大于 0';
          }
        }
        break;
    }
    return null;
  }

  String _monthKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';

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
      final cashRecords = await db.balanceRecordDao.getAllRecords();
      final recordsByHolding = <int, List<BalanceRecordRow>>{};
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
        'version': 4,
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
              'balanceRecords': [
                for (final record
                    in recordsByHolding[item.holding.id] ?? const [])
                  {
                    'amount': record.amount,
                    'flowKind': record.flowKind,
                    'flowAmount': record.flowAmount,
                    'fee': record.fee,
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
      final isV4 = version >= 4;

      for (final item in holdings) {
        if (item is! Map<String, dynamic>) continue;
        final categoryId = item['categoryId']?.toString() ?? '';
        if (!_isAmountBasedCategory(categoryId)) continue;
        final name = item['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final key = _amountKey(categoryId, name);
        state.fileAmountNameCounts[key] =
            (state.fileAmountNameCounts[key] ?? 0) + 1;
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
            isV4: isV4,
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
    required bool isV4,
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

    if (_isAmountBasedCategory(categoryId)) {
      final nameError = state.checkAmountName(categoryId, name);
      if (nameError != null) return nameError;

      final records = <_ImportedBalanceRecord>[];
      if (isV4) {
        final rawRecords = item['balanceRecords'];
        if (rawRecords is List) {
          for (final raw in rawRecords) {
            if (raw is! Map) return '「$name」的余额记录格式错误';
            final recordAmount =
                DecimalUtils.tryParse(raw['amount']?.toString());
            final recordDate =
                DateTime.tryParse(raw['recordDate']?.toString() ?? '');
            if (recordAmount == null ||
                recordDate == null ||
                recordDate.isAfter(DateTime.now()) ||
                recordDate.isBefore(DateTime(2000))) {
              return '「$name」的余额记录无效';
            }
            records.add(
              _ImportedBalanceRecord(
                amount: recordAmount,
                flowKind: BalanceFlowKind.fromStorage(
                  raw['flowKind']?.toString(),
                ),
                flowAmount: DecimalUtils.tryParse(
                  raw['flowAmount']?.toString(),
                ),
                fee: DecimalUtils.tryParse(raw['fee']?.toString()),
                recordDate: recordDate,
              ),
            );
          }
        }
      } else {
        final rawRecords = item['cashRecords'];
        if (rawRecords is List) {
          for (final raw in rawRecords) {
            if (raw is! Map) return '「$name」的现金记录格式错误';
            final recordAmount =
                DecimalUtils.tryParse(raw['amount']?.toString());
            final recordDate =
                DateTime.tryParse(raw['recordDate']?.toString() ?? '');
            if (recordAmount == null ||
                recordDate == null ||
                recordDate.isAfter(DateTime.now()) ||
                recordDate.isBefore(DateTime(2000))) {
              return '「$name」的现金记录无效';
            }
            records.add(
              _ImportedBalanceRecord(
                amount: recordAmount,
                recordDate: recordDate,
              ),
            );
          }
        }
      }

      final parsedAmount = DecimalUtils.tryParse(
            item['amount']?.toString(),
          ) ??
          DecimalUtils.tryParse(item['quantity']?.toString());
      if (parsedAmount == null && records.isEmpty) {
        return '「$name」的金额无效';
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
        amount: (parsedAmount ?? records.last.amount).toString(),
        balanceRecords: records,
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
      balanceRecords: const [],
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
      final cashRecords = await db.balanceRecordDao.getAllRecords();
      final excel = Excel.createExcel();
      final sheet = excel['持仓'];
      excel.delete('Sheet1');

      sheet.appendRow([for (final header in _headers) TextCellValue(header)]);

      for (final item in rows) {
        final holding = item.holding;
        final isAmountBased = _isAmountBasedCategory(holding.categoryId);
        sheet.appendRow([
          TextCellValue(item.category?.name ?? holding.categoryId),
          TextCellValue(holding.name),
          TextCellValue(holding.code ?? ''),
          TextCellValue(isAmountBased ? '' : holding.quantity),
          TextCellValue(isAmountBased ? '' : holding.costPrice),
          TextCellValue(isAmountBased ? '' : (holding.currentPrice ?? '')),
          TextCellValue(DateFormatter.date(holding.purchaseDate)),
          TextCellValue(holding.notes ?? ''),
          TextCellValue(isAmountBased ? (holding.amount ?? '') : ''),
          TextCellValue(holding.unit ?? ''),
        ]);
      }

      final holdingByIdForBalances = {
        for (final item in rows) item.holding.id: item,
      };
      final balanceSheet = excel['余额记录'];
      balanceSheet.appendRow([
        TextCellValue('品类'),
        TextCellValue('名称'),
        TextCellValue('操作'),
        TextCellValue('金额'),
        TextCellValue('流水金额'),
        TextCellValue('手续费'),
        TextCellValue('记录日期'),
      ]);
      for (final record in cashRecords) {
        final item = holdingByIdForBalances[record.holdingId];
        if (item == null) continue;
        balanceSheet.appendRow([
          TextCellValue(item.category?.name ?? item.holding.categoryId),
          TextCellValue(item.holding.name),
          TextCellValue(
            BalanceFlowKind.fromStorage(record.flowKind).label,
          ),
          TextCellValue(record.amount),
          TextCellValue(record.flowAmount ?? ''),
          TextCellValue(record.fee),
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

      final recordsByAmountKey = <String, List<_ImportedBalanceRecord>>{};

      void addRecord(
        String categoryId,
        String name,
        _ImportedBalanceRecord record,
      ) {
        (recordsByAmountKey[_amountKey(categoryId, name)] ??= []).add(record);
      }

      final balanceSheet = excel.tables['余额记录'];
      if (balanceSheet != null && balanceSheet.rows.isNotEmpty) {
        final balanceRows = balanceSheet.rows;
        final balanceError = ImportLimits.validateRows(balanceRows.length - 1);
        if (balanceError != null) return Result.failure(balanceError);

        final balanceHeader = balanceRows.first.map(_cellText).toList();
        final bCategoryIndex = balanceHeader.indexOf('品类');
        final bNameIndex = balanceHeader.indexOf('名称');
        final bKindIndex = balanceHeader.indexOf('操作');
        final bAmountIndex = balanceHeader.indexOf('金额');
        final bFlowAmountIndex = balanceHeader.indexOf('流水金额');
        final bFeeIndex = balanceHeader.indexOf('手续费');
        final bDateIndex = balanceHeader.indexOf('记录日期');
        if (bCategoryIndex < 0 ||
            bNameIndex < 0 ||
            bAmountIndex < 0 ||
            bDateIndex < 0) {
          return Result.failure('「余额记录」表缺少品类 / 名称 / 金额 / 记录日期列');
        }

        for (var i = 1; i < balanceRows.length; i++) {
          final row = balanceRows[i];
          String cell(int index) =>
              index >= 0 && index < row.length ? _cellText(row[index]) : '';
          final categoryRaw = cell(bCategoryIndex);
          final name = cell(bNameIndex);
          final amountRaw = cell(bAmountIndex);
          final dateRaw = cell(bDateIndex);
          if (categoryRaw.isEmpty &&
              name.isEmpty &&
              amountRaw.isEmpty &&
              dateRaw.isEmpty) {
            continue;
          }
          final categoryId = categoryByName[categoryRaw];
          final amount = DecimalUtils.tryParse(amountRaw);
          final recordDate = DateTime.tryParse(dateRaw);
          if (categoryId == null ||
              name.isEmpty ||
              amount == null ||
              recordDate == null ||
              recordDate.isAfter(DateTime.now()) ||
              recordDate.isBefore(DateTime(2000))) {
            state.errors.add(
              '余额记录第 ${i + 1} 行：品类 / 名称 / 金额 / 日期无效',
            );
            continue;
          }
          addRecord(
            categoryId,
            name,
            _ImportedBalanceRecord(
              amount: amount,
              flowKind: _parseFlowKind(cell(bKindIndex)),
              flowAmount: DecimalUtils.tryParse(cell(bFlowAmountIndex)),
              fee: DecimalUtils.tryParse(cell(bFeeIndex)),
              recordDate: recordDate,
            ),
          );
        }
      } else {
        final historySheet = excel.tables['现金记录'];
        if (historySheet != null && historySheet.rows.isNotEmpty) {
          final historyRows = historySheet.rows;
          final historyError =
              ImportLimits.validateRows(historyRows.length - 1);
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
            addRecord(
              AssetCategoryIds.cash,
              platform,
              _ImportedBalanceRecord(
                amount: amount,
                recordDate: recordDate,
              ),
            );
          }
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

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        String cell(int index) =>
            index >= 0 && index < row.length ? _cellText(row[index]) : '';
        final categoryId = categoryByName[cell(categoryIndex)];
        if (categoryId == null || !_isAmountBasedCategory(categoryId)) {
          continue;
        }
        final name = cell(nameIndex).trim();
        if (name.isEmpty) continue;
        final key = _amountKey(categoryId, name);
        state.fileAmountNameCounts[key] =
            (state.fileAmountNameCounts[key] ?? 0) + 1;
      }

      final amountKeysInMain = <String>{};
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

          if (_isAmountBasedCategory(categoryId)) {
            amountKeysInMain.add(_amountKey(categoryId, name));
            final nameError = state.checkAmountName(categoryId, name);
            if (nameError != null) {
              state.skipped++;
              state.errors.add(nameError);
              continue;
            }
            final amount = DecimalUtils.tryParse(amountRaw) ??
                DecimalUtils.tryParse(quantityRaw);
            final records = recordsByAmountKey[_amountKey(categoryId, name)] ??
                const <_ImportedBalanceRecord>[];
            if (name.isEmpty || (amount == null && records.isEmpty)) {
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
              amount: (amount ?? records.last.amount).toString(),
              balanceRecords: records,
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
              balanceRecords: const [],
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
            balanceRecords: const [],
            duplicates: duplicates,
            isV3: false,
            transactions: importedTransactions,
            priceHistory: importedPrices,
          );
        }
      });

      for (final key in recordsByAmountKey.keys) {
        if (!amountKeysInMain.contains(key)) {
          final name = key.split('\u0000').last;
          state.errors.add('余额记录中的资产「$name」不在持仓表中');
        }
      }

      return Result.success(state.toResult());
    } catch (e) {
      return Result.failure('导入 Excel 失败：$e');
    }
  }

  BalanceFlowKind _parseFlowKind(String raw) {
    final text = raw.trim();
    for (final kind in BalanceFlowKind.values) {
      if (kind.storageValue == text || kind.label == text) return kind;
    }
    return BalanceFlowKind.none;
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
