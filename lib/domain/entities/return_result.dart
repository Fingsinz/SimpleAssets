import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'return_result.freezed.dart';

/// 单笔持仓的收益计算结果。
@freezed
abstract class ReturnResult with _$ReturnResult {
  const ReturnResult._();

  const factory ReturnResult({
    required Decimal totalCost,
    required Decimal currentValue,
    required Decimal profit,
    required double returnRate,
    double? annualizedRate,
    @Default(false) bool hasPrice,
  }) = _ReturnResult;

  static ReturnResult empty() => ReturnResult(
        totalCost: Decimal.zero,
        currentValue: Decimal.zero,
        profit: Decimal.zero,
        returnRate: 0,
      );
}
