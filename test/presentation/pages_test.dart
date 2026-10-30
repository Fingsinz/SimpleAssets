import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/entities/asset_transaction_draft.dart';
import 'package:simple_assets/presentation/analysis/analysis_page.dart';
import 'package:simple_assets/presentation/holding/add_holding_page.dart';
import 'package:simple_assets/presentation/holding/holding_detail_page.dart';
import 'package:simple_assets/presentation/holding/holding_list_page.dart';
import 'package:simple_assets/presentation/overview/overview_page.dart';
import 'package:simple_assets/presentation/overview/widgets/summary_header.dart';
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
    expect(find.text('总市值'), findsOneWidget);
    expect(find.text('总投入'), findsOneWidget);
    expect(find.text('累计收益'), findsOneWidget);
    expect(find.byKey(const Key('overview-include-cash')), findsOneWidget);
    expect(find.text('资产配置'), findsOneWidget);
    expect(find.text('持仓明细'), findsOneWidget);
    expect(find.text('测试基金'), findsOneWidget);
    expect(find.text('测试股票'), findsOneWidget);
    expect(find.text('¥1,650.00'), findsWidgets);
    // 卡片只保留品类与代码，持有数量 / 成本 / 现价不再展示。
    expect(find.text('基金 · 000001'), findsOneWidget);
    expect(find.text('股票 · 600519'), findsOneWidget);
    expect(find.textContaining('持有 '), findsNothing);
    expect(find.textContaining('成本 ¥'), findsNothing);
    expect(find.textContaining('现价 ¥'), findsNothing);
    // 含现金开关移出头部，头部只保留印刷分隔线。
    expect(
      find.descendant(
        of: find.byType(SummaryHeader),
        matching: find.byKey(const Key('overview-include-cash')),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('summary-hero-rule')), findsOneWidget);
    // 资产配置图例改为两列网格。
    expect(find.byKey(const Key('allocation-legend-grid')), findsOneWidget);
    // 价格来源说明已迁入设置页的技术说明。
    expect(find.textContaining('价格来源'), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('总览持仓明细可在金额与品类排序间切换', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
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

    // 默认金额降序：基金市值 1200 > 股票 450。
    expect(
      tester.getTopLeft(find.text('测试基金')).dy,
      lessThan(tester.getTopLeft(find.text('测试股票')).dy),
    );

    await tester.tap(find.byKey(const Key('holdings-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sort-category')));
    await tester.pumpAndSettle();

    // 品类排序：股票排在基金之前，与市值无关。
    expect(
      tester.getTopLeft(find.text('测试股票')).dy,
      lessThan(tester.getTopLeft(find.text('测试基金')).dy),
    );

    await tester.tap(find.byKey(const Key('holdings-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sort-amount')));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('测试基金')).dy,
      lessThan(tester.getTopLeft(find.text('测试股票')).dy),
    );

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

    await tester.scrollUntilVisible(
      find.text('编辑持仓'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
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
    expect(find.byKey(const Key('analysis-include-cash')), findsOneWidget);
    // 分析页以记录以来 TWR 作为自己的锚点，并用刻度条表达现价覆盖。
    expect(find.text('记录以来 TWR'), findsOneWidget);
    expect(find.byKey(const Key('analysis-coverage-ticks')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('品类表现'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('品类表现'), findsOneWidget);
    // 品类表现条改为编码收益率。
    expect(find.byKey(const Key('category-return-bar-fund')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('持仓收益排行'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('持仓收益排行'), findsOneWidget);
    expect(find.text('测试基金'), findsWidgets);
    expect(find.text('测试股票'), findsWidgets);

    await _disposeTree(tester);
  });

  testWidgets('总览含现金开关切换统计口径', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AssetRepositoryImpl(database);
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '测试基金',
        quantity: Decimal.parse('100'),
        costPrice: Decimal.parse('10'),
        currentPrice: Decimal.parse('12'),
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '现金',
        amount: Decimal.parse('5000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );

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

    expect(find.text('¥1,200.00'), findsWidgets);
    expect(find.text('¥6,200.00'), findsNothing);

    await tester.tap(find.byKey(const Key('overview-include-cash')));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('¥6,200.00').evaluate().isNotEmpty) break;
    }
    expect(find.text('¥6,200.00'), findsWidgets);

    await _disposeTree(tester);
  });

  testWidgets('持仓页显示已清仓筛选与标记', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AssetRepositoryImpl(database);
    final id = await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '已清仓基金',
        quantity: Decimal.parse('100'),
        costPrice: Decimal.parse('10'),
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    await repository.addTransaction(
      AssetTransactionDraft(
        holdingId: id,
        type: TransactionType.sell,
        quantity: Decimal.parse('100'),
        price: Decimal.parse('12'),
        date: DateTime(2025, 2, 1),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HoldingListPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('已清仓基金'));

    expect(find.textContaining('已清仓'), findsWidgets);
    expect(find.text('已清仓 1'), findsOneWidget);

    await tester.tap(find.text('已清仓 1'));
    await tester.pump();
    expect(find.text('已清仓基金'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('分析页现价覆盖率排除已清仓', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AssetRepositoryImpl(database);
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '开放基金',
        code: '000001',
        quantity: Decimal.parse('100'),
        costPrice: Decimal.parse('10'),
        currentPrice: Decimal.parse('12'),
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    final closedId = await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '已清仓基金',
        code: '000002',
        quantity: Decimal.parse('100'),
        costPrice: Decimal.parse('10'),
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    await repository.addTransaction(
      AssetTransactionDraft(
        holdingId: closedId,
        type: TransactionType.sell,
        quantity: Decimal.parse('100'),
        price: Decimal.parse('12'),
        date: DateTime(2025, 2, 1),
      ),
    );

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

    expect(find.text('现价覆盖 1/1'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('新增持仓表单默认展示现金字段', (tester) async {
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
    await _pumpUntil(tester, find.text('添加现金'));

    expect(find.text('新增现金'), findsOneWidget);
    expect(find.text('品类'), findsOneWidget);
    expect(find.byKey(const Key('holding-amount')), findsOneWidget);
    expect(find.byKey(const Key('holding-record-date')), findsOneWidget);
    expect(find.byKey(const Key('holding-quantity')), findsNothing);
    expect(find.byKey(const Key('holding-cost-price')), findsNothing);
    expect(find.byKey(const Key('holding-code')), findsNothing);
    expect(find.text('添加现金'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('切换品类到基金展示通用字段', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
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
    await _pumpUntil(tester, find.text('添加现金'));

    await tester.tap(find.byKey(const Key('holding-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('基金').last);
    await tester.pumpAndSettle();

    expect(find.text('新增持仓'), findsOneWidget);
    expect(find.byKey(const Key('holding-quantity')), findsOneWidget);
    expect(find.byKey(const Key('holding-cost-price')), findsOneWidget);
    expect(find.byKey(const Key('holding-fee')), findsOneWidget);
    expect(find.byKey(const Key('holding-purchase-date')), findsOneWidget);
    expect(find.byKey(const Key('holding-code')), findsOneWidget);
    expect(find.byKey(const Key('holding-amount')), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('切换品类到贵金属展示单位字段', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
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
    await _pumpUntil(tester, find.text('添加现金'));

    await tester.tap(find.byKey(const Key('holding-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('贵金属').last);
    await tester.pumpAndSettle();

    expect(find.text('新增贵金属'), findsOneWidget);
    expect(find.byKey(const Key('holding-unit')), findsOneWidget);
    expect(find.byKey(const Key('holding-quantity')), findsOneWidget);
    expect(find.text('黄金'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('贵金属数量必填、单位可自由填写', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
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
    await _pumpUntil(tester, find.text('添加现金'));

    await tester.tap(find.byKey(const Key('holding-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('贵金属').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('holding-name')), '黄金');
    await tester.enterText(find.byKey(const Key('holding-unit')), '克');
    await tester.enterText(find.byKey(const Key('holding-cost-price')), '600');
    await tester.ensureVisible(find.byKey(const Key('holding-submit')));
    await tester.tap(find.byKey(const Key('holding-submit')));
    await tester.pumpAndSettle();

    expect(find.text('请输入有效的数量'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('新增基金时手续费计入首笔买入', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
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
    await _pumpUntil(tester, find.text('添加现金'));

    await tester.tap(find.byKey(const Key('holding-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('基金').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('holding-name')), '测试基金');
    await tester.enterText(find.byKey(const Key('holding-quantity')), '100');
    await tester.enterText(find.byKey(const Key('holding-cost-price')), '10');
    await tester.enterText(find.byKey(const Key('holding-fee')), '2');
    await tester.ensureVisible(find.byKey(const Key('holding-submit')));
    await tester.tap(find.byKey(const Key('holding-submit')));

    List<AssetHolding>? holdings;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      holdings = await tester.runAsync(
        () => AssetRepositoryImpl(database).getHoldings(),
      );
      if (holdings != null && holdings.isNotEmpty) break;
    }

    expect(holdings, isNotNull);
    expect(holdings!.single.totalBuy, Decimal.parse('1002'));
    expect(holdings.single.costPrice, Decimal.parse('10.02'));

    await _disposeTree(tester);
  });

  testWidgets('编辑非现金持仓显示只读派生信息', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final id = await tester.runAsync(
      () => AssetRepositoryImpl(database).addHolding(
        AssetHoldingDraft(
          categoryId: 'fund',
          name: '测试基金',
          quantity: Decimal.parse('100'),
          costPrice: Decimal.parse('10'),
          purchaseDate: DateTime(2025, 1, 1),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: AddHoldingPage(holdingId: id),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('编辑持仓'));

    expect(find.byKey(const Key('holding-quantity')), findsNothing);
    expect(find.byKey(const Key('holding-cost-price')), findsNothing);
    expect(find.byKey(const Key('holding-purchase-date')), findsNothing);
    expect(find.textContaining('由交易流水自动计算'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('编辑现金持仓隐藏金额与记录日期', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AssetRepositoryImpl(database);
    final id = await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '招商银行',
        amount: Decimal.parse('5000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: AddHoldingPage(holdingId: id),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('编辑现金平台'));

    expect(find.byKey(const Key('holding-name')), findsOneWidget);
    expect(find.byKey(const Key('holding-amount')), findsNothing);
    expect(find.byKey(const Key('holding-record-date')), findsNothing);
    expect(
      find.text('金额与记录日期请在详情页的记录历史中管理'),
      findsOneWidget,
    );

    await _disposeTree(tester);
  });

  testWidgets('现金详情展示当前金额与记录历史', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AssetRepositoryImpl(database);
    final id = await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '招商银行',
        amount: Decimal.parse('50000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2026, 9, 1),
      ),
    );
    await repository.addCashRecord(
      id,
      Decimal.parse('60000'),
      DateTime(2026, 10, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: HoldingDetailPage(holdingId: id),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('记录历史'));

    expect(find.text('当前金额'), findsOneWidget);
    expect(find.text('记录历史'), findsOneWidget);
    expect(find.text('记一笔'), findsOneWidget);
    expect(find.text('¥60,000.00'), findsWidgets);
    expect(find.text('当前单价'), findsNothing);
    expect(find.text('持有数量'), findsNothing);
    expect(find.text('待更新现价'), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('贵金属详情同时展示数量与单位', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AssetRepositoryImpl(database);
    final id = await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'gold',
        name: '黄金',
        unit: '克',
        quantity: Decimal.parse('10'),
        costPrice: Decimal.parse('600'),
        currentPrice: Decimal.parse('700'),
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: HoldingDetailPage(holdingId: id),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('持有数量'));

    expect(find.text('持有数量'), findsOneWidget);
    expect(find.text('计量单位'), findsOneWidget);
    expect(find.text('克'), findsOneWidget);
    expect(find.text('代码'), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('现金平台名称重复时提示已存在', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AssetRepositoryImpl(database);
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '招商银行',
        amount: Decimal.parse('5000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AddHoldingPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('添加现金'));

    await tester.enterText(find.byKey(const Key('holding-name')), '招商银行');
    await tester.enterText(find.byKey(const Key('holding-amount')), '6000');
    await tester.ensureVisible(find.byKey(const Key('holding-submit')));
    await tester.tap(find.byKey(const Key('holding-submit')));
    await tester.pumpAndSettle();

    expect(find.text('该平台已存在'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('只有现金时总览不提示待更新现价', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AssetRepositoryImpl(database);
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '招商银行',
        amount: Decimal.parse('5000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2026, 10, 1),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OverviewPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('招商银行'));

    // 卡片副标题与资产配置图例都会出现「现金」。
    expect(find.text('现金'), findsWidgets);
    expect(find.textContaining('记录于'), findsNothing);
    expect(find.textContaining('尚未更新现价'), findsNothing);
    expect(find.textContaining('待更新现价'), findsNothing);
    expect(find.text('¥5,000.00'), findsWidgets);

    await _disposeTree(tester);
  });

  testWidgets('分析页现价覆盖率排除现金', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AssetRepositoryImpl(database);
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '招商银行',
        amount: Decimal.parse('5000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2026, 10, 1),
      ),
    );
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

    expect(find.text('现价覆盖 1/1'), findsOneWidget);
    expect(find.text('暂无可计算收益的资产'), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('只有现金时分析页显示暂无可计算收益的资产', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = AssetRepositoryImpl(database);
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '招商银行',
        amount: Decimal.parse('5000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2026, 10, 1),
      ),
    );

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

    expect(find.text('现价覆盖 0/0'), findsOneWidget);
    expect(find.text('暂无可计算收益的资产'), findsOneWidget);

    await _disposeTree(tester);
  });
}
