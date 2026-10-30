import 'package:flutter/material.dart';

import 'theme_presets.dart';

class AppColors {
  AppColors._();

  /// 当前预设的颜色决策；主题未挂载扩展时回落到靛青浅色。
  static ThemeLook? _look(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()?.look;

  /// 涨跌配色遵循 A 股习惯：红涨绿跌，冷暖随预设微调。
  static Color gain(BuildContext context) {
    final look = _look(context);
    if (look != null) return look.gain;
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF6B7A)
        : const Color(0xFFD63842);
  }

  static Color loss(BuildContext context) {
    final look = _look(context);
    if (look != null) return look.loss;
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3DD68C)
        : const Color(0xFF0E8145);
  }

  static Color change(BuildContext context, double value) {
    if (value > 0) return gain(context);
    if (value < 0) return loss(context);
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// 品类油墨：同一品类在饼图、图例、图标底与图标上始终同色。
  static Color categoryColor(
    BuildContext context,
    String id, [
    int fallbackIndex = 0,
  ]) {
    final look = _look(context);
    if (look == null) return _fallbackCategoryColors[id] ?? _fallbackPalette[0];
    return look.categoryColors[id] ??
        look.categoryPalette[fallbackIndex % look.categoryPalette.length];
  }

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

  /// 仅在没有主题扩展的极端场景（独立 widget 测试）下使用。
  static const Map<String, Color> _fallbackCategoryColors = {
    'cash': Color(0xFF5B8DEF),
    'bond': Color(0xFF57B8A8),
    'fund': Color(0xFFE8A02F),
    'stock': Color(0xFFE5646E),
    'etf': Color(0xFF9B8AFB),
    'gold': Color(0xFFD4A84B),
  };

  static const List<Color> _fallbackPalette = [
    Color(0xFF5B8DEF),
    Color(0xFF57B8A8),
    Color(0xFFE8A02F),
    Color(0xFFE5646E),
    Color(0xFF9B8AFB),
    Color(0xFFD4A84B),
    Color(0xFF4EC9B0),
    Color(0xFFB07CF5),
  ];
}
