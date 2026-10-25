import 'package:decimal/decimal.dart';

import 'asset_holding.dart';

/// 新增/编辑持仓时提交的数据。
class AssetHoldingDraft {
  final String categoryId;
  final String name;
  final String? code;
  final Decimal quantity;
  final Decimal costPrice;
  final Decimal? currentPrice;
  final DateTime purchaseDate;
  final String? notes;

  const AssetHoldingDraft({
    required this.categoryId,
    required this.name,
    this.code,
    required this.quantity,
    required this.costPrice,
    this.currentPrice,
    required this.purchaseDate,
    this.notes,
  });

  factory AssetHoldingDraft.fromHolding(AssetHolding holding) => AssetHoldingDraft(
        categoryId: holding.categoryId,
        name: holding.name,
        code: holding.code,
        quantity: holding.quantity,
        costPrice: holding.costPrice,
        currentPrice: holding.currentPrice,
        purchaseDate: holding.purchaseDate,
        notes: holding.notes,
      );
}
