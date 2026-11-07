import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/square_inch_jar.dart';
import 'package:simple_assets/presentation/freedom/widgets/square_jar_layout.dart';
import 'package:simple_assets/presentation/freedom/widgets/square_jar_painter.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';
import 'package:simple_assets/presentation/theme/theme_presets.dart';

List<SquareInchBlock> _blocks() => [
      for (final level in [4096, 512, 128, 64, 32, 16, 8, 4])
        SquareInchBlock(level: level, value: Decimal.fromInt(level * 100)),
    ];

void main() {
  test('方块不重叠、不越界，且是正方形', () {
    final layout = SquareJarLayout.pack(
      blocks: _blocks(),
      width: 300,
      height: 168,
    );

    expect(layout.tiles.length, 8);
    for (final tile in layout.tiles) {
      expect(tile.rect.left, greaterThanOrEqualTo(-0.001));
      expect(tile.rect.top, greaterThanOrEqualTo(-0.001));
      expect(tile.rect.right, lessThanOrEqualTo(300.001));
      expect(tile.rect.bottom, lessThanOrEqualTo(168.001));
      expect(tile.rect.width, closeTo(tile.rect.height, 0.001));
    }
    for (var i = 0; i < layout.tiles.length; i++) {
      for (var j = i + 1; j < layout.tiles.length; j++) {
        expect(layout.tiles[i].rect.overlaps(layout.tiles[j].rect), isFalse);
      }
    }
    expect(
      layout.tiles[0].rect.width / layout.tiles[1].rect.width,
      closeTo(math.sqrt(4096 / 512), 0.02),
    );
  });

  test('六套主题、明暗模式下块面白字对比度不低于 4.5', () {
    double contrast(Color color) => 1.05 / (color.computeLuminance() + 0.05);

    for (final preset in AppThemePreset.values) {
      for (final brightness in Brightness.values) {
        final scheme = AppTheme.forPreset(preset, brightness).colorScheme;
        var previous = double.infinity;
        for (final level in [1, 2, 4, 8, 16, 64, 512, 4096]) {
          final color = squareJarBlockColor(
            primary: scheme.primary,
            level: level,
            maxLevel: 4096,
          );
          expect(
            contrast(color),
            greaterThanOrEqualTo(4.5),
            reason: '${preset.id} $brightness $level',
          );
          expect(
            color.computeLuminance(),
            lessThanOrEqualTo(previous + 0.0001),
            reason: '等级越高应越深：${preset.id} $brightness $level',
          );
          previous = color.computeLuminance();
        }
      }
    }
  });
}
