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
}
