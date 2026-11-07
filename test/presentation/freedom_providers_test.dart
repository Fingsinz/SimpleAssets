import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_assets/core/constants.dart';
import 'package:simple_assets/presentation/providers/freedom_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('默认净资产口径与每方寸 ¥100，三项成本为空', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final config = await container.read(freedomConfigProvider.future);

    expect(config.assetBasis, FreedomAssetBasis.net);
    expect(config.unitValue, Decimal.fromInt(100));
    expect(config.minimumMonthlyCost, isNull);
    expect(config.currentMonthlyCost, isNull);
    expect(config.idealMonthlyCost, isNull);
  });

  test('偏好中的 0 / 负数按默认值或未设置处理', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefFreedomUnitValue: '0',
      AppConstants.prefFreedomCostMin: '-100',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final config = await container.read(freedomConfigProvider.future);

    expect(config.unitValue, Decimal.fromInt(100));
    expect(config.minimumMonthlyCost, isNull);
  });

  test('修改口径、单位与三项成本会更新状态并落盘', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(freedomConfigProvider.future);

    final notifier = container.read(freedomConfigProvider.notifier);
    await notifier.setAssetBasis(FreedomAssetBasis.total);
    await notifier.setUnitValue(Decimal.fromInt(500));
    await notifier.setCosts(
      minimum: Decimal.fromInt(3000),
      current: null,
      ideal: Decimal.fromInt(10000),
    );

    final config = container.read(freedomConfigProvider).valueOrNull!;
    expect(config.assetBasis, FreedomAssetBasis.total);
    expect(config.unitValue, Decimal.fromInt(500));
    expect(config.minimumMonthlyCost, Decimal.fromInt(3000));
    expect(config.currentMonthlyCost, isNull);
    expect(config.idealMonthlyCost, Decimal.fromInt(10000));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.prefFreedomAssetBasis), 'total');
    expect(prefs.getString(AppConstants.prefFreedomUnitValue), '500');
    expect(prefs.getString(AppConstants.prefFreedomCostMin), '3000');
    expect(prefs.getString(AppConstants.prefFreedomCostCurrent), isNull);
    expect(prefs.getString(AppConstants.prefFreedomCostIdeal), '10000');
  });
}
