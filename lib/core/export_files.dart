import 'dart:io';

/// 导出文件名前缀，清理旧导出文件时以此识别。
const String exportFilePrefix = 'simple_assets_';

final RegExp _exportFilePattern = RegExp(
  '^${RegExp.escape(exportFilePrefix)}.*\\.(json|xlsx)\$',
);

/// 生成带时间戳的导出文件名，避免覆盖同一分钟内的多次导出。
String buildExportFileName(DateTime timestamp, String extension) {
  String two(int value) => value.toString().padLeft(2, '0');
  final stamp =
      '${timestamp.year}${two(timestamp.month)}${two(timestamp.day)}_'
      '${two(timestamp.hour)}${two(timestamp.minute)}';
  return '$exportFilePrefix$stamp.$extension';
}

/// 删除目录中历史导出遗留的文件，返回删除数量。
///
/// 只处理当前目录下形如 `simple_assets_*.json|xlsx` 的普通文件，
/// 不递归子目录，也不影响其他文件。
Future<int> cleanupOldExportFiles(Directory directory) async {
  if (!await directory.exists()) return 0;

  var removed = 0;
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!_exportFilePattern.hasMatch(name)) continue;
    try {
      await entity.delete();
      removed++;
    } catch (_) {
      // 单个文件删除失败不应阻断本次导出。
    }
  }
  return removed;
}
