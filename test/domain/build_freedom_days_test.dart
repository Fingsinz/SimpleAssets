import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/freedom_days.dart';
import 'package:simple_assets/domain/usecases/build_freedom_days.dart';

FreedomDaysSnapshot _build({
  String asset = '486048',
  String? minimum = '2400',
  String? current = '6000',
  String? ideal = '12000',
  double? rate,
}) {
  return BuildFreedomDays.build(
    asset: Decimal.parse(asset),
    usesNetAssets: true,
    minimumMonthlyCost: minimum == null ? null : Decimal.parse(minimum),
    currentMonthlyCost: current == null ? null : Decimal.parse(current),
    idealMonthlyCost: ideal == null ? null : Decimal.parse(ideal),
    annualizedRate: rate,
  );
}

void main() {
  group('BuildFreedomDays', () {
    test('三项月成本换算成天数并向下取整', () {
      final snapshot = _build();

      expect(snapshot.entries.map((entry) => entry.days), [6159, 2463, 1231]);
      expect(snapshot.entries[0].years, closeTo(16.87, 0.01));
      expect(snapshot.entries[1].years, closeTo(6.75, 0.01));
      expect(snapshot.entries[2].years, closeTo(3.37, 0.01));
      expect(snapshot.coverageState, FreedomCoverageState.noAnnualizedRate);
    });

    test('正年化计算理论月被动收入与当前生活覆盖率', () {
      final snapshot = _build(rate: 8.5);

      expect(snapshot.coverageState, FreedomCoverageState.available);
      expect(
        snapshot.monthlyPassiveIncome,
        Decimal.parse('3442.84'),
      );
      expect(snapshot.entries[1].coverage, closeTo(57.38, 0.01));
      expect(snapshot.entries[0].coverage, isNull);
      expect(snapshot.entries[2].coverage, isNull);
    });

    test('年化为负时不估算覆盖率', () {
      final snapshot = _build(rate: -3.2);

      expect(
        snapshot.coverageState,
        FreedomCoverageState.negativeAnnualizedRate,
      );
      expect(snapshot.monthlyPassiveIncome, isNull);
      expect(snapshot.entries[1].coverage, isNull);
    });

    test('当前生活成本未设置时不估算覆盖率', () {
      final snapshot = _build(current: null, rate: 8.5);

      expect(
        snapshot.coverageState,
        FreedomCoverageState.noCurrentCost,
      );
      expect(snapshot.entries[1].days, isNull);
      expect(snapshot.entries[1].coverage, isNull);
    });

    test('零或负资产时天数为空', () {
      for (final asset in ['0', '-3200']) {
        final snapshot = _build(asset: asset, rate: 8.5);
        expect(snapshot.asset, Decimal.zero);
        expect(snapshot.entries.every((entry) => entry.days == null), isTrue);
        expect(snapshot.coverageState, FreedomCoverageState.noAssets);
      }
    });

    test('负成本按未设置处理', () {
      final snapshot = _build(minimum: '-100');
      expect(snapshot.entries[0].days, isNull);
    });
  });
}
