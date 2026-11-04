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
import 'package:simple_assets/domain/entities/balance_record.dart';
import 'package:simple_assets/presentation/analysis/analysis_page.dart';
import 'package:simple_assets/presentation/common/category_mark.dart';
import 'package:simple_assets/presentation/common/ledger_sheet.dart';
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

Future<void> _pumpUntilButtonEnabled(
  WidgetTester tester,
  String label,
) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    final finder = find.ancestor(
      of: find.text(label),
      matching: find.byType(TextButton),
    );
    if (finder.evaluate().isEmpty) continue;
    final button = tester.widget<TextButton>(finder.first);
    if (button.onPressed != null) return;
  }
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('总览渲染总资产、配置图且无持仓明细', (tester) async {
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
    await _pumpUntil(tester, find.text('资产配置'));

    expect(find.text('总览'), findsOneWidget);
    expect(find.text('我有多少资产'), findsOneWidget);
    expect(find.text('总资产'), findsOneWidget);
    expect(find.text('总市值'), findsNothing);
    expect(find.text('总投入'), findsOneWidget);
    expect(find.text('累计收益'), findsOneWidget);
    expect(find.byKey(const Key('overview-include-cash')), findsNothing);
    expect(find.text('资产配置'), findsOneWidget);
    expect(find.text('持仓明细'), findsNothing);
    expect(find.byKey(const Key('holdings-sort')), findsNothing);
    expect(find.text('测试基金'), findsNothing);
    expect(find.text('测试股票'), findsNothing);
    expect(find.text('¥1,650.00'), findsWidgets);
    expect(find.byKey(const Key('summary-hero-rule')), findsOneWidget);
    expect(find.byType(LedgerSheet), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Card).first)).cardTheme.color,
      Colors.transparent,
    );
    expect(find.byKey(const Key('allocation-legend-grid')), findsOneWidget);
    expect(find.textContaining('价格来源'), findsNothing);

    await tester.tap(find.byKey(const Key('summary-profit-info')));
    await tester.pumpAndSettle();
    expect(find.text('累计收益口径'), findsOneWidget);
    expect(find.textContaining('只统计理财产品'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('summary-return-info')));
    await tester.pumpAndSettle();
    expect(find.text('收益率口径'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await _disposeTree(tester);
  });

  testWidgets('总资产不含负债，块内可切换净资产', (tester) async {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OverviewPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('资产配置'));

    final hero = find.byType(SummaryHeader);
    // 总资产 = 基金 1200 + 现金 5000，不含负债。
    expect(
      find.descendant(of: hero, matching: find.text('¥6,200.00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hero, matching: find.text('¥3,200.00')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('summary-net-assets')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: hero, matching: find.text('¥3,200.00')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('summary-total-assets')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: hero, matching: find.text('¥6,200.00')),
      findsOneWidget,
    );

    await _disposeTree(tester);
  });

  testWidgets('资产配置图在负债时显示独立图例行', (tester) async {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OverviewPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('资产配置'));

    expect(find.text('负债'), findsOneWidget);
    expect(find.text('-¥3,000.00'), findsWidgets);
    // 正资产合计 6200：基金 19.4%，现金 80.6%；负债显示 —。
    expect(find.text('19.4%'), findsOneWidget);
    expect(find.text('80.6%'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('资产页展示品类筛选与两条资产', (tester) async {

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

    expect(find.text('资产'), findsOneWidget);
    expect(find.text('我有哪些资产'), findsOneWidget);
    expect(find.text('全部 2'), findsOneWidget);
    expect(find.text('基金 1'), findsOneWidget);
    expect(find.text('股票 1'), findsOneWidget);
    expect(find.text('测试基金'), findsOneWidget);
    expect(find.text('测试股票'), findsOneWidget);
    expect(find.byType(LedgerSheet), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Card).first)).cardTheme.color,
      Colors.transparent,
    );
    expect(find.byType(CategoryMark), findsNWidgets(2));

    await _disposeTree(tester);
  });

  testWidgets('资产页默认按金额降序并可切换品类排序', (tester) async {
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
        name: '银行卡',
        amount: Decimal.parse('5000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
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
        categoryId: 'stock',
        name: '测试股票',
        quantity: Decimal.parse('10'),
        costPrice: Decimal.parse('50'),
        currentPrice: Decimal.parse('45'),
        purchaseDate: DateTime(2025, 1, 1),
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
    await _pumpUntil(tester, find.text('银行卡'));

    // 默认金额降序：5000 > 1200 > 450。
    expect(
      tester.getTopLeft(find.text('银行卡')).dy,
      lessThan(tester.getTopLeft(find.text('测试基金')).dy),
    );
    expect(
      tester.getTopLeft(find.text('测试基金')).dy,
      lessThan(tester.getTopLeft(find.text('测试股票')).dy),
    );

    await tester.tap(find.byKey(const Key('holdings-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sort-category')));
    await tester.pumpAndSettle();

    // 品类顺序：股票 → 基金 → 现金。
    expect(
      tester.getTopLeft(find.text('测试股票')).dy,
      lessThan(tester.getTopLeft(find.text('测试基金')).dy),
    );
    expect(
      tester.getTopLeft(find.text('测试基金')).dy,
      lessThan(tester.getTopLeft(find.text('银行卡')).dy),
    );

    await tester.tap(find.byKey(const Key('holdings-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sort-amount')));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('银行卡')).dy,
      lessThan(tester.getTopLeft(find.text('测试基金')).dy),
    );

    await _disposeTree(tester);
  });

  testWidgets('持仓页品类筛选条与概览排序使用同一顺序', (tester) async {
    // 用宽屏让横向筛选条一次铺开，便于比较品类顺序。
    tester.view.physicalSize = const Size(900, 820);
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
        name: '现金',
        amount: Decimal.parse('5000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '测试基金',
        quantity: Decimal.parse('100'),
        costPrice: Decimal.parse('10'),
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'stock',
        name: '测试股票',
        quantity: Decimal.parse('10'),
        costPrice: Decimal.parse('50'),
        purchaseDate: DateTime(2025, 1, 1),
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
    await _pumpUntil(tester, find.text('测试基金'));

    // 股票 → 基金 → 现金，不再跟随数据库的 cash/bond/fund/stock 顺序。
    expect(
      tester.getTopLeft(find.text('股票 1')).dx,
      lessThan(tester.getTopLeft(find.text('基金 1')).dx),
    );
    expect(
      tester.getTopLeft(find.text('基金 1')).dx,
      lessThan(tester.getTopLeft(find.text('现金 1')).dx),
    );

    await _disposeTree(tester);
  });

  testWidgets('资产详情在手机尺寸下完整展示', (tester) async {
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

    expect(find.text('资产详情'), findsOneWidget);
    expect(find.text('测试基金'), findsOneWidget);
    expect(find.text('当前市值'), findsOneWidget);
    expect(find.text('持仓信息'), findsOneWidget);
    expect(find.text('更新'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('编辑资产'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('编辑资产'), findsOneWidget);

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
    expect(find.text('我有多少收益'), findsOneWidget);
    expect(find.text('累计收益'), findsOneWidget);
    expect(find.byKey(const Key('analysis-include-cash')), findsNothing);
    // 分析页以记录以来 TWR 作为自己的锚点，并用刻度条表达估值覆盖。
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

  testWidgets('总览总资产始终包含现金与负债', (tester) async {
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

    // 总资产默认包含现金，不再需要开关。
    expect(find.text('¥6,200.00'), findsWidgets);
    expect(find.byKey(const Key('overview-include-cash')), findsNothing);

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

  testWidgets('分析页估值覆盖率排除已清仓', (tester) async {
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

    expect(find.text('估值覆盖 1/1'), findsOneWidget);

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

    expect(find.text('新增资产'), findsOneWidget);
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
    await _pumpUntil(tester, find.text('编辑资产'));

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
    await repository.addBalanceRecord(
      id,
      BalanceRecordDraft(
        amount: Decimal.parse('60000'),
        recordDate: DateTime(2026, 10, 1),
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

    // 资产配置图例会显示「现金」，但不再有持仓卡片。
    expect(find.text('现金'), findsWidgets);
    expect(find.text('招商银行'), findsNothing);
    expect(find.textContaining('尚未更新现价'), findsNothing);
    expect(find.textContaining('待更新现价'), findsNothing);
    expect(find.text('¥5,000.00'), findsWidgets);

    await _disposeTree(tester);
  });

  testWidgets('分析页估值覆盖率排除现金', (tester) async {
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

    expect(find.text('估值覆盖 1/1'), findsOneWidget);
    expect(find.text('暂无可计算收益的资产'), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('切换品类到负债展示负数金额字段', (tester) async {
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
    await tester.tap(find.text('负债').last);
    await tester.pumpAndSettle();

    expect(find.text('新增负债'), findsOneWidget);
    expect(find.byKey(const Key('holding-amount')), findsOneWidget);
    expect(find.byKey(const Key('holding-record-date')), findsOneWidget);
    expect(find.byKey(const Key('holding-quantity')), findsNothing);
    expect(find.byKey(const Key('holding-cost-price')), findsNothing);
    expect(find.byKey(const Key('holding-code')), findsNothing);
    expect(find.text('-'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('负债金额为正时提示必须小于 0', (tester) async {
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
    await tester.tap(find.text('负债').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('holding-name')), '信用卡');
    await tester.enterText(find.byKey(const Key('holding-amount')), '3000');
    await tester.ensureVisible(find.byKey(const Key('holding-submit')));
    await tester.tap(find.byKey(const Key('holding-submit')));
    await tester.pumpAndSettle();

    expect(find.text('金额必须小于 0'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('切换品类到自定义产品展示买入金额与手续费', (tester) async {
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
    await tester.tap(find.text('自定义产品').last);
    await tester.pumpAndSettle();

    expect(find.text('新增自定义产品'), findsOneWidget);
    expect(find.byKey(const Key('holding-amount')), findsOneWidget);
    expect(find.byKey(const Key('holding-fee')), findsOneWidget);
    expect(find.byKey(const Key('holding-purchase-date')), findsOneWidget);
    expect(find.byKey(const Key('holding-quantity')), findsNothing);
    expect(find.byKey(const Key('holding-cost-price')), findsNothing);
    expect(find.byKey(const Key('holding-code')), findsNothing);
    expect(find.byKey(const Key('holding-current-price')), findsNothing);
    expect(find.byKey(const Key('holding-unit')), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('自定义产品买入金额为 0 时拒绝提交', (tester) async {
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
    await tester.tap(find.text('自定义产品').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('holding-name')), '某银行理财');
    await tester.enterText(find.byKey(const Key('holding-amount')), '0');
    await tester.ensureVisible(find.byKey(const Key('holding-submit')));
    await tester.tap(find.byKey(const Key('holding-submit')));
    await tester.pumpAndSettle();

    expect(find.text('买入金额必须大于 0'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('自定义产品创建后写入投入记录', (tester) async {
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
    await tester.tap(find.text('自定义产品').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('holding-name')), '某银行理财');
    await tester.enterText(find.byKey(const Key('holding-amount')), '5000');
    await tester.enterText(find.byKey(const Key('holding-fee')), '5');
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
    expect(holdings!.single.categoryId, 'custom');
    expect(holdings.single.totalBuy, Decimal.parse('5005'));
    expect(holdings.single.totalFees, Decimal.parse('5'));
    expect(holdings.single.amount, Decimal.parse('5000'));

    await _disposeTree(tester);
  });

  testWidgets('负债平台名称重复时提示已存在', (tester) async {
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
        categoryId: 'liability',
        name: '招商银行信用卡',
        amount: Decimal.parse('-3000'),
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

    await tester.tap(find.byKey(const Key('holding-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('负债').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('holding-name')),
      '招商银行信用卡',
    );
    await tester.enterText(find.byKey(const Key('holding-amount')), '-4000');
    await tester.ensureVisible(find.byKey(const Key('holding-submit')));
    await tester.tap(find.byKey(const Key('holding-submit')));
    await tester.pumpAndSettle();

    expect(find.text('该平台已存在'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('自定义产品名称重复时提示已存在', (tester) async {
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
        categoryId: 'custom',
        name: '产品A',
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

    await tester.tap(find.byKey(const Key('holding-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义产品').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('holding-name')), '产品A');
    await tester.enterText(find.byKey(const Key('holding-amount')), '3000');
    await tester.ensureVisible(find.byKey(const Key('holding-submit')));
    await tester.tap(find.byKey(const Key('holding-submit')));
    await tester.pumpAndSettle();

    expect(find.text('该产品已存在'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('编辑自定义产品只显示名称与备注', (tester) async {
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
        categoryId: 'custom',
        name: '产品A',
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
    await _pumpUntil(tester, find.text('编辑自定义产品'));

    expect(find.byKey(const Key('holding-name')), findsOneWidget);
    expect(find.byKey(const Key('holding-notes')), findsOneWidget);
    expect(find.byKey(const Key('holding-amount')), findsNothing);
    expect(find.byKey(const Key('holding-quantity')), findsNothing);
    expect(find.byKey(const Key('holding-cost-price')), findsNothing);
    expect(find.byKey(const Key('holding-code')), findsNothing);
    expect(find.byKey(const Key('holding-purchase-date')), findsNothing);
    expect(find.text('金额与记录请在详情页管理'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('已清仓筛选不包含自定义产品', (tester) async {
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
        categoryId: 'custom',
        name: '未清仓产品',
        amount: Decimal.parse('5000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    final closedId = await repository.addHolding(
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
          home: const HoldingListPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('已清仓基金'));

    expect(find.text('已清仓 1'), findsOneWidget);
    expect(find.text('全部 2'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('负债详情展示当前负债与负数记录', (tester) async {
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
        categoryId: 'liability',
        name: '招商银行信用卡',
        amount: Decimal.parse('-3000'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2026, 9, 1),
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
    await _pumpUntil(tester, find.text('当前负债'));

    expect(find.text('-¥3,000.00'), findsWidgets);
    expect(find.text('记录历史'), findsOneWidget);
    expect(find.text('记一笔'), findsOneWidget);
    expect(find.text('当前单价'), findsNothing);
    expect(find.text('持有数量'), findsNothing);
    expect(find.text('累计收益'), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('自定义产品详情展示持有金额与更新入口', (tester) async {
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
        categoryId: 'custom',
        name: '某银行理财',
        amount: Decimal.parse('5000'),
        fee: Decimal.parse('5'),
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
          home: HoldingDetailPage(holdingId: id),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('当前持有金额'));

    expect(find.text('累计投入'), findsOneWidget);
    expect(find.text('累计收益'), findsOneWidget);
    expect(find.text('当前单价'), findsNothing);
    expect(find.text('月末价格'), findsNothing);
    expect(find.text('持有数量'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('更新'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('更新'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('自定义产品更新为新投入后金额与收益变化', (tester) async {
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
        categoryId: 'custom',
        name: '某银行理财',
        amount: Decimal.parse('5000'),
        fee: Decimal.parse('5'),
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
          home: HoldingDetailPage(holdingId: id),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('当前持有金额'));

    await tester.scrollUntilVisible(
      find.text('更新'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await _pumpUntilButtonEnabled(tester, '更新');
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('custom-record-kind')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新投入').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('custom-flow-amount')),
      '1000',
    );
    await tester.enterText(
      find.byKey(const Key('custom-current-amount')),
      '6300',
    );
    await tester.tap(find.byKey(const Key('custom-record-submit')));
    await tester.pumpAndSettle();

    expect(find.text('¥6,300.00'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('¥295.00'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('¥295.00'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('自定义产品更新为卖出后收益变化', (tester) async {
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
        categoryId: 'custom',
        name: '某银行理财',
        amount: Decimal.parse('5000'),
        fee: Decimal.parse('5'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    await repository.addBalanceRecord(
      id,
      BalanceRecordDraft(
        amount: Decimal.parse('6300'),
        flowKind: BalanceFlowKind.invest,
        flowAmount: Decimal.parse('1000'),
        recordDate: DateTime(2025, 2, 1),
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
    await _pumpUntil(tester, find.text('当前持有金额'));

    await tester.scrollUntilVisible(
      find.text('更新'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await _pumpUntilButtonEnabled(tester, '更新');
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('custom-record-kind')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('卖出').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('custom-flow-amount')),
      '500',
    );
    await tester.enterText(
      find.byKey(const Key('custom-current-amount')),
      '5600',
    );
    await tester.tap(find.byKey(const Key('custom-record-submit')));
    await tester.pumpAndSettle();

    expect(find.text('¥5,600.00'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('¥95.00'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('¥95.00'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('编辑自定义产品首笔投入记录不丢手续费', (tester) async {
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
        categoryId: 'custom',
        name: '某银行理财',
        amount: Decimal.parse('5000'),
        fee: Decimal.parse('5'),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    final recordId = (await repository.getBalanceRecords(id)).single.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: HoldingDetailPage(holdingId: id),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('当前持有金额'));

    final recordFinder = find.byKey(ValueKey('balance-record-$recordId'));
    await tester.scrollUntilVisible(
      recordFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(recordFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('custom-record-submit')));
    await tester.pumpAndSettle();

    final holding = (await repository.getHoldings()).single;
    expect(holding.totalFees, Decimal.parse('5'));
    expect(holding.totalBuy, Decimal.parse('5005'));
    expect(holding.profit, Decimal.parse('-5'));

    await _disposeTree(tester);
  });

  testWidgets('分析页排除现金与负债', (tester) async {
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
        code: '000001',
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

    expect(find.text('估值覆盖 1/1'), findsOneWidget);
    expect(find.text('现金'), findsNothing);
    expect(find.text('负债'), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('自定义产品计入分析', (tester) async {
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
        code: '000001',
        quantity: Decimal.parse('100'),
        costPrice: Decimal.parse('10'),
        currentPrice: Decimal.parse('12'),
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'custom',
        name: '某银行理财',
        amount: Decimal.parse('5000'),
        fee: Decimal.parse('5'),
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
          home: const AnalysisPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('收益概览'));

    expect(find.text('估值覆盖 2/2'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('某银行理财'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('某银行理财'), findsWidgets);

    await _disposeTree(tester);
  });

  testWidgets('只有负债时分析页显示整页空态', (tester) async {
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
        categoryId: 'liability',
        name: '信用卡',
        amount: Decimal.parse('-3000'),
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
          home: const AnalysisPage(),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('暂无可分析的理财资产'));

    expect(find.text('收益概览'), findsNothing);
    expect(find.textContaining('估值覆盖'), findsNothing);
    expect(find.text('去添加资产'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('只有现金时分析页显示整页空态', (tester) async {
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
    await _pumpUntil(tester, find.text('暂无可分析的理财资产'));

    expect(find.text('收益概览'), findsNothing);
    expect(find.textContaining('估值覆盖'), findsNothing);
    expect(find.text('去添加资产'), findsOneWidget);

    await _disposeTree(tester);
  });
}
