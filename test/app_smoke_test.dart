import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/app.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/presentation/providers/database_provider.dart';

void main() {
  testWidgets('应用启动后展示总览空状态', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const SimpleAssetsApp(),
      ),
    );

    // 不用 pumpAndSettle：数据库流与主题动画可能持续调度帧。
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('还没有资产').evaluate().isNotEmpty) break;
    }

    expect(find.text('总览'), findsWidgets);
    expect(find.text('还没有资产'), findsOneWidget);
    expect(find.text('添加第一笔资产'), findsOneWidget);

    // 卸载 ProviderScope，让 Drift 的流清理 Timer 在测试结束前执行完毕。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('底部栏五个入口，点击加号弹出添加菜单', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const SimpleAssetsApp(),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('还没有资产').evaluate().isNotEmpty) break;
    }

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byKey(const Key('nav-add')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.add_rounded),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('添加资产').evaluate().isNotEmpty) break;
    }
    expect(find.text('添加资产'), findsOneWidget);
    expect(find.text('记录交易'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('应用 detach 时关闭数据库连接', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() async {
      try {
        await database.close();
      } catch (_) {
        // 已由生命周期回调关闭。
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const SimpleAssetsApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    await tester.pump();

    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
