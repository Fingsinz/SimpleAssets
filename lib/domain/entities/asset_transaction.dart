import 'package:decimal/decimal.dart';

/// 交易流水类型。
enum TransactionType {
  buy,
  sell,
  dividend,
  split;

  /// 数据库与导入导出使用的稳定值。
  String get storageValue => name;

  String get label => switch (this) {
        TransactionType.buy => '买入',
        TransactionType.sell => '卖出',
        TransactionType.dividend => '分红',
        TransactionType.split => '拆股/折算',
      };

  static TransactionType? fromStorage(String? value) {
    for (final type in TransactionType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

/// 一笔交易流水。金额使用 Decimal，可空字段由具体类型决定。
class AssetTransaction {
  final int id;
  final int holdingId;
  final TransactionType type;
  final Decimal? amount;
  final Decimal? price;
  final Decimal? quantity;
  final Decimal? fee;
  final Decimal? ratio;
  final DateTime date;
  final String? notes;

  const AssetTransaction({
    required this.id,
    required this.holdingId,
    required this.type,
    this.amount,
    this.price,
    this.quantity,
    this.fee,
    this.ratio,
    required this.date,
    this.notes,
  });

  Decimal get grossAmount => amount ?? Decimal.zero;

  Decimal get feeValue => fee ?? Decimal.zero;

  /// 买入总成本（含手续费）。
  Decimal get buyCost => grossAmount + feeValue;

  /// 卖出净所得（扣手续费）。
  Decimal get sellProceeds => grossAmount - feeValue;

  /// 分红净额（扣手续费 / 税）。
  Decimal get netDividend => grossAmount - feeValue;
}
