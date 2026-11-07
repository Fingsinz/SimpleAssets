import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_assets/core/constants.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/domain/entities/freedom_days.dart';
import 'package:simple_assets/presentation/common/amount_visibility.dart';
import 'package:simple_assets/presentation/freedom/freedom_page.dart';
import 'package:simple_assets/presentation/providers/database_provider.dart';
import 'package:simple_assets/presentation/providers/freedom_providers.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';

Future<AppDatabase> _seedCash(String amount) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final repository = AssetRepositoryImpl(database);
  await repository.addHolding(
    AssetHoldingDraft(
      categoryId: 'cash',
      name: '现金',
      amount: Decimal.parse(amount),
      quantity: Decimal.zero,
      costPrice: Decimal.zero,
      purchaseDate: DateTime(2025, 1, 1),
    ),
  );
  return database;
}

Future<AppDatabase> _seedCashAndLiability() async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final repository = AssetRepositoryImpl(database);
  await repository.addHolding(
    AssetHoldingDraft(
      categoryId: 'cash',
      name: '现金',
      amount: Decimal.fromInt(5000),
      quantity: Decimal.zero,
      costPrice: Decimal.zero,
      purchaseDate: DateTime(2025, 1, 1),
    ),
  );
  await repository.addHolding(
    AssetHoldingDraft(
      categoryId: 'liability',
      name: '信用卡',
      amount: Decimal.parse('-3000'),
      quantity: Decimal.zero,
      costPrice: Decimal.zero,
      purchaseDate: DateTime(2025, 1, 1),
    ),
  );
  return database;
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Widget _wrap(AppDatabase database) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(database)],
  child: MaterialApp(theme: AppTheme.light, home: const FreedomPage()),
);

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('自由页渲染方寸罐、块与进度', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefFreedomUnitValue: '100',
      AppConstants.prefFreedomAssetBasis: 'net',
    });
    _phoneSize(tester);
    final database = await tester.runAsync(() => _seedCash('486048'));
    addTearDown(database!.close);

    await tester.pumpWidget(_wrap(database));
    await _pumpUntil(tester, find.text('方寸罐'));

    expect(find.text('方寸罐'), findsOneWidget);
    expect(find.textContaining('4,860 方寸'), findsOneWidget);
    expect(find.byKey(const Key('freedom-jar-canvas')), findsOneWidget);
    expect(find.textContaining('还差 ¥52.00'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('切换总资产 / 净资产会重算方寸数', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneSize(tester);
    final database = await tester.runAsync(_seedCashAndLiability);
    addTearDown(database!.close);

    await tester.pumpWidget(_wrap(database));
    await _pumpUntil(tester, find.text('方寸罐'));
    expect(find.textContaining('共 20 方寸'), findsOneWidget);

    await tester.tap(find.byKey(const Key('freedom-basis-total')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('共 50 方寸'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('修改每方寸价值后重算并持久化', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneSize(tester);
    final database = await tester.runAsync(() => _seedCash('486048'));
    addTearDown(database!.close);

    await tester.pumpWidget(_wrap(database));
    await _pumpUntil(tester, find.text('方寸罐'));

    await tester.tap(find.byKey(const Key('freedom-unit-value')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('freedom-unit-input')), '500');
    await tester.tap(find.byKey(const Key('freedom-unit-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('共 972 方寸'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.prefFreedomUnitValue), '500');

    await _disposeTree(tester);
  });

  testWidgets('每方寸价值拒绝 0', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneSize(tester);
    final database = await tester.runAsync(() => _seedCash('486048'));
    addTearDown(database!.close);

    await tester.pumpWidget(_wrap(database));
    await _pumpUntil(tester, find.text('方寸罐'));

    await tester.tap(find.byKey(const Key('freedom-unit-value')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('freedom-unit-input')), '0');
    await tester.tap(find.byKey(const Key('freedom-unit-save')));
    await tester.pumpAndSettle();

    expect(find.text('请输入大于 0 的金额'), findsOneWidget);
    expect(find.byKey(const Key('freedom-unit-save')), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('零资产显示空罐文案', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneSize(tester);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(_wrap(database));
    await _pumpUntil(tester, find.text('罐里还没有方寸，添加资产后自动垒起'));

    expect(find.text('罐里还没有方寸，添加资产后自动垒起'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('隐藏金额后方寸数仍可见', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneSize(tester);
    final database = await tester.runAsync(() => _seedCash('486048'));
    addTearDown(database!.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: AmountVisibility(
          hidden: true,
          child: MaterialApp(theme: AppTheme.light, home: const FreedomPage()),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('方寸罐'));

    expect(find.textContaining(AmountVisibility.mask), findsWidgets);
    expect(find.textContaining('4,860 方寸'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('自由天数按三档月成本展示并向下取整', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefFreedomCostMin: '2400',
      AppConstants.prefFreedomCostCurrent: '6000',
      AppConstants.prefFreedomCostIdeal: '12000',
    });
    _phoneSize(tester);
    final database = await tester.runAsync(() => _seedCash('486048'));
    addTearDown(database!.close);

    await tester.pumpWidget(_wrap(database));
    await _pumpUntil(tester, find.text('自由天数'));

    expect(find.text('最低生存'), findsOneWidget);
    expect(find.text('当前生活'), findsOneWidget);
    expect(find.text('理想生活'), findsOneWidget);
    expect(find.text('6,159 天'), findsOneWidget);
    expect(find.text('2,463 天'), findsOneWidget);
    expect(find.text('1,231 天'), findsOneWidget);
    expect(find.text('年化待积累'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('编辑三项月成本后更新并持久化', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneSize(tester);
    final database = await tester.runAsync(() => _seedCash('486048'));
    addTearDown(database!.close);

    await tester.pumpWidget(_wrap(database));
    await _pumpUntil(tester, find.text('自由天数'));
    expect(find.text('未设置'), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('freedom-edit-costs')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('freedom-cost-min')), '3000');
    await tester.enterText(
      find.byKey(const Key('freedom-cost-current')),
      '7000',
    );
    await tester.enterText(
      find.byKey(const Key('freedom-cost-ideal')),
      '10000',
    );
    await tester.tap(find.byKey(const Key('freedom-cost-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('¥7,000.00'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.prefFreedomCostCurrent), '7000');

    await _disposeTree(tester);
  });

  testWidgets('隐藏金额后天数仍可见', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefFreedomCostCurrent: '6000',
    });
    _phoneSize(tester);
    final database = await tester.runAsync(() => _seedCash('486048'));
    addTearDown(database!.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: AmountVisibility(
          hidden: true,
          child: MaterialApp(theme: AppTheme.light, home: const FreedomPage()),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('2,463 天'));

    expect(find.textContaining(AmountVisibility.mask), findsWidgets);
    expect(find.text('2,463 天'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('成本输入拒绝 0 与负数', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneSize(tester);
    final database = await tester.runAsync(() => _seedCash('486048'));
    addTearDown(database!.close);

    await tester.pumpWidget(_wrap(database));
    await _pumpUntil(tester, find.text('自由天数'));

    await tester.tap(find.byKey(const Key('freedom-edit-costs')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('freedom-cost-current')), '0');
    await tester.tap(find.byKey(const Key('freedom-cost-save')));
    await tester.pumpAndSettle();

    expect(find.text('请输入大于 0 的金额'), findsOneWidget);
    expect(find.byKey(const Key('freedom-cost-save')), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('有年化率时显示被动覆盖率与说明', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _phoneSize(tester);
    final database = await tester.runAsync(() => _seedCash('486048'));
    addTearDown(database!.close);

    final snapshot = FreedomDaysSnapshot(
      asset: Decimal.parse('486048'),
      usesNetAssets: true,
      entries: const [
        FreedomDayEntry(
          kind: FreedomCostKind.minimum,
          monthlyCost: null,
          days: 6159,
          years: 16.87,
        ),
        FreedomDayEntry(
          kind: FreedomCostKind.current,
          monthlyCost: null,
          days: 2463,
          years: 6.75,
          coverage: 57.38,
        ),
        FreedomDayEntry(
          kind: FreedomCostKind.ideal,
          monthlyCost: null,
          days: 1231,
          years: 3.37,
        ),
      ],
      annualizedRate: 8.5,
      monthlyPassiveIncome: Decimal.parse('3442.84'),
      coverageState: FreedomCoverageState.available,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          freedomDaysProvider.overrideWithValue(snapshot),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const FreedomPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('被动覆盖 57%'), findsOneWidget);
    expect(find.textContaining('理论被动收入 ¥3,442.84/月'), findsOneWidget);

    await _disposeTree(tester);
  });
}
