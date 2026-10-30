import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/currency_formatter.dart';
import '../theme/app_typography.dart';
import 'amount_visibility.dart';

/// 金额文本：货币符号降级、数字等宽；支持遮罩与正号。
class MoneyText extends StatelessWidget {
  final Decimal value;
  final TextStyle style;
  final double symbolScale;
  final double symbolOpacity;
  final bool compact;
  final bool showSign;

  const MoneyText({
    super.key,
    required this.value,
    required this.style,
    this.symbolScale = 0.62,
    this.symbolOpacity = 0.72,
    this.compact = false,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final hidden = AmountVisibility.of(context);
    final amount = hidden
        ? AmountVisibility.mask
        : (compact
            ? CurrencyFormatter.compact(value)
            : CurrencyFormatter.money(value));
    final prefix =
        showSign && !hidden && value > Decimal.zero ? '+' : '';
    final raw = '$prefix$amount';
    final baseStyle = AppTypography.tabular(style);
    return Text.rich(
      TextSpan(
        children: _moneySpans(
          context,
          raw,
          baseStyle,
          symbolScale: symbolScale,
          symbolOpacity: symbolOpacity,
        ),
      ),
      style: baseStyle,
      semanticsLabel: raw,
    );
  }
}

/// 收益率文本：百分号降级，数字等宽。
class PercentText extends StatelessWidget {
  final double? value;
  final TextStyle style;
  final int digits;
  final double percentScale;
  final double percentOpacity;

  const PercentText({
    super.key,
    required this.value,
    required this.style,
    this.digits = 2,
    this.percentScale = 0.78,
    this.percentOpacity = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.tabular(style);
    if (value == null) {
      return Text('--', style: baseStyle);
    }
    final raw = CurrencyFormatter.percent(value!, digits: digits);
    final number = raw.endsWith('%')
        ? raw.substring(0, raw.length - 1)
        : raw;
    final color = _resolveColor(context, baseStyle);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: number, style: baseStyle),
          if (number != raw)
            TextSpan(
              text: '%',
              style: baseStyle.copyWith(
                fontSize: (baseStyle.fontSize ?? 14) * percentScale,
                color: color.withValues(alpha: percentOpacity),
              ),
            ),
        ],
      ),
      style: baseStyle,
      semanticsLabel: raw,
    );
  }
}

List<InlineSpan> _moneySpans(
  BuildContext context,
  String raw,
  TextStyle baseStyle, {
  required double symbolScale,
  required double symbolOpacity,
}) {
  final signMatch = RegExp(r'^[+-]').firstMatch(raw);
  final sign = signMatch?.group(0) ?? '';
  final rest = raw.substring(sign.length);
  final symbol = rest.startsWith('¥') ? '¥' : '';
  final number = rest.substring(symbol.length);
  final color = _resolveColor(context, baseStyle);
  final numberStyle = baseStyle.copyWith(
    fontSize: baseStyle.fontSize ?? 14,
  );
  return [
    if (sign.isNotEmpty) TextSpan(text: sign, style: numberStyle),
    if (symbol.isNotEmpty)
      TextSpan(
        text: symbol,
        style: baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 14) * symbolScale,
          color: color.withValues(alpha: symbolOpacity),
        ),
      ),
    TextSpan(text: number, style: numberStyle),
  ];
}

Color _resolveColor(BuildContext context, TextStyle style) =>
    style.color ??
    DefaultTextStyle.of(context).style.color ??
    Theme.of(context).colorScheme.onSurface;
