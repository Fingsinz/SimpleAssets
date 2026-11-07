import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/entities/square_inch_jar.dart';

/// 画布上的一个方寸块。
class SquareJarTile {
  final SquareInchBlock block;
  final Rect rect;

  const SquareJarTile({required this.block, required this.rect});
}

/// 方寸罐的二维货架布局。
///
/// 每个块是正方形，面积与等级成正比；等级越高块越大。
class SquareJarLayout {
  final List<SquareJarTile> tiles;
  final double scale;
  final double height;

  const SquareJarLayout({
    required this.tiles,
    required this.scale,
    required this.height,
  });

  static const SquareJarLayout empty = SquareJarLayout(
    tiles: [],
    scale: 0,
    height: 0,
  );

  static SquareJarLayout pack({
    required List<SquareInchBlock> blocks,
    required double width,
    required double height,
    double gap = 3,
  }) {
    if (width <= 0 || height <= 0) return empty;

    final sorted = [
      for (final block in blocks)
        if (block.level > 0) block,
    ]..sort((a, b) => b.level.compareTo(a.level));
    if (sorted.isEmpty) return empty;

    final maxLevel = sorted.first.level;
    final upper = math.min(width, height) / math.sqrt(maxLevel);
    var low = 0.0;
    var high = upper;

    for (var i = 0; i < 40; i++) {
      final mid = (low + high) / 2;
      if (_packAt(sorted, width, height, mid, gap).height <= height) {
        low = mid;
      } else {
        high = mid;
      }
    }

    final packed = _packAt(sorted, width, height, low, gap);
    final offset = height - packed.height;
    final tiles = offset <= 0
        ? packed.tiles
        : [
            for (final tile in packed.tiles)
              SquareJarTile(
                block: tile.block,
                rect: tile.rect.translate(0, offset),
              ),
          ];

    return SquareJarLayout(tiles: tiles, scale: low, height: height);
  }

  static _Packed _packAt(
    List<SquareInchBlock> blocks,
    double width,
    double height,
    double scale,
    double gap,
  ) {
    final tiles = <SquareJarTile>[];
    var x = 0.0;
    var y = 0.0;
    var shelfHeight = 0.0;

    for (final block in blocks) {
      final side = math.sqrt(block.level) * scale;
      if (x > 0 && x + side > width) {
        y += shelfHeight + gap;
        x = 0;
        shelfHeight = 0;
      }
      tiles.add(
        SquareJarTile(block: block, rect: Rect.fromLTWH(x, y, side, side)),
      );
      x += side + gap;
      shelfHeight = math.max(shelfHeight, side);
    }

    return _Packed(tiles: tiles, height: y + shelfHeight);
  }
}

class _Packed {
  final List<SquareJarTile> tiles;
  final double height;

  const _Packed({required this.tiles, required this.height});
}
