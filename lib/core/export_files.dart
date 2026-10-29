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

/// file_picker 把用户选中的文件复制到缓存下的这个目录。
const String pickerCacheDirectoryName = 'file_picker';

/// share_plus 在分享前把文件复制到缓存下的这个目录。
const String shareCacheDirectoryName = 'share_plus';

/// 清理缓存目录中的明文临时文件，返回删除的条目数量。
///
/// 覆盖导出时生成的 `simple_assets_*.json|xlsx`、导入时 file_picker
/// 留下的副本目录，以及分享时 share_plus 留下的副本目录。只处理缓存
/// 根目录下的已知条目，不递归其他目录，也不影响其他文件。
Future<int> cleanupTransientFiles(Directory directory) async {
  var removed = await cleanupOldExportFiles(directory);
  if (!await directory.exists()) return removed;

  for (final name in [pickerCacheDirectoryName, shareCacheDirectoryName]) {
    final cache = Directory('${directory.path}${Platform.pathSeparator}$name');
    if (!await cache.exists()) continue;
    try {
      await cache.delete(recursive: true);
      removed++;
    } catch (_) {
      // 单个目录删除失败不应阻断整体清理。
    }
  }
  return removed;
}

/// 删除导入结束后 file_picker 残留在缓存中的明文副本。
///
/// 副本路径来自插件，删除失败或不存在都不应影响导入结果。
Future<void> deleteCachedFile(String? path) async {
  if (path == null || path.isEmpty) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } catch (_) {
    // 缓存清理是尽力而为，失败不影响主流程。
  }
}
