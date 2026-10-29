import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_assets/core/constants.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/presentation/providers/database_provider.dart';
import 'package:simple_assets/presentation/providers/settings_providers.dart';
import 'package:simple_assets/presentation/settings/settings_page.dart';
import 'package:simple_assets/presentation/theme/app_theme.dart';
import 'package:simple_assets/presentation/theme/theme_presets.dart';

void main() {
  testWidgets('默认靛青 / 跟随系统，色盘可切换配色与深色并持久化', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      container.read(settingsProvider).valueOrNull?.themeMode,
      ThemeMode.system,
    );
    expect(
      container.read(settingsProvider).valueOrNull?.themePreset,
      AppThemePreset.indigo,
    );

    await tester.tap(find.byKey(const Key('theme-picker')));
    await tester.pumpAndSettle();

    expect(find.text('靛青'), findsOneWidget);
    expect(find.text('青瓷'), findsOneWidget);
    expect(find.text('鎏金'), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('浅色'), findsOneWidget);
    expect(find.text('深色'), findsOneWidget);

    await tester.tap(find.byKey(const Key('theme-preset-gilt')));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).valueOrNull?.themePreset,
      AppThemePreset.gilt,
    );
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.prefThemePreset), 'gilt');

    await tester.tap(find.byKey(const Key('theme-mode-dark')));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).valueOrNull?.themeMode,
      ThemeMode.dark,
    );
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.prefThemeMode), 'dark');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('2 倍字号下外观面板不溢出且仍可切换', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const SettingsPage(),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.tap(find.byKey(const Key('theme-picker')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('theme-mode-system')), findsOneWidget);
    await tester.tap(find.byKey(const Key('theme-preset-celadon')));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).valueOrNull?.themePreset,
      AppThemePreset.celadon,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
