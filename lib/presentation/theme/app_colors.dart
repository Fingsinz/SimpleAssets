import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color seed = Color(0xFF4A5CF5);

  /// 涨跌配色遵循 A 股习惯：红涨绿跌。
  static Color gain(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFF6B6B)
          : const Color(0xFFE5484D);

  static Color loss(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3DD68C)
          : const Color(0xFF18A058);

  static Color change(BuildContext context, double value) {
    if (value > 0) return gain(context);
    if (value < 0) return loss(context);
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static const Map<String, Color> categoryColors = {
    'cash': Color(0xFF5B8DEF),
    'bond': Color(0xFF57B8A8),
    'fund': Color(0xFFF2A93B),
    'stock': Color(0xFFE5646E),
    'etf': Color(0xFF9B8AFB),
    'gold': Color(0xFFD4A84B),
  };

  static const List<Color> palette = [
    Color(0xFF5B8DEF),
    Color(0xFF57B8A8),
    Color(0xFFF2A93B),
    Color(0xFFE5646E),
    Color(0xFF9B8AFB),
    Color(0xFFD4A84B),
    Color(0xFF4EC9B0),
    Color(0xFFB07CF5),
  ];

  static Color categoryColor(String id, [int fallbackIndex = 0]) =>
      categoryColors[id] ?? palette[fallbackIndex % palette.length];

  static IconData categoryIcon(String id) {
    switch (id) {
      case 'cash':
        return Icons.account_balance_wallet_rounded;
      case 'bond':
        return Icons.receipt_long_rounded;
      case 'fund':
        return Icons.pie_chart_rounded;
      case 'stock':
        return Icons.show_chart_rounded;
      case 'etf':
        return Icons.stacked_line_chart_rounded;
      case 'gold':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.savings_rounded;
    }
  }
}
