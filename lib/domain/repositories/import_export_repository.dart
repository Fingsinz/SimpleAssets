import 'dart:typed_data';

import '../../core/result.dart';

/// 导入时遇到重复持仓（品类 + 名称 + 代码相同）的处理方式。
enum DuplicatePolicy {
  /// 跳过文件中的重复记录，保留现有数据。
  skip,

  /// 用文件中的数量、成本价、现价、买入日期与备注覆盖现有记录。
  overwrite,
}

/// 导入/导出抽象。新增格式时实现该接口即可，不修改调用方。
abstract class ImportExportRepository {
  Future<Result<Uint8List>> exportJson();

  Future<Result<Uint8List>> exportExcel();

  Future<Result<ImportResult>> importJson(
    Uint8List bytes, {
    DuplicatePolicy duplicates = DuplicatePolicy.skip,
  });

  Future<Result<ImportResult>> importExcel(
    Uint8List bytes, {
    DuplicatePolicy duplicates = DuplicatePolicy.skip,
  });
}

class ImportResult {
  final int imported;
  final int updated;
  final int skipped;
  final List<String> errors;

  const ImportResult({
    required this.imported,
    this.updated = 0,
    required this.skipped,
    this.errors = const [],
  });

  String get message {
    final buffer = StringBuffer('成功导入 $imported 条');
    if (updated > 0) buffer.write('，更新 $updated 条');
    if (skipped > 0) buffer.write('，跳过 $skipped 条');
    if (errors.isNotEmpty) buffer.write('（${errors.length} 条异常）');
    return buffer.toString();
  }
}
