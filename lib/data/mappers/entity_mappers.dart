import '../../core/decimal_utils.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_holding.dart';
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
