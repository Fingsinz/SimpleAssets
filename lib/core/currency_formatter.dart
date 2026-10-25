import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// 货币与数字格式化。
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _money = NumberFormat('#,##0.00', 'zh_CN');
  static final NumberFormat _price = NumberFormat('#,##0.0000', 'zh_CN');
  static final NumberFormat _quantity = NumberFormat('#,##0.####', 'zh_CN');

  static String money(Decimal value, {String symbol = '¥'}) {
    final text = _money.format(value.toDouble());
    if (text.startsWith('-')) {
      return '-$symbol${text.substring(1)}';
    }
    return '$symbol$text';
  }

  static String price(Decimal value, {String symbol = '¥'}) {
    final text = _price.format(value.toDouble());
    if (text.startsWith('-')) {
      return '-$symbol${text.substring(1)}';
    }
    return '$symbol$text';
  }

  static String quantity(Decimal value) => _quantity.format(value.toDouble());

  static String percent(double value, {int digits = 2}) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(digits)}%';
  }

  /// 大额数字缩写，例如 12.34万 / 1.23亿。
  static String compact(Decimal value, {String symbol = '¥'}) {
    final number = value.toDouble();
    final abs = number.abs();
    if (abs >= 100000000) {
      return '$symbol${(number / 100000000).toStringAsFixed(2)}亿';
    }
    if (abs >= 10000) {
      return '$symbol${(number / 10000).toStringAsFixed(2)}万';
    }
    return money(value, symbol: symbol);
  }
}
