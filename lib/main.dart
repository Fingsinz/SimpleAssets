import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/export_files.dart';
import 'data/local/database.dart';
import 'presentation/providers/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _cleanupTransientFiles();
  final database = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const SimpleAssetsApp(),
    ),
  );
}

/// 启动时清除上次运行留下的明文临时文件。
///
/// 缓存清理是尽力而为，失败不应阻止应用启动。
Future<void> _cleanupTransientFiles() async {
  try {
    await cleanupTransientFiles(await getTemporaryDirectory());
  } catch (_) {
    // 忽略：缓存目录不可用时继续启动。
  }
}
