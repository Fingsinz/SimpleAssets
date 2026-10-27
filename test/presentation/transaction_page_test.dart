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
import 'package:simple_assets/presentation/holding/holding_detail_page.dart';
import 'package:simple_assets/presentation/providers/database_provider.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';
import 'package:simple_assets/presentation/transaction/transaction_form_page.dart';
import 'package:simple_assets/presentation/transaction/transaction_list_page.dart';

Future<AppDatabase> _seedDatabase({String costPrice = '10'}) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  await AssetRepositoryImpl(database).addHolding(
    AssetHoldingDraft(
      categoryId: 'fund',
      name: '测试基金',
      quantity: Decimal.parse('100'),
      costPrice: Decimal.parse(costPrice),
      purchaseDate: DateTime(2025, 1, 1),
    ),
  );
  return database;
}

Future<void> _pumpPage(
  WidgetTester tester,
  AppDatabase database,
  Widget page,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: MaterialApp(theme: AppTheme.light, home: page),
    ),
  );
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
  testWidgets('记录一笔买入写入数据库', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seedDatabase);
    addTearDown(database!.close);

    await _pumpPage(
      tester,
      database,
      const TransactionFormPage(holdingId: 1),
    );
    await _pumpUntil(tester, find.byKey(const Key('transaction-quantity')));

    await tester.enterText(
      find.byKey(const Key('transaction-quantity')),
      '10',
    );
    await tester.enterText(find.byKey(const Key('transaction-price')), '2');
    await tester.enterText(find.byKey(const Key('transaction-fee')), '0.5');
    await tester.ensureVisible(find.byKey(const Key('transaction-submit')));
    await tester.tap(find.byKey(const Key('transaction-submit')));

    List<AssetTransaction>? transactions;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      transactions = await tester.runAsync(
        () => AssetRepositoryImpl(database).getTransactions(1),
      );
      if (transactions != null && transactions.length >= 2) break;
    }

    expect(transactions, isNotNull);
    expect(transactions, hasLength(2));
    expect(transactions!.last.fee, Decimal.parse('0.5'));
    expect(transactions.last.quantity, Decimal.parse('10'));

    await _disposeTree(tester);
  });

  testWidgets('卖出超过持有显示错误且不写入', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seedDatabase);
    addTearDown(database!.close);

    await _pumpPage(
      tester,
      database,
      const TransactionFormPage(holdingId: 1),
    );
    await _pumpUntil(tester, find.byKey(const Key('transaction-quantity')));

    await tester.tap(find.text('卖出'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('transaction-quantity')),
      '999',
    );
    await tester.enterText(find.byKey(const Key('transaction-price')), '12');
    await tester.ensureVisible(find.byKey(const Key('transaction-submit')));
    await tester.tap(find.byKey(const Key('transaction-submit')));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.textContaining('卖出数量超过').evaluate().isNotEmpty) break;
    }

    expect(find.textContaining('卖出数量超过'), findsOneWidget);
    final transactions = await tester.runAsync(
      () => AssetRepositoryImpl(database).getTransactions(1),
    );
    expect(transactions, hasLength(1));

    await _disposeTree(tester);
  });

  testWidgets('拆股表单显示折算预览', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seedDatabase);
    addTearDown(database!.close);

    await _pumpPage(
      tester,
      database,
      const TransactionFormPage(holdingId: 1),
    );
    await _pumpUntil(tester, find.byKey(const Key('transaction-quantity')));

    await tester.tap(find.text('拆股/折算'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('transaction-ratio')), '2');
    await tester.pump();

    expect(find.textContaining('200'), findsOneWidget);
    expect(find.textContaining('5.00'), findsOneWidget);

    await _disposeTree(tester);
  });

  testWidgets('详情页展示交易记录', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seedDatabase);
    addTearDown(database!.close);
    await tester.runAsync(() async {
      final repository = AssetRepositoryImpl(database);
      await repository.addTransaction(
        AssetTransactionDraft(
          holdingId: 1,
          type: TransactionType.buy,
          quantity: Decimal.parse('10'),
          price: Decimal.parse('2'),
          date: DateTime(2025, 2, 1),
        ),
      );
      await repository.addTransaction(
        AssetTransactionDraft(
          holdingId: 1,
          type: TransactionType.dividend,
          amount: Decimal.parse('5'),
          date: DateTime(2025, 3, 1),
        ),
      );
    });

    await _pumpPage(tester, database, const HoldingDetailPage(holdingId: 1));
    await _pumpUntil(tester, find.text('持仓信息'));

    await tester.scrollUntilVisible(
      find.text('交易记录'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('交易记录'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('分红'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('买入'), findsWidgets);
    expect(find.textContaining('分红'), findsWidgets);

    await _disposeTree(tester);
  });

  testWidgets('全局流水列表按持仓展示', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(_seedDatabase);
    addTearDown(database!.close);
    await tester.runAsync(() async {
      await AssetRepositoryImpl(database).addTransaction(
        AssetTransactionDraft(
          holdingId: 1,
          type: TransactionType.buy,
          quantity: Decimal.parse('10'),
          price: Decimal.parse('2'),
          date: DateTime(2025, 2, 1),
        ),
      );
    });

    await _pumpPage(tester, database, const TransactionListPage());
    await _pumpUntil(tester, find.textContaining('买入'));

    expect(find.text('全部流水'), findsOneWidget);
    expect(find.textContaining('测试基金'), findsWidgets);

    await _disposeTree(tester);
  });

  testWidgets('零成本期初流水不改单价时允许保存', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = await tester.runAsync(
      () => _seedDatabase(costPrice: '0'),
    );
    addTearDown(database!.close);
    final buy = (await tester.runAsync(
      () => AssetRepositoryImpl(database).getTransactions(1),
    ))!
        .first;

    await _pumpPage(
      tester,
      database,
      TransactionFormPage(transactionId: buy.id),
    );
    await _pumpUntil(tester, find.byKey(const Key('transaction-submit')));

    await tester.ensureVisible(find.byKey(const Key('transaction-submit')));
    await tester.tap(find.byKey(const Key('transaction-submit')));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('transaction-submit')).evaluate().isEmpty) break;
    }

    final updated = (await tester.runAsync(
      () => AssetRepositoryImpl(database).getTransactions(1),
    ))!
        .first;
    expect(updated.price, Decimal.zero);

    await _disposeTree(tester);
  });
}
