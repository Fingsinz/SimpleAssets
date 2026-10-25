import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/currency_formatter.dart';
import '../theme/app_colors.dart';

/// 统一展示盈亏金额与收益率，红涨绿跌。
class ProfitText extends StatelessWidget {
  final Decimal amount;
  final double? percent;
  final TextStyle? style;
  final bool showSign;

  const ProfitText({
    super.key,
    required this.amount,
    this.percent,
    this.style,
    this.showSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final value = amount.toDouble();
    final color = AppColors.change(context, value);
    final amountText = CurrencyFormatter.money(amount);
    final sign = showSign && value > 0 ? '+' : '';
    final percentText = percent == null
        ? ''
        : ' (${CurrencyFormatter.percent(percent!)})';
    return Text(
      '$sign$amountText$percentText',
      style: (style ?? const TextStyle(fontSize: 13)).copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
