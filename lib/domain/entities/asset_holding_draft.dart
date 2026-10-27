import 'package:decimal/decimal.dart';

import 'asset_holding.dart';

/// 新增/编辑持仓时提交的数据。
class AssetHoldingDraft {
  final String categoryId;
  final String name;
  final String? code;
  final String? unit;
  final Decimal? amount;
  final Decimal quantity;
  final Decimal costPrice;
  /// 首笔买入手续费。
  final Decimal? fee;
  final Decimal? currentPrice;
  final DateTime purchaseDate;
  final String? notes;

  const AssetHoldingDraft({
    required this.categoryId,
    required this.name,
    this.code,
    this.unit,
    this.amount,
    required this.quantity,
    required this.costPrice,
    this.fee,
    this.currentPrice,
    required this.purchaseDate,
    this.notes,
  });

  factory AssetHoldingDraft.fromHolding(AssetHolding holding) => AssetHoldingDraft(
        categoryId: holding.categoryId,
        name: holding.name,
        code: holding.code,
        unit: holding.unit,
        amount: holding.amount,
        quantity: holding.quantity,
        costPrice: holding.costPrice,
        currentPrice: holding.currentPrice,
        purchaseDate: holding.purchaseDate,
        notes: holding.notes,
      );
}
