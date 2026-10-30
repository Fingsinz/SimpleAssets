import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';

import '../../core/currency_formatter.dart';

/// 金额可见性：眼睛开关打开时，所有金钱金额都换成占位符；
/// 收益率、回撤、数量不参与遮罩。
class AmountVisibility extends InheritedWidget {
  final bool hidden;

  const AmountVisibility({
    super.key,
    required this.hidden,
    required super.child,
  });

  /// 金额占位符。保留货币符号，让人知道这里原本是钱。
  static const String mask = '¥ ••••';

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AmountVisibility>()
            ?.hidden ??
        false;
  }

  @override
  bool updateShouldNotify(AmountVisibility oldWidget) =>
      hidden != oldWidget.hidden;
}

/// 在 build 里格式化金额时使用，例如 `context.money(holding.value)`。
extension AmountFormatting on BuildContext {
  bool get amountsHidden => AmountVisibility.of(this);

  String money(Decimal value) => amountsHidden
      ? AmountVisibility.mask
      : CurrencyFormatter.money(value);

  String price(Decimal value) => amountsHidden
      ? AmountVisibility.mask
      : CurrencyFormatter.price(value);

  String compactMoney(Decimal value) => amountsHidden
      ? AmountVisibility.mask
      : CurrencyFormatter.compact(value);
}
