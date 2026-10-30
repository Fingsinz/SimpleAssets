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
import 'package:simple_assets/presentation/common/amount_visibility.dart';
import 'package:simple_assets/presentation/common/profit_text.dart';
import 'package:simple_assets/presentation/overview/overview_page.dart';
import 'package:simple_assets/presentation/providers/database_provider.dart';
import 'package:simple_assets/presentation/providers/settings_providers.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';

Future<AppDatabase> _seed() async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
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
  return database;
}

Widget _wrap(bool hidden, Widget child) {
  return AmountVisibility(
    hidden: hidden,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('隐藏金额时所有金额格式都变成占位符', (tester) async {
    await tester.pumpWidget(
      _wrap(
        true,
        Builder(
          builder: (context) => Column(
            children: [
              Text(context.money(Decimal.parse('1234.50'))),
              Text(context.price(Decimal.parse('4.0210'))),
              Text(context.compactMoney(Decimal.parse('123456'))),
            ],
          ),
        ),
      ),
    );

    expect(find.text(AmountVisibility.mask), findsNWidgets(3));
  });

  testWidgets('显示金额时格式不变', (tester) async {
    await tester.pumpWidget(
      _wrap(
        false,
        Builder(
          builder: (context) => Column(
            children: [
              Text(context.money(Decimal.parse('1234.50'))),
              Text(context.price(Decimal.parse('4.0210'))),
            ],
          ),
        ),
      ),
    );

    expect(find.text('¥1,234.50'), findsOneWidget);
    expect(find.text('¥4.0210'), findsOneWidget);
  });

  testWidgets('盈亏文字隐藏时不留正号，收益率照常显示', (tester) async {
    await tester.pumpWidget(
      _wrap(
        true,
        ProfitText(
          amount: Decimal.parse('199.80'),
          percent: 4.14,
        ),
      ),
    );

    expect(find.text('${AmountVisibility.mask} (+4.14%)'), findsOneWidget);
    expect(find.textContaining('+¥'), findsNothing);
  });

  testWidgets('总览的眼睛开关遮住金额并持久化', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
        child: Consumer(
          builder: (context, ref, child) => AmountVisibility(
            hidden: ref.watch(hideAmountsProvider),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              home: const OverviewPage(),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('¥'), findsWidgets);
    expect(find.text(AmountVisibility.mask), findsNothing);

    await tester.tap(find.byKey(const Key('toggle-amounts')));
    await tester.pumpAndSettle();

    expect(find.text(AmountVisibility.mask), findsWidgets);
    // 收益率仍然以百分比显示。
    expect(find.textContaining('%'), findsWidgets);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppConstants.prefHideAmounts), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
