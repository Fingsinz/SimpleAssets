import 'package:decimal/decimal.dart';

/// 从贵金属的「持有单位」文本中提取数量。
///
/// 例：`10克` → 10，`1,000克` → 1000，`5 枚` → 5。
/// 没有数字、数量不大于 0 或为负数时返回 null。
class ParseQuantityFromUnit {
  ParseQuantityFromUnit._();

  static final RegExp _numberPattern =
      RegExp(r'-?(?:\d+(?:\.\d+)?|\.\d+)');

  static Decimal? parse(String? unit) {
    final text = unit?.trim().replaceAll(RegExp(r'[,，]'), '');
    if (text == null || text.isEmpty) return null;

    final match = _numberPattern.firstMatch(text);
    if (match == null) return null;

    final value = Decimal.tryParse(match.group(0)!);
    if (value == null || value <= Decimal.zero) return null;
    return value;
  }
}
