import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'presentation/common/amount_visibility.dart';
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
    final preset = ref.watch(themePresetProvider);
    final layoutStyle = ref.watch(layoutStyleProvider);
    return AmountVisibility(
      hidden: ref.watch(hideAmountsProvider),
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightFor(preset, layoutStyle),
        darkTheme: AppTheme.darkFor(preset, layoutStyle),
        themeMode: ref.watch(themeModeProvider),
        // 纸张与墨色整体渐变，180ms，换肤不跳变。
        themeAnimationDuration: const Duration(milliseconds: 180),
        themeAnimationCurve: Curves.easeOutCubic,
        routerConfig: appRouter,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
