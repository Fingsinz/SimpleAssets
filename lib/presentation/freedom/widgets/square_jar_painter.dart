import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'square_jar_layout.dart';

/// 方块颜色：等级越高越深，但始终能承载白字。
Color squareJarBlockColor({
  required Color primary,
  required int level,
  required int maxLevel,
}) {
  final base = AppColors.whiteLegibleInk(primary);
  if (maxLevel <= 1) return base;

  final safeLevel = level <= 0 ? 1 : level;
  final maxLog = math.log(maxLevel) / math.log(2);
  final t = ((math.log(safeLevel) / math.log(2)) / maxLog).clamp(0.0, 1.0);
  return Color.lerp(base, Colors.black, 0.32 * t)!;
}

/// 画方寸块与块内等级数字。
class SquareJarPainter extends CustomPainter {
  final SquareJarLayout layout;
  final Color primary;
  final double radius;

  const SquareJarPainter({
    required this.layout,
    required this.primary,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.tiles.isEmpty) return;
    final maxLevel = layout.tiles.first.block.level;

    for (final tile in layout.tiles) {
      final color = squareJarBlockColor(
        primary: primary,
        level: tile.block.level,
        maxLevel: maxLevel,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile.rect, Radius.circular(radius)),
        Paint()..color = color,
      );

      final side = tile.rect.shortestSide;
      if (side < 22) continue;
      final fontSize = side >= 44 ? 15.0 : 11.0;
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${tile.block.level}',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: side - 4);
      if (textPainter.width > side - 4 || textPainter.height > side - 4) {
        continue;
      }
      textPainter.paint(
        canvas,
        tile.rect.center -
            Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SquareJarPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.primary != primary ||
      oldDelegate.radius != radius;
}
