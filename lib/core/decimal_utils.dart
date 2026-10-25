import 'package:decimal/decimal.dart';

/// Decimal 解析与计算工具。金融金额一律使用 Decimal，禁止 double 参与计算。
class DecimalUtils {
  DecimalUtils._();

  /// 容错解析：支持千分位、前后空格、空字符串。非法输入返回 null。
  static Decimal? tryParse(String? value) {
    if (value == null) return null;
    final cleaned = value.replaceAll(',', '').replaceAll('，', '').trim();
    if (cleaned.isEmpty) return null;
    try {
      return Decimal.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  static Decimal parseOrZero(String? value) => tryParse(value) ?? Decimal.zero;

  static Decimal sum(Iterable<Decimal> values) {
    var total = Decimal.zero;
    for (final value in values) {
      total += value;
    }
    return total;
  }

  /// 数据库统一以字符串保存 Decimal。
  static String toStorage(Decimal value) => value.toString();

  static Decimal multiply(Decimal a, Decimal b) => a * b;

  /// 安全的百分比计算，分母为 0 时返回 0。
  static double percentOf(Decimal part, Decimal whole) {
    if (whole <= Decimal.zero) return 0;
    return ((part * Decimal.fromInt(100)) / whole).toDouble();
  }

  static bool isPositive(Decimal value) => value > Decimal.zero;
}
