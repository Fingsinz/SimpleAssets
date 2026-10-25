import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
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
}
