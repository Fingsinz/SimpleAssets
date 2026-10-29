import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/core/export_files.dart';

void main() {
  test('导出文件名包含时间戳与扩展名', () {
    expect(
      buildExportFileName(DateTime(2026, 1, 2, 3, 4), 'json'),
      'simple_assets_20260102_0304.json',
    );
  });

  test('清理旧的导出文件且不影响其他文件与子目录', () async {
    final directory = await Directory.systemTemp.createTemp(
      'simple_assets_exports',
    );
    addTearDown(() => directory.delete(recursive: true));

    final oldJson = File('${directory.path}/simple_assets_20250101_1200.json')
      ..writeAsStringSync('{}');
    final oldExcel = File('${directory.path}/simple_assets_20250101_1200.xlsx')
      ..writeAsBytesSync([0]);
    final unrelated = File('${directory.path}/notes.txt')
      ..writeAsStringSync('keep');
    final nested = Directory('${directory.path}/sub')..createSync();
    final nestedExport = File('${nested.path}/simple_assets_old.json')
      ..writeAsStringSync('{}');

    final removed = await cleanupOldExportFiles(directory);

    expect(removed, 2);
    expect(oldJson.existsSync(), isFalse);
    expect(oldExcel.existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue);
    expect(nestedExport.existsSync(), isTrue);
  });

  test('目录不存在时不报错', () async {
    final missing = Directory(
      '${Directory.systemTemp.path}/simple_assets_missing_${DateTime.now().microsecondsSinceEpoch}',
    );
    expect(await cleanupOldExportFiles(missing), 0);
  });

  test('清理临时导出、导入缓存与分享缓存，不影响其他文件与目录', () async {
    final directory = await Directory.systemTemp.createTemp(
      'simple_assets_transient',
    );
    addTearDown(() => directory.delete(recursive: true));

    final exportFile = File('${directory.path}/simple_assets_20250101_1200.json')
      ..writeAsStringSync('{}');
    final pickerCache = Directory('${directory.path}/file_picker/1730000000')
      ..createSync(recursive: true);
    final pickedCopy = File('${pickerCache.path}/backup.json')
      ..writeAsStringSync('{}');
    final shareCache = Directory('${directory.path}/share_plus')
      ..createSync();
    final sharedCopy = File('${shareCache.path}/simple_assets_20250101_1200.json')
      ..writeAsStringSync('{}');
    final unrelated = File('${directory.path}/notes.txt')
      ..writeAsStringSync('keep');
    final nested = Directory('${directory.path}/sub')..createSync();
    final nestedExport = File('${nested.path}/simple_assets_old.json')
      ..writeAsStringSync('{}');

    final removed = await cleanupTransientFiles(directory);

    expect(removed, 3);
    expect(exportFile.existsSync(), isFalse);
    expect(pickerCache.existsSync(), isFalse);
    expect(pickedCopy.existsSync(), isFalse);
    expect(shareCache.existsSync(), isFalse);
    expect(sharedCopy.existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue);
    expect(nestedExport.existsSync(), isTrue);
  });

  test('临时目录不存在时不报错', () async {
    final missing = Directory(
      '${Directory.systemTemp.path}/simple_assets_missing_${DateTime.now().microsecondsSinceEpoch}',
    );
    expect(await cleanupTransientFiles(missing), 0);
  });

  test('导入结束后删除 file_picker 留下的缓存副本', () async {
    final directory = await Directory.systemTemp.createTemp(
      'simple_assets_picked',
    );
    addTearDown(() => directory.delete(recursive: true));
    final copy = File('${directory.path}/backup.json')
      ..writeAsStringSync('{}');

    await deleteCachedFile(copy.path);

    expect(copy.existsSync(), isFalse);
  });

  test('缓存副本不存在或路径为空时不报错', () async {
    await deleteCachedFile(null);
    await deleteCachedFile('');
    await deleteCachedFile(
      '${Directory.systemTemp.path}/simple_assets_missing_'
      '${DateTime.now().microsecondsSinceEpoch}.json',
    );
  });
}
