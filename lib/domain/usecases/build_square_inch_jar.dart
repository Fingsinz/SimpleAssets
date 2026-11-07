import 'package:decimal/decimal.dart';

import '../entities/square_inch_jar.dart';

/// 把资产折算成方寸罐（纯函数）。
class BuildSquareInchJar {
  const BuildSquareInchJar();

  SquareInchJar call({required Decimal asset, required Decimal unitValue}) =>
      build(asset: asset, unitValue: unitValue);

  static SquareInchJar build({
    required Decimal asset,
    required Decimal unitValue,
  }) {
    final effectiveAsset = asset > Decimal.zero ? asset : Decimal.zero;
    final effectiveUnit = unitValue > Decimal.zero ? unitValue : Decimal.one;

    final baseCount = (effectiveAsset ~/ effectiveUnit).toInt();
    final remainder = effectiveAsset.remainder(effectiveUnit);
    final fraction = (remainder / effectiveUnit).toDecimal(
      scaleOnInfinitePrecision: 20,
    );

    final blocks = <SquareInchBlock>[];
    var level = 1;
    var remaining = baseCount;
    while (remaining > 0) {
      if (remaining & 1 == 1) {
        blocks.add(
          SquareInchBlock(
            level: level,
            value: effectiveUnit * Decimal.fromInt(level),
          ),
        );
      }
      remaining >>= 1;
      level <<= 1;
    }

    return SquareInchJar(
      asset: effectiveAsset,
      unitValue: effectiveUnit,
      baseCount: baseCount,
      fraction: fraction,
      blocks: blocks.reversed.toList(growable: false),
    );
  }
}
