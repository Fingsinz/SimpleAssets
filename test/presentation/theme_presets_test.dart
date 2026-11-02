import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';
import 'package:simple_assets/presentation/theme/theme_presets.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// sRGB → OKLab，用来检查品类墨之间的可辨认距离。
({double l, double a, double b}) _oklab(Color color) {
  final argb = color.toARGB32();

  double channel(int shift) {
    final value = ((argb >> shift) & 0xFF) / 255.0;
    return value <= 0.04045
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(16);
  final g = channel(8);
  final b = channel(0);
  final l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
  final m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
  final s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;
  final lRoot = math.pow(l, 1 / 3).toDouble();
  final mRoot = math.pow(m, 1 / 3).toDouble();
  final sRoot = math.pow(s, 1 / 3).toDouble();
  return (
    l: 0.2104542553 * lRoot + 0.7936177850 * mRoot - 0.0040720468 * sRoot,
    a: 1.9779984951 * lRoot - 2.4285922050 * mRoot + 0.4505937099 * sRoot,
    b: 0.0259040371 * lRoot + 0.7827717662 * mRoot - 0.8086757660 * sRoot,
  );
}

double _colorDistance(Color a, Color b) {
  final first = _oklab(a);
  final second = _oklab(b);
  final dl = first.l - second.l;
  final da = first.a - second.a;
  final db = first.b - second.b;
  return math.sqrt(dl * dl + da * da + db * db) * 100;
}

void main() {
  group('六套主题配色', () {
    test('主题文字默认启用等宽数字', () {
      final theme = AppTheme.light;
      final feature = theme.textTheme.bodyMedium?.fontFeatures?.any(
        (item) => item.feature == 'tnum',
      );
      expect(feature, isTrue);
    });

    test('主色可承载白色文字，正文与次要文字在各自底色上可读', () {
      for (final preset in AppThemePreset.values) {
        for (final brightness in Brightness.values) {
          final theme = AppTheme.forPreset(preset, brightness);
          final scheme = theme.colorScheme;
          final hero = theme.extension<AppPalette>()!.hero;
          final gradientMid = Color.lerp(hero, scheme.tertiary, 0.55) ?? hero;
          final tag = '${preset.id}/${brightness.name}';

          expect(
            _contrast(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5),
            reason: '$tag 主色上的文字对比度不足',
          );
          expect(
            _contrast(Colors.white, hero),
            greaterThanOrEqualTo(4.5),
            reason: '$tag 品牌大色块承载白字的对比度不足',
          );
          expect(
            _contrast(Colors.white, gradientMid),
            greaterThanOrEqualTo(4.5),
            reason: '$tag 头部渐变中段的文字对比度不足',
          );
          expect(
            _contrast(scheme.primary, theme.scaffoldBackgroundColor),
            greaterThanOrEqualTo(4.5),
            reason: '$tag 交互主色在页面底色上的对比度不足',
          );
          expect(
            _contrast(scheme.onPrimaryContainer, scheme.primaryContainer),
            greaterThanOrEqualTo(4.5),
            reason: '$tag 主色容器对比度不足',
          );
          expect(
            _contrast(scheme.onSurface, scheme.surface),
            greaterThanOrEqualTo(7),
            reason: '$tag 正文对比度不足',
          );
          expect(
            _contrast(scheme.onSurfaceVariant, scheme.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$tag 次要文字对比度不足',
          );
        }
      }
    });

    test('主题令牌落到 ThemeData 上', () {
      for (final preset in AppThemePreset.values) {
        for (final brightness in Brightness.values) {
          final look = preset.lookFor(brightness);
          final theme = AppTheme.forPreset(preset, brightness);
          expect(theme.scaffoldBackgroundColor, look.background);
          expect(theme.cardTheme.color, look.surface);
          expect(theme.colorScheme.primary, look.primary);
          expect(theme.colorScheme.outlineVariant, look.border);
          expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
          final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
          expect(shape.borderRadius, BorderRadius.circular(preset.cardRadius));
        }
      }
    });

    test('品类油墨随预设换色，八个品类在每套预设里齐备', () {
      const categories = [
        'cash',
        'bond',
        'fund',
        'stock',
        'etf',
        'gold',
        'custom',
        'liability',
      ];
      for (final preset in AppThemePreset.values) {
        final look = preset.lookFor(Brightness.light);
        expect(look.categoryColors.keys, containsAll(categories));
        expect(look.categoryPalette.length, greaterThanOrEqualTo(8));
      }
      final funds = AppThemePreset.values
          .map(
            (preset) =>
                preset.lookFor(Brightness.light).categoryColors['fund']!
                    .toARGB32(),
          )
          .toSet();
      expect(funds.length, AppThemePreset.values.length);
    });

    test('正资产品类墨之间保持可辨认的 OKLab 距离', () {
      const categories = [
        'cash',
        'bond',
        'fund',
        'stock',
        'etf',
        'gold',
        'custom',
      ];
      for (final preset in AppThemePreset.values) {
        final colors =
            preset.lookFor(Brightness.light).categoryColors;
        for (var i = 0; i < categories.length; i++) {
          for (var j = i + 1; j < categories.length; j++) {
            final first = colors[categories[i]]!;
            final second = colors[categories[j]]!;
            expect(
              _colorDistance(first, second),
              greaterThanOrEqualTo(10),
              reason:
                  '${preset.id} 的 ${categories[i]} 与 ${categories[j]} 色差不足',
            );
          }
        }
      }
    });

    test('涨跌红绿随预设微调，并在各自纸面上可读', () {
      for (final preset in AppThemePreset.values) {
        for (final brightness in Brightness.values) {
          final look = preset.lookFor(brightness);
          final tag = '${preset.id}/${brightness.name}';
          expect(
            _contrast(look.gain, look.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$tag 涨色在卡片底色上不可读',
          );
          expect(
            _contrast(look.loss, look.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$tag 跌色在卡片底色上不可读',
          );
        }
      }
      final gains = AppThemePreset.values
          .map((preset) => preset.lookFor(Brightness.light).gain.toARGB32())
          .toSet();
      expect(gains.length, AppThemePreset.values.length);
    });

    test('六套配色彼此可区分，未知持久化值回落靛青', () {
      final primaries = AppThemePreset.values
          .map((preset) => preset.lookFor(Brightness.light).primary.toARGB32())
          .toSet();
      expect(primaries.length, AppThemePreset.values.length);

      expect(AppThemePreset.fromId('missing'), AppThemePreset.indigo);
      expect(AppThemePreset.fromId('celadon'), AppThemePreset.celadon);
      expect(AppThemePreset.fromId('gilt'), AppThemePreset.gilt);
      expect(AppThemePreset.fromId('sky'), AppThemePreset.sky);
      expect(AppThemePreset.fromId('mint'), AppThemePreset.mint);
      expect(AppThemePreset.fromId('sunset'), AppThemePreset.sunset);
    });
  });
}
