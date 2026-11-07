import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/usecases/build_square_inch_jar.dart';

void main() {
  group('BuildSquareInchJar', () {
    test('4860 个基础方寸按二进制拆成 8 个块', () {
      final jar = BuildSquareInchJar.build(
        asset: Decimal.parse('486048'),
        unitValue: Decimal.fromInt(100),
      );

      expect(jar.baseCount, 4860);
      expect(jar.fraction, Decimal.parse('0.48'));
      expect(jar.blocks.map((block) => block.level), [
        4096,
        512,
        128,
        64,
        32,
        16,
        8,
        4,
      ]);
      expect(jar.blocks.first.value, Decimal.parse('409600'));
      expect(jar.missingToNext, Decimal.parse('52'));
    });

    test('整方寸没有零头', () {
      final jar = BuildSquareInchJar.build(
        asset: Decimal.fromInt(12300),
        unitValue: Decimal.fromInt(100),
      );

      expect(jar.baseCount, 123);
      expect(jar.fraction, Decimal.zero);
      expect(jar.blocks.map((block) => block.level), [64, 32, 16, 8, 2, 1]);
      expect(jar.missingToNext, Decimal.fromInt(100));
    });

    test('资产不足一个方寸时块为空、零头是比例', () {
      final jar = BuildSquareInchJar.build(
        asset: Decimal.fromInt(45),
        unitValue: Decimal.fromInt(100),
      );

      expect(jar.baseCount, 0);
      expect(jar.blocks, isEmpty);
      expect(jar.fraction, Decimal.parse('0.45'));
      expect(jar.missingToNext, Decimal.fromInt(55));
    });

    test('零或负资产按空罐处理', () {
      for (final raw in ['0', '-3200']) {
        final jar = BuildSquareInchJar.build(
          asset: Decimal.parse(raw),
          unitValue: Decimal.fromInt(100),
        );
        expect(jar.asset, Decimal.zero);
        expect(jar.baseCount, 0);
        expect(jar.blocks, isEmpty);
        expect(jar.fraction, Decimal.zero);
        expect(jar.missingToNext, Decimal.fromInt(100));
      }
    });

    test('单位含 3 的零头不会因非终止小数崩溃', () {
      for (final unit in [3, 300, 1200]) {
        final jar = BuildSquareInchJar.build(
          asset: Decimal.fromInt(1000),
          unitValue: Decimal.fromInt(unit),
        );
        final expectedFraction = switch (unit) {
          3 => 1 / 3,
          300 => 1 / 3,
          _ => 5 / 6,
        };
        expect(
          jar.fraction.toDouble(),
          closeTo(expectedFraction, 0.001),
          reason: 'unit=$unit',
        );
      }
    });

    test('极大资产不会溢出，块数不超过 63', () {
      final jar = BuildSquareInchJar.build(
        asset: Decimal.parse('1000000000000'),
        unitValue: Decimal.one,
      );

      expect(jar.baseCount, 1000000000000);
      expect(jar.blocks.length, lessThanOrEqualTo(63));
      expect(jar.blocks.first.level, 549755813888);
    });
  });
}
