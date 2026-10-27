import 'package:decimal/decimal.dart';

import 'asset_transaction.dart';

/// 新增 / 编辑交易流水时提交的数据。
class AssetTransactionDraft {
  final int holdingId;
  final TransactionType type;
  final Decimal? quantity;
  final Decimal? price;
  final Decimal? amount;
  final Decimal? fee;
  final Decimal? ratio;
  final DateTime date;
  final String? notes;

  const AssetTransactionDraft({
    required this.holdingId,
    required this.type,
    this.quantity,
    this.price,
    this.amount,
    this.fee,
    this.ratio,
    required this.date,
    this.notes,
  });
}
