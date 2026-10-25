import 'dart:typed_data';

import '../../core/result.dart';

/// 导入/导出抽象。新增格式时实现该接口即可，不修改调用方。
abstract class ImportExportRepository {
  Future<Result<Uint8List>> exportJson();

  Future<Result<Uint8List>> exportExcel();

  Future<Result<ImportResult>> importJson(Uint8List bytes);

  Future<Result<ImportResult>> importExcel(Uint8List bytes);
}

class ImportResult {
  final int imported;
  final int skipped;
  final List<String> errors;

  const ImportResult({
    required this.imported,
    required this.skipped,
    this.errors = const [],
  });

  String get message {
    final buffer = StringBuffer('成功导入 $imported 条');
    if (skipped > 0) buffer.write('，跳过 $skipped 条');
    if (errors.isNotEmpty) buffer.write('（${errors.length} 条异常）');
    return buffer.toString();
  }
}
