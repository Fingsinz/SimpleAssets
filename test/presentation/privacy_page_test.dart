import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/presentation/providers/database_provider.dart';
import 'package:simple_assets/presentation/settings/privacy_page.dart';
import 'package:simple_assets/presentation/settings/settings_page.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';

void main() {
  testWidgets('隐私说明覆盖本地明文存储、证书固定与系统备份', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPage()));

    expect(find.text('隐私说明'), findsOneWidget);
    expect(find.textContaining('明文'), findsWidgets);
    expect(find.textContaining('证书固定'), findsWidgets);
    expect(find.textContaining('自动备份'), findsWidgets);
    expect(find.textContaining('证券代码'), findsWidgets);
  });

  testWidgets('设置页关于区域提供隐私说明入口', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 1400);
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
        child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('隐私说明'), findsOneWidget);

    // 品牌、作者与 AI 辅助开发标识。
    expect(find.text('方寸有数'), findsOneWidget);
    expect(find.textContaining('方寸有数，资产有底'), findsOneWidget);
    expect(find.text('Fingsinz'), findsOneWidget);
    expect(find.text('DeepSeek'), findsOneWidget);

    // 让 Drift 流清理 Timer 在测试结束前执行完毕。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
