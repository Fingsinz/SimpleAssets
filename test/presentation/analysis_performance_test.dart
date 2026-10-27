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

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('分析页展示收益细节、表格与年历', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seed);
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

    await tester.scrollUntilVisible(
      find.text('收益细节'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('收益细节'), findsOneWidget);
    expect(find.text('月度'), findsWidgets);
    expect(find.text('年度'), findsWidgets);
    expect(find.text('记录以来'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('收益年历'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('收益年历'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('切换年度与点击年历单元格', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seed);
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

    await tester.scrollUntilVisible(
      find.text('收益细节'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('年度'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('performance-year-header')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('performance-year-header')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('calendar-2026-09')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('calendar-2026-09')));
    await tester.pump();
    expect(find.textContaining('2026-09'), findsWidgets);

    await _disposeTree(tester);
  });
}
