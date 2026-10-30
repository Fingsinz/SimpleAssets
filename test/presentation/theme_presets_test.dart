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

void main() {
  group('三套主题配色', () {
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

    test('品类油墨随预设换色，六个品类在每套预设里齐备', () {
      const categories = ['cash', 'bond', 'fund', 'stock', 'etf', 'gold'];
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

    test('三套配色彼此可区分，未知持久化值回落靛青', () {
      final primaries = AppThemePreset.values
          .map((preset) => preset.lookFor(Brightness.light).primary.toARGB32())
          .toSet();
      expect(primaries.length, AppThemePreset.values.length);

      expect(AppThemePreset.fromId('missing'), AppThemePreset.indigo);
      expect(AppThemePreset.fromId('celadon'), AppThemePreset.celadon);
      expect(AppThemePreset.fromId('gilt'), AppThemePreset.gilt);
    });
  });
}
