import 'package:decimal/decimal.dart';

/// 余额记录附带的现金流向。
///
/// 现金与负债只有余额快照（[none]）；自定义产品每次更新可以同时记录
/// 一笔新投入（[invest]）或卖出（[sell]）。
enum BalanceFlowKind {
  none,
  invest,
  sell;

  String get storageValue => name;

  String get label => switch (this) {
        BalanceFlowKind.none => '无变化',
        BalanceFlowKind.invest => '新投入',
        BalanceFlowKind.sell => '卖出',
      };

  static BalanceFlowKind fromStorage(String? value) {
    for (final kind in BalanceFlowKind.values) {
      if (kind.name == value) return kind;
    }
    return BalanceFlowKind.none;
  }
}

/// 一条余额记录：现金 / 负债的余额快照，或自定义产品的一次更新。
class BalanceRecord {
  final int id;
  final int holdingId;

  /// 本次记录后的余额 / 持有金额；负债为负数。
  final Decimal amount;
  final BalanceFlowKind flowKind;

  /// 本次新投入或卖出金额，与 [flowKind] 配套。
  final Decimal? flowAmount;
  final Decimal? fee;
  final DateTime recordDate;
  final DateTime createdAt;

  const BalanceRecord({
    required this.id,
    required this.holdingId,
    required this.amount,
    this.flowKind = BalanceFlowKind.none,
    this.flowAmount,
    this.fee,
    required this.recordDate,
    required this.createdAt,
  });

  Decimal get grossFlow => flowAmount ?? Decimal.zero;

  Decimal get feeValue => fee ?? Decimal.zero;

  /// 新投入计入累计成本（含手续费）。
  Decimal get buyCost =>
      flowKind == BalanceFlowKind.invest ? grossFlow + feeValue : Decimal.zero;

  /// 卖出计入累计回金（扣手续费）。
  Decimal get sellProceeds =>
      flowKind == BalanceFlowKind.sell
          ? grossFlow - feeValue
          : Decimal.zero;
}

/// 新增 / 编辑余额记录时提交的数据。
class BalanceRecordDraft {
  final Decimal amount;
  final BalanceFlowKind flowKind;
  final Decimal? flowAmount;
  final Decimal? fee;
  final DateTime recordDate;

  const BalanceRecordDraft({
    required this.amount,
    this.flowKind = BalanceFlowKind.none,
    this.flowAmount,
    this.fee,
    required this.recordDate,
  });

  Decimal get feeValue => fee ?? Decimal.zero;
}
