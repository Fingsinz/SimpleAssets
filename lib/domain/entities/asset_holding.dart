import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'asset_category.dart';

part 'asset_holding.freezed.dart';

/// 一笔持仓。金额统一使用 Decimal，避免浮点误差。
@freezed
abstract class AssetHolding with _$AssetHolding {
  const AssetHolding._();

  const factory AssetHolding({
    required int id,
    required String categoryId,
    required String name,
    String? code,
    /// 贵金属持有单位原文，如 `10克`。
    String? unit,
    /// 现金最新金额。
    Decimal? amount,
    required Decimal quantity,
    required Decimal costPrice,
    Decimal? currentPrice,
    required DateTime purchaseDate,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
    /// 联表查询得到的品类名，仅用于展示。
    String? categoryName,
    Decimal? totalBuy,
    Decimal? totalSell,
    Decimal? totalDividends,
    Decimal? totalFees,
    Decimal? realizedProfit,
    DateTime? firstTransactionDate,
  }) = _AssetHolding;

  bool get isCash => categoryId == AssetCategoryIds.cash;

  bool get isPreciousMetal => categoryId == AssetCategoryIds.preciousMetal;

  Decimal get costValue =>
      isCash ? (amount ?? Decimal.zero) : costPrice * quantity;

  Decimal? get currentValue =>
      isCash ? amount : (currentPrice != null ? currentPrice! * quantity : null);

  /// 未更新现价时以成本计价，保证总览数据完整。
  Decimal get effectiveValue => currentValue ?? costValue;

  /// 累计投入：有流水统计时用累计买入，否则退化为剩余成本。
  Decimal get investedCost => totalBuy ?? costValue;

  /// 累计收益 = 期末市值 + 累计卖出 + 累计分红 − 累计买入。
  Decimal get cumulativeProfit => isCash
      ? Decimal.zero
      : effectiveValue +
          (totalSell ?? Decimal.zero) +
          (totalDividends ?? Decimal.zero) -
          investedCost;

  Decimal get profit => cumulativeProfit;

  /// 已实现收益（无流水统计时为 0）。
  Decimal get realized => realizedProfit ?? Decimal.zero;

  /// 现金没有涨跌概念，始终视为未更新现价。
  bool get hasCurrentPrice =>
      !isCash && currentPrice != null && currentPrice! > Decimal.zero;

  /// 摊薄收益率 = 累计收益 / 剩余持仓成本（净投入）。
  ///
  /// 清仓或净投入 ≤ 0 时退回累计投入，避免除零，同时保留清仓后的累计收益率。
  double get returnRate {
    final base = isCash
        ? Decimal.zero
        : (quantity > Decimal.zero && costValue > Decimal.zero
            ? costValue
            : investedCost);
    if (base <= Decimal.zero) return 0;
    return ((profit * Decimal.fromInt(100)) / base).toDouble();
  }

  int get holdingDays {
    final days = DateTime.now().difference(purchaseDate).inDays;
    return days < 0 ? 0 : days;
  }
}
