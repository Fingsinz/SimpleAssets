import '../../core/decimal_utils.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/entities/asset_transaction.dart';
import '../../domain/entities/cash_record.dart';
import '../../domain/entities/price_point.dart';
import '../local/dao/asset_dao.dart';
import '../local/database.dart';

extension HoldingWithCategoryMapper on HoldingWithCategory {
  AssetHolding toDomain() {
    final row = holding;
    return AssetHolding(
      id: row.id,
      categoryId: row.categoryId,
      categoryName: category?.name ?? row.categoryId,
      name: row.name,
      code: row.code,
      unit: row.unit,
      amount: DecimalUtils.tryParse(row.amount),
      quantity: DecimalUtils.parseOrZero(row.quantity),
      costPrice: DecimalUtils.parseOrZero(row.costPrice),
      currentPrice: DecimalUtils.tryParse(row.currentPrice),
      purchaseDate: row.purchaseDate,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

extension AssetCategoryRowMapper on AssetCategoryRow {
  AssetCategory toDomain() => AssetCategory(
        id: id,
        displayName: name,
        currencyCode: currency,
        icon: icon,
        sortOrder: sortOrder,
      );
}

extension CashRecordRowMapper on CashRecordRow {
  CashRecord toDomain() => CashRecord(
        id: id,
        holdingId: holdingId,
        amount: DecimalUtils.parseOrZero(amount),
        recordDate: recordDate,
        createdAt: createdAt,
      );
}

extension TransactionRowMapper on TransactionRow {
  AssetTransaction toDomain() {
    final parsedType = TransactionType.fromStorage(type);
    if (parsedType == null) {
      throw StateError('未知交易类型：$type');
    }
    return AssetTransaction(
      id: id,
      holdingId: holdingId,
      type: parsedType,
      amount: DecimalUtils.tryParse(amount),
      price: DecimalUtils.tryParse(price),
      quantity: DecimalUtils.tryParse(quantity),
      fee: DecimalUtils.tryParse(fee),
      ratio: DecimalUtils.tryParse(ratio),
      date: date,
      notes: notes,
    );
  }
}

extension PriceHistoryRowMapper on PriceHistoryRow {
  PricePoint toDomain() => PricePoint(
        holdingId: holdingId,
        period: period,
        price: DecimalUtils.parseOrZero(price),
        observedAt: observedAt,
      );
}
