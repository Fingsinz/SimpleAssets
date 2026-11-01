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
    /// 金额型资产的最新余额 / 持有金额。
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

  bool get isLiability => categoryId == AssetCategoryIds.liability;

  bool get isCustom => categoryId == AssetCategoryIds.custom;

  /// 现金与负债都按余额记录估值。
  bool get isCashLike => isCash || isLiability;

  /// 现金、负债与自定义产品都没有数量 / 单价。
  bool get isAmountBased => isCashLike || isCustom;

  /// 参与理财收益分析的资产：除现金与负债外的全部品类。
  bool get isInvestment => !isCashLike;

  /// 价格型资产：有数量 / 单价、可记录交易流水的品类。
  ///
  /// 自定义产品虽然参与分析，但只走余额记录，不接受交易流水。
  bool get isPriceBased => !isAmountBased;

  /// 自定义产品没有数量概念，持有金额为 0 时也不应视为已清仓。
  bool get isClosed =>
      isInvestment && !isCustom && quantity == Decimal.zero;

  Decimal get costValue {
    if (isCustom) return totalBuy ?? (amount ?? Decimal.zero);
    if (isCashLike) return amount ?? Decimal.zero;
    return costPrice * quantity;
  }

  Decimal? get currentValue {
    if (isAmountBased) return amount;
    return currentPrice != null ? currentPrice! * quantity : null;
  }

  /// 未更新现价时以成本计价，保证总览数据完整。
  Decimal get effectiveValue => currentValue ?? costValue;

  /// 累计投入：有流水统计时用累计买入，否则退化为剩余成本。
  Decimal get investedCost => totalBuy ?? costValue;

  /// 累计收益 = 期末市值 + 累计卖出 + 累计分红 − 累计买入。
  ///
  /// 现金与负债没有涨跌，收益恒为 0；自定义产品的累计买卖来自余额记录。
  Decimal get cumulativeProfit => isCashLike
      ? Decimal.zero
      : effectiveValue +
          (totalSell ?? Decimal.zero) +
          (totalDividends ?? Decimal.zero) -
          investedCost;

  Decimal get profit => cumulativeProfit;

  /// 已实现收益（无流水统计时为 0）。
  Decimal get realized => realizedProfit ?? Decimal.zero;

  /// 金额型资产没有涨跌概念，始终视为未更新现价。
  bool get hasCurrentPrice =>
      !isAmountBased && currentPrice != null && currentPrice! > Decimal.zero;

  /// 是否具备可用于估值的当前金额 / 现价。
  ///
  /// 现金与负债不参与分析；自定义产品有持有金额即可估值；
  /// 其余资产要求已更新现价。
  bool get hasValuation {
    if (isCashLike) return false;
    if (isCustom) return amount != null;
    return hasCurrentPrice;
  }

  /// 摊薄收益率 = 累计收益 / 剩余持仓成本（净投入）。
  ///
  /// 清仓或净投入 ≤ 0 时退回累计投入，避免除零，同时保留清仓后的累计收益率。
  /// 自定义产品没有剩余数量，直接以累计投入为分母。
  double get returnRate {
    if (isCashLike) return 0;
    final base = isCustom
        ? (investedCost > Decimal.zero ? investedCost : costValue)
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
