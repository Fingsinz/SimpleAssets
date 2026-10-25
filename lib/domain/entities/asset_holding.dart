import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
    required Decimal quantity,
    required Decimal costPrice,
    Decimal? currentPrice,
    required DateTime purchaseDate,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
    /// 联表查询得到的品类名，仅用于展示。
    String? categoryName,
  }) = _AssetHolding;

  Decimal get costValue => costPrice * quantity;

  Decimal? get currentValue =>
      currentPrice != null ? currentPrice! * quantity : null;

  /// 未更新现价时以成本计价，保证总览数据完整。
  Decimal get effectiveValue => currentValue ?? costValue;

  Decimal get profit => effectiveValue - costValue;

  bool get hasCurrentPrice => currentPrice != null && currentPrice! > Decimal.zero;

  double get returnRate {
    if (costValue <= Decimal.zero) return 0;
    return ((profit * Decimal.fromInt(100)) / costValue).toDouble();
  }

  int get holdingDays {
    final days = DateTime.now().difference(purchaseDate).inDays;
    return days < 0 ? 0 : days;
  }
}
