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

  /// 品类油墨：同一品类在饼图、图例与品类印记上始终同色。
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

  /// 品类印记上的反白单字。
  static String? categoryGlyph(String id) {
    switch (id) {
      case 'cash':
        return '现';
      case 'bond':
        return '债';
      case 'fund':
        return '基';
      case 'stock':
        return '股';
      case 'etf':
        return 'E';
      case 'gold':
        return '金';
      case 'custom':
        return '自';
      case 'liability':
        return '负';
      default:
        return null;
    }
  }

  /// 印泥底：把品类墨压深到反白单字仍有 4.5:1 对比度。
  ///
  /// 印泥本来比淡彩浓，压深后仍是同一支墨，不另造颜色。
  static Color categoryStampInk(Color ink) {
    if (_whiteContrast(ink) >= 4.5) return ink;
    var blended = ink;
    for (var step = 1; step <= 10; step++) {
      blended = Color.lerp(ink, const Color(0xFF000000), step * 0.05)!;
      if (_whiteContrast(blended) >= 4.5) return blended;
    }
    return blended;
  }

  static double _whiteContrast(Color color) =>
      1.05 / (color.computeLuminance() + 0.05);

  /// 仅在没有主题扩展的极端场景（独立 widget 测试）下使用。
  static const Map<String, Color> _fallbackCategoryColors = {
    'cash': Color(0xFF3E96EA),
    'bond': Color(0xFF54B1A6),
    'fund': Color(0xFFEB881F),
    'stock': Color(0xFFE26272),
    'etf': Color(0xFFB298F9),
    'gold': Color(0xFFC3B351),
    'custom': Color(0xFFA55D96),
    'liability': Color(0xFF7B8395),
  };

  static const List<Color> _fallbackPalette = [
    Color(0xFF3E96EA),
    Color(0xFF54B1A6),
    Color(0xFFEB881F),
    Color(0xFFE26272),
    Color(0xFFB298F9),
    Color(0xFFC3B351),
    Color(0xFFA55D96),
    Color(0xFF7B8395),
  ];
}
