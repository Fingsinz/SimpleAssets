import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/entities/asset_transaction_draft.dart';
import 'package:simple_assets/presentation/analysis/analysis_page.dart';
import 'package:simple_assets/presentation/providers/database_provider.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';

Future<AppDatabase> _seed() async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final repository = AssetRepositoryImpl(database);
  final id = await repository.addHolding(
    AssetHoldingDraft(
      categoryId: 'fund',
      name: '测试基金',
      quantity: Decimal.parse('100'),
      costPrice: Decimal.parse('10'),
      purchaseDate: DateTime(2026, 9, 1),
    ),
  );
  await repository.addTransaction(
    AssetTransactionDraft(
      holdingId: id,
      type: TransactionType.buy,
      quantity: Decimal.parse('100'),
      price: Decimal.parse('12'),
      date: DateTime(2026, 10, 1),
    ),
  );
  await database.priceHistoryDao.upsertMonth(
    holdingId: id,
    period: '2026-09',
    price: '12',
    observedAt: DateTime(2026, 9, 30),
  );
  await database.priceHistoryDao.upsertMonth(
    holdingId: id,
    period: '2026-10',
    price: '13',
    observedAt: DateTime(2026, 10, 26),
  );
  return database;
}

/// 跨年份数据：2025-12 首笔买入，2026-10 追加买入。
Future<AppDatabase> _seedMultiYear() async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final repository = AssetRepositoryImpl(database);
  final id = await repository.addHolding(
    AssetHoldingDraft(
      categoryId: 'fund',
      name: '跨年基金',
      quantity: Decimal.parse('100'),
      costPrice: Decimal.parse('10'),
      purchaseDate: DateTime(2025, 12, 1),
    ),
  );
  await repository.addTransaction(
    AssetTransactionDraft(
      holdingId: id,
      type: TransactionType.buy,
      quantity: Decimal.parse('100'),
      price: Decimal.parse('10'),
      date: DateTime(2025, 12, 1),
    ),
  );
  await repository.addTransaction(
    AssetTransactionDraft(
      holdingId: id,
      type: TransactionType.buy,
      quantity: Decimal.parse('100'),
      price: Decimal.parse('12'),
      date: DateTime(2026, 10, 1),
    ),
  );
  for (final entry in {
    '2025-12': '10',
    '2026-09': '12',
    '2026-10': '13',
  }.entries) {
    final date = DateTime(
      int.parse(entry.key.split('-')[0]),
      int.parse(entry.key.split('-')[1]) + 1,
      0,
    );
    await database.priceHistoryDao.upsertMonth(
      holdingId: id,
      period: entry.key,
      price: entry.value,
      observedAt: date,
    );
  }
  return database;
}

/// 跨年基金有流水与价格；空仓基金没有任何流水与价格。
Future<AppDatabase> _seedWithEmptyHolding() async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final repository = AssetRepositoryImpl(database);
  final id = await repository.addHolding(
    AssetHoldingDraft(
      categoryId: 'fund',
      name: '跨年基金',
      quantity: Decimal.parse('100'),
      costPrice: Decimal.parse('10'),
      purchaseDate: DateTime(2025, 12, 1),
    ),
  );
  await repository.addTransaction(
    AssetTransactionDraft(
      holdingId: id,
      type: TransactionType.buy,
      quantity: Decimal.parse('100'),
      price: Decimal.parse('10'),
      date: DateTime(2025, 12, 1),
    ),
  );
  await database.priceHistoryDao.upsertMonth(
    holdingId: id,
    period: '2025-12',
    price: '10',
    observedAt: DateTime(2025, 12, 31),
  );
  // 直接插表：addHolding 会自动生成首笔买入流水，这里要一个没有流水的持仓。
  await database.assetDao.insertHolding(
    AssetHoldingsCompanion.insert(
      categoryId: 'fund',
      name: '空仓基金',
      quantity: '0',
      costPrice: '0',
      purchaseDate: DateTime(2026, 1, 1),
    ),
  );
  return database;
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _pumpAnalysis(WidgetTester tester, AppDatabase database) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

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
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );

/// 年历是横向可滚动的，右侧月份的单元格需要先滚入可视区才能点击。
/// 把任意控件滚到列表可视区内（避开 AppBar），再供 tap 使用。
Future<void> _scrollIntoTappable(WidgetTester tester, Finder finder) async {
  final list = find.byType(ListView);
  for (var i = 0; i < 8; i++) {
    final viewport = tester.getRect(list);
    final rect = tester.getRect(finder);
    final top = viewport.top + 8;
    final bottom = viewport.bottom - 8;
    if (rect.top >= top && rect.bottom <= bottom) return;
    final dy = rect.top < top ? top - rect.top : -(rect.bottom - bottom);
    await tester.drag(list, Offset(0, dy));
    await tester.pumpAndSettle();
  }
}

Future<void> _tapCalendarCell(WidgetTester tester, Key key) async {
  final scroll = find.byKey(const Key('calendar-scroll'));
  await _scrollTo(tester, scroll);
  final cell = find.byKey(key);
  for (var i = 0; i < 8; i++) {
    final viewport = tester.getRect(scroll);
    final rect = tester.getRect(cell);
    final visible = rect.left >= viewport.left &&
        rect.right <= viewport.right &&
        rect.top >= viewport.top &&
        rect.bottom <= viewport.bottom;
    if (visible) break;
    await tester.drag(scroll, const Offset(-120, 0));
    await tester.pumpAndSettle();
  }
  await tester.tap(cell);
  await tester.pump();
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('分析页展示收益概览、收益细节与收益年历', (tester) async {
    final database = await tester.runAsync(_seed);
    addTearDown(database!.close);
    await _pumpAnalysis(tester, database);

    expect(find.text('收益概览'), findsOneWidget);
    expect(find.text('累计收益'), findsOneWidget);
    expect(find.byKey(const Key('analysis-include-cash')), findsOneWidget);

    await _scrollTo(tester, find.text('收益细节'));
    expect(find.text('收益细节'), findsOneWidget);

    await _scrollTo(tester, find.text('收益年历'));
    expect(find.text('收益年历'), findsOneWidget);
    expect(find.byKey(const Key('calendar-year-selector')), findsOneWidget);

    await _scrollTo(tester, find.text('月度'));
    expect(find.text('月度'), findsWidgets);
    expect(find.text('年度'), findsWidgets);
    expect(find.text('记录以来'), findsWidgets);

    await _disposeTree(tester);
  });

  testWidgets('年历只展示所选年份，切换年份不保留明细', (tester) async {
    final database = await tester.runAsync(_seedMultiYear);
    addTearDown(database!.close);
    await _pumpAnalysis(tester, database);

    await _scrollTo(tester, find.text('收益年历'));
    expect(find.byKey(const Key('calendar-2026-09')), findsOneWidget);
    expect(find.byKey(const Key('calendar-2025-12')), findsNothing);

    await _tapCalendarCell(tester, const Key('calendar-2026-09'));
    expect(find.byKey(const Key('calendar-detail-table')), findsOneWidget);

    await _scrollIntoTappable(
      tester,
      find.byKey(const Key('calendar-year-selector')),
    );
    await tester.tap(find.byKey(const Key('calendar-year-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-2025-12')), findsOneWidget);
    expect(find.byKey(const Key('calendar-2026-09')), findsNothing);
    expect(find.byKey(const Key('calendar-detail-table')), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('点击月份只显示该月一行，点击全年显示该年汇总', (tester) async {
    final database = await tester.runAsync(_seedMultiYear);
    addTearDown(database!.close);
    await _pumpAnalysis(tester, database);

    await _scrollTo(tester, find.text('收益年历'));
    expect(find.byKey(const Key('calendar-detail-table')), findsNothing);

    await _tapCalendarCell(tester, const Key('calendar-2026-09'));

    final table = find.byKey(const Key('calendar-detail-table'));
    expect(table, findsOneWidget);
    expect(
      find.descendant(of: table, matching: find.text('2026-09')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: table, matching: find.text('2026-10')),
      findsNothing,
    );
    expect(
      find.descendant(of: table, matching: find.text('月份')),
      findsOneWidget,
    );

    await _tapCalendarCell(tester, const Key('calendar-2026-all'));

    expect(
      find.descendant(of: table, matching: find.text('2026')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: table, matching: find.text('2026-09')),
      findsNothing,
    );
    expect(
      find.descendant(of: table, matching: find.text('年份')),
      findsOneWidget,
    );

    await _disposeTree(tester);
  });

  testWidgets('统计曲线可切换为单品曲线', (tester) async {
    final database = await tester.runAsync(_seedMultiYear);
    addTearDown(database!.close);
    await _pumpAnalysis(tester, database);

    final selector = find.byKey(const Key('performance-holding-selector'));
    await _scrollTo(tester, selector);
    expect(find.text('全部持仓'), findsOneWidget);

    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('跨年基金').last);
    await tester.pumpAndSettle();

    expect(find.text('全部持仓'), findsNothing);
    expect(find.text('跨年基金'), findsWidgets);

    await _disposeTree(tester);
  });

  testWidgets('单品没有曲线数据时，选择器仍可切回全部持仓', (tester) async {
    final database = await tester.runAsync(_seedWithEmptyHolding);
    addTearDown(database!.close);
    await _pumpAnalysis(tester, database);

    final selector = find.byKey(const Key('performance-holding-selector'));
    await _scrollTo(tester, selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('空仓基金').last);
    await tester.pumpAndSettle();

    expect(find.text('该持仓还没有可绘制的收益曲线。'), findsOneWidget);

    await _scrollIntoTappable(tester, selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部持仓').last);
    await tester.pumpAndSettle();

    expect(find.text('全部持仓'), findsOneWidget);
    expect(find.text('该持仓还没有可绘制的收益曲线。'), findsNothing);

    await _disposeTree(tester);
  });

  testWidgets('折线图口径切换只更新图下指标文字，不改动年历明细', (tester) async {
    final database = await tester.runAsync(_seedMultiYear);
    addTearDown(database!.close);
    await _pumpAnalysis(tester, database);

    await _scrollTo(tester, find.text('收益年历'));
    await _tapCalendarCell(tester, const Key('calendar-2026-09'));

    final table = find.byKey(const Key('calendar-detail-table'));
    expect(
      find.descendant(of: table, matching: find.text('2026-09')),
      findsOneWidget,
    );

    await _scrollTo(tester, find.text('年度'));
    await tester.tap(find.text('年度'));
    await tester.pump();

    expect(
      find.descendant(of: table, matching: find.text('2026-09')),
      findsOneWidget,
    );
    expect(find.textContaining('收益额'), findsWidgets);
    expect(find.textContaining('直接收益率'), findsWidgets);
    expect(find.textContaining('年化收益率'), findsWidgets);
    expect(find.textContaining('时间加权收益率'), findsWidgets);
    expect(find.textContaining('最大回撤'), findsWidgets);

    await _disposeTree(tester);
  });
}
