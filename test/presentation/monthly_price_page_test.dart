import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/presentation/holding/holding_detail_page.dart';
import 'package:simple_assets/presentation/holding/monthly_price_page.dart';
import 'package:simple_assets/presentation/providers/database_provider.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';

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
  testWidgets('按月列出月末价格，未记录的月份可补录', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final today = DateTime(2026, 3, 15);
    late AppDatabase database;
    late int holdingId;
    await tester.runAsync(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = AssetRepositoryImpl(database);
      holdingId = await repository.addHolding(
        AssetHoldingDraft(
          categoryId: 'fund',
          name: '测试基金',
          code: '000001',
          quantity: Decimal.parse('100'),
          costPrice: Decimal.parse('10'),
          purchaseDate: DateTime(2025, 11, 5),
        ),
      );
      await repository.saveMonthEndPrice(
        holdingId,
        DateTime(2026, 1),
        Decimal.parse('1.5'),
      );
    });
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MonthlyPricePage(holdingId: holdingId, today: today),
        ),
      ),
    );

    await _pumpUntil(tester, find.text('2026-02'));

    expect(find.text('2025-11'), findsOneWidget);
    expect(find.text('2025-12'), findsOneWidget);
    expect(find.text('2026-01'), findsOneWidget);
    expect(find.text('2026-02'), findsOneWidget);
    expect(find.text('年末'), findsOneWidget);
    expect(find.text('¥1.5000'), findsOneWidget);
    expect(find.textContaining('未记录'), findsNWidgets(3));

    await _disposeTree(tester);
  });

  testWidgets('补录某个月的月末价格后写入该月最后一天', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late AppDatabase database;
    late int holdingId;
    await tester.runAsync(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = AssetRepositoryImpl(database);
      holdingId = await repository.addHolding(
        AssetHoldingDraft(
          categoryId: 'fund',
          name: '测试基金',
          code: '000001',
          quantity: Decimal.parse('100'),
          costPrice: Decimal.parse('10'),
          purchaseDate: DateTime(2025, 11, 5),
        ),
      );
    });
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MonthlyPricePage(
            holdingId: holdingId,
            today: DateTime(2026, 3, 15),
          ),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('2026-02'));

    await tester.tap(find.text('2026-02'));
    await tester.pumpAndSettle();
    expect(find.text('补录 2026-02 月末价格'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2.4');
    await tester.tap(find.text('保存'));
    await _pumpUntil(tester, find.text('¥2.4000'));

    expect(find.text('¥2.4000'), findsOneWidget);

    final rows = await tester.runAsync(
      () => database.priceHistoryDao.getForHolding(holdingId),
    );
    expect(rows, hasLength(1));
    expect(rows!.single.period, '2026-02');
    expect(rows.single.price, '2.4');
    expect(rows.single.observedAt, DateTime(2026, 2, 28));

    await _disposeTree(tester);
  });

  testWidgets('持仓详情提供月末价格入口', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late AppDatabase database;
    late int holdingId;
    await tester.runAsync(() async {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      final repository = AssetRepositoryImpl(database);
      holdingId = await repository.addHolding(
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
    });
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: HoldingDetailPage(holdingId: holdingId),
        ),
      ),
    );
    await _pumpUntil(tester, find.text('月末价格'));

    expect(find.text('月末价格'), findsOneWidget);
    expect(find.text('补录'), findsOneWidget);

    await _disposeTree(tester);
  });
}
