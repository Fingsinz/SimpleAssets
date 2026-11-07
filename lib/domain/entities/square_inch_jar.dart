import 'package:decimal/decimal.dart';

/// 方寸罐中的一个合并块。
///
/// [level] 表示它代表多少个基础方寸，[value] 是它折算出的金额。
class SquareInchBlock {
  final int level;
  final Decimal value;

  const SquareInchBlock({required this.level, required this.value});
}

/// 方寸罐计算结果。
class SquareInchJar {
  /// 已夹到 >= 0 的资产。
  final Decimal asset;

  /// 每个基础方寸的价值，保证 > 0。
  final Decimal unitValue;

  /// 完整基础方寸数，向下取整。
  final int baseCount;

  /// 距下一个完整方寸的进度，范围 [0, 1)。
  final Decimal fraction;

  /// 按等级降序排列的合并块。
  final List<SquareInchBlock> blocks;

  const SquareInchJar({
    required this.asset,
    required this.unitValue,
    required this.baseCount,
    required this.fraction,
    required this.blocks,
  });

  bool get isEmpty => blocks.isEmpty;

  /// 不足一个基础方寸的余额。
  Decimal get remainderValue => asset - unitValue * Decimal.fromInt(baseCount);

  /// 再攒多少才能进入下一个基础方寸。
  Decimal get missingToNext => unitValue - remainderValue;
}
