import 'package:decimal/decimal.dart';

/// 某个持仓在某个自然月内最后一次观察到的价格。
class PricePoint {
  final int holdingId;

  /// YYYY-MM
  final String period;
  final Decimal price;
  final DateTime observedAt;

  const PricePoint({
    required this.holdingId,
    required this.period,
    required this.price,
    required this.observedAt,
  });
}
