import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/presentation/analysis/analysis_page.dart';
import 'package:simple_assets/presentation/holding/add_holding_page.dart';
import 'package:simple_assets/presentation/holding/holding_detail_page.dart';
import 'package:simple_assets/presentation/holding/holding_list_page.dart';
import 'package:simple_assets/presentation/overview/overview_page.dart';
import 'package:simple_assets/presentation/providers/database_provider.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';

Future<AppDatabase> _seedDatabase() async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final repository = AssetRepositoryImpl(database);
  await repository.addHolding(
    AssetHoldingDraft(
      categoryId: 'fund',
      name: '测试基金',
      code: '000001',
      quantity: Decimal.parse('100'),
      costPrice: Decimal.parse('10'),
      currentPrice: Decimal.parse('12'),
      purchaseDate: DateTime(2025, 1, 1),
    ),
  );
  await repository.addHolding(
    AssetHoldingDraft(
      categoryId: 'stock',
      name: '测试股票',
      code: '600519',
      quantity: Decimal.parse('10'),
      costPrice: Decimal.parse('50'),
      currentPrice: Decimal.parse('45'),
      purchaseDate: DateTime(2025, 2, 1),
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

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('总览在手机尺寸下渲染汇总、饼图与持仓卡片', (tester) async {
    tester.view.physicalSize = const Size(400, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seedDatabase);
    addTearDown(database!.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OverviewPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('测试基金'));

    expect(find.text('总览'), findsOneWidget);
    expect(find.text('资产配置'), findsOneWidget);
    expect(find.text('持仓明细'), findsOneWidget);
    expect(find.text('测试基金'), findsOneWidget);
    expect(find.text('测试股票'), findsOneWidget);
    expect(find.text('¥1,650.00'), findsWidgets);

    await _disposeTree(tester);
  });

  testWidgets('持仓页展示品类筛选与两条持仓', (tester) async {

    tester.view.physicalSize = const Size(400, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seedDatabase);
    addTearDown(database!.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HoldingListPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('测试基金'));

    expect(find.text('持仓'), findsOneWidget);
    expect(find.text('全部 2'), findsOneWidget);
    expect(find.text('基金 1'), findsOneWidget);
    expect(find.text('股票 1'), findsOneWidget);
    expect(find.text('测试基金'), findsOneWidget);
    expect(find.text('测试股票'), findsOneWidget);
    expect(find.text('添加'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('持仓详情在手机尺寸下完整展示', (tester) async {
    tester.view.physicalSize = const Size(400, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seedDatabase);
    addTearDown(database!.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HoldingDetailPage(holdingId: 1),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('持仓信息'));

    expect(find.text('持仓详情'), findsOneWidget);
    expect(find.text('测试基金'), findsOneWidget);
    expect(find.text('当前市值'), findsOneWidget);
    expect(find.text('持仓信息'), findsOneWidget);
    expect(find.text('更新'), findsOneWidget);
    expect(find.text('编辑持仓'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('分析页在手机尺寸下展示收益概览与排行', (tester) async {
    tester.view.physicalSize = const Size(400, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seedDatabase);
    addTearDown(database!.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AnalysisPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('收益概览'));

    expect(find.text('分析'), findsOneWidget);
    expect(find.text('累计收益'), findsOneWidget);
    expect(find.text('品类表现'), findsOneWidget);
    expect(find.text('持仓收益排行'), findsOneWidget);
    expect(find.text('测试基金'), findsOneWidget);
    expect(find.text('测试股票'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('新增持仓表单在手机尺寸下渲染', (tester) async {
    tester.view.physicalSize = const Size(400, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AddHoldingPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('添加资产'));

    expect(find.text('新增持仓'), findsOneWidget);
    expect(find.text('品类'), findsOneWidget);
    expect(find.text('持有数量'), findsOneWidget);
    expect(find.text('成本单价'), findsOneWidget);
    expect(find.text('买入日期'), findsOneWidget);
    expect(find.text('添加资产'), findsOneWidget);

    await _disposeTree(tester);
  });
}
