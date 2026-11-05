import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/presentation/common/app_menu.dart';
import 'package:simple_assets/presentation/theme/app_colors.dart';
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

    test('下拉菜单跟随页面样式', () {
      final look = AppThemePreset.indigo.lookFor(Brightness.light);
      final native = appPopupMenuThemeFor(AppTheme.light);
      final nativeShape = native.shape! as RoundedRectangleBorder;
      expect(native.color, look.surface);
      expect(native.elevation, 0);
      expect(native.surfaceTintColor, Colors.transparent);
      expect(
        nativeShape.borderRadius,
        BorderRadius.circular(AppThemePreset.indigo.controlRadius),
      );
      expect(nativeShape.side.width, 0.8);

      final ledger = appPopupMenuThemeFor(
        AppTheme.lightFor(AppThemePreset.indigo, AppLayoutStyle.ledger),
      );
      final ledgerShape = ledger.shape! as RoundedRectangleBorder;
      expect(ledgerShape.borderRadius, BorderRadius.zero);
      expect(ledgerShape.side.width, 1.2);
      expect(ledgerShape.side.color, look.outline);
    });

    test('底部导航选中态只染图标，不画指示器', () {
      final theme = AppTheme.light;
      final nav = theme.navigationBarTheme;

      expect(nav.indicatorColor, Colors.transparent);
      expect(
        nav.iconTheme!.resolve({WidgetState.selected})!.color,
        theme.colorScheme.primary,
      );
      expect(
        nav.iconTheme!.resolve(<WidgetState>{})!.color,
        theme.colorScheme.onSurfaceVariant,
      );
    });

    test('主色可承载白色文字，正文与次要文字在各自底色上可读', () {
      for (final preset in AppThemePreset.values) {
        for (final brightness in Brightness.values) {
          final theme = AppTheme.forPreset(preset, brightness);
          final scheme = theme.colorScheme;
          final hero = theme.extension<AppPalette>()!.hero;
          final inkBottom = Color.lerp(hero, scheme.tertiary, 0.38) ?? hero;
          final inkTop = Color.lerp(hero, Colors.black, 0.10) ?? hero;
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
            _contrast(Colors.white, inkTop),
            greaterThanOrEqualTo(4.5),
            reason: '$tag 头部墨洗顶部的文字对比度不足',
          );
          expect(
            _contrast(Colors.white, inkBottom),
            greaterThanOrEqualTo(4.5),
            reason: '$tag 头部墨洗底部的文字对比度不足',
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
          final defaultTheme = AppTheme.forPreset(preset, brightness);
          expect(
            defaultTheme.extension<AppPalette>()!.style,
            AppLayoutStyle.native,
          );

          final theme = AppTheme.forPreset(
            preset,
            brightness,
            AppLayoutStyle.ledger,
          );
          expect(theme.scaffoldBackgroundColor, look.background);
          expect(theme.cardTheme.color, look.surface);
          expect(theme.colorScheme.primary, look.primary);
          expect(theme.colorScheme.outlineVariant, look.border);
          expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
          final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
          expect(shape.borderRadius, BorderRadius.zero);
          expect(shape.side.width, 1.2);
          expect(theme.extension<AppPalette>()!.style, AppLayoutStyle.ledger);

          final native = AppTheme.forPreset(
            preset,
            brightness,
            AppLayoutStyle.native,
          );
          final nativeShape = native.cardTheme.shape! as RoundedRectangleBorder;
          expect(nativeShape.borderRadius, BorderRadius.circular(preset.cardRadius));
          expect(nativeShape.side.width, 0.8);
          expect(native.cardTheme.color, look.surface);
          expect(
            native.extension<AppPalette>()!.style,
            AppLayoutStyle.native,
          );
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

    test('品类印记把墨压深到反白单字可读，且每个品类都有单字', () {
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
        for (final brightness in Brightness.values) {
          final look = preset.lookFor(brightness);
          for (final id in categories) {
            final stamp = AppColors.categoryStampInk(
              look.categoryColors[id]!,
            );
            expect(
              _contrast(Colors.white, stamp),
              greaterThanOrEqualTo(4.5),
              reason: '${preset.id}/${brightness.name} 的 $id 印记白字对比度不足',
            );
            expect(
              AppColors.categoryGlyph(id),
              isNotNull,
              reason: '$id 缺少印记单字',
            );
          }
        }
      }
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
        for (final brightness in Brightness.values) {
          final colors = preset.lookFor(brightness).categoryColors;
          for (var i = 0; i < categories.length; i++) {
            for (var j = i + 1; j < categories.length; j++) {
              final first = colors[categories[i]]!;
              final second = colors[categories[j]]!;
              expect(
                _colorDistance(first, second),
                greaterThanOrEqualTo(10),
                reason:
                    '${preset.id}/${brightness.name} 的 '
                    '${categories[i]} 与 ${categories[j]} 色差不足',
              );
            }
          }
        }
      }
    });

    test('同一品类跨预设是换过墨的，不是同一支墨换个名字', () {
      const categories = [
        'cash',
        'bond',
        'fund',
        'stock',
        'etf',
        'gold',
        'custom',
      ];
      for (final brightness in Brightness.values) {
        for (final category in categories) {
          for (var i = 0; i < AppThemePreset.values.length; i++) {
            for (var j = i + 1; j < AppThemePreset.values.length; j++) {
              final first = AppThemePreset.values[i]
                  .lookFor(brightness)
                  .categoryColors[category]!;
              final second = AppThemePreset.values[j]
                  .lookFor(brightness)
                  .categoryColors[category]!;
              expect(
                _colorDistance(first, second),
                greaterThanOrEqualTo(3),
                reason:
                    '$category 在 ${AppThemePreset.values[i].id} 与 '
                    '${AppThemePreset.values[j].id}（${brightness.name}）'
                    '之间几乎没换墨',
              );
            }
          }
        }
      }
    });

    test('夜色纸上的品类油墨整体提亮', () {
      for (final preset in AppThemePreset.values) {
        final light = preset.lookFor(Brightness.light).categoryColors;
        final dark = preset.lookFor(Brightness.dark).categoryColors;
        for (final entry in light.entries) {
          expect(
            _colorDistance(entry.value, dark[entry.key]!),
            greaterThanOrEqualTo(4),
            reason: '${preset.id} 的 ${entry.key} 在夜色纸上没有提亮',
          );
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
