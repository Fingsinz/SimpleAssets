import 'package:decimal/decimal.dart';

/// 一笔现金余额记录。属于某个现金平台（AssetHolding）。
class CashRecord {
  final int id;
  final int holdingId;
  final Decimal amount;
  final DateTime recordDate;
  final DateTime createdAt;

  const CashRecord({
    required this.id,
    required this.holdingId,
    required this.amount,
    required this.recordDate,
    required this.createdAt,
  });
}
