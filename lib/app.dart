import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'presentation/providers/database_provider.dart';
import 'presentation/providers/settings_providers.dart';
import 'presentation/router/app_router.dart';
import 'presentation/theme/app_theme.dart';

class SimpleAssetsApp extends ConsumerStatefulWidget {
  const SimpleAssetsApp({super.key});

  @override
  ConsumerState<SimpleAssetsApp> createState() => _SimpleAssetsAppState();
}

class _SimpleAssetsAppState extends ConsumerState<SimpleAssetsApp>
    with WidgetsBindingObserver {
  bool _databaseClosed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 正常退出时主动关闭数据库连接；进程被系统直接杀死时此回调不保证触发。
    if (state != AppLifecycleState.detached || _databaseClosed) return;
    _databaseClosed = true;
    ref.read(databaseProvider).close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightFor(ref.watch(themePresetProvider)),
      darkTheme: AppTheme.darkFor(ref.watch(themePresetProvider)),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: appRouter,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
