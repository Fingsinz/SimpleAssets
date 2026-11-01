/// 导入文件触达防护上限时抛出，调用方直接展示 [message]。
class ImportLimitException implements Exception {
  final String message;

  const ImportLimitException(this.message);

  @override
  String toString() => message;
}

/// 导入文件的防护上限，避免一次性读入超大文件或构造过的表格造成内存峰值。
class ImportLimits {
  const ImportLimits._();

  /// 单个导入文件的大小上限：10MB。
  static const int maxBytes = 10 * 1024 * 1024;

  /// 单次导入的最大记录数。
  static const int maxRows = 10000;

  /// 单个 xlsx 的最大工作表数。
  static const int maxSheets = 20;

  /// 解压后单元格总数上限，防止小体积文件解压出巨大表格。
  static const int maxCells = 500000;

  static String? validateBytes(int bytes) {
    if (bytes > maxBytes) {
      return '文件过大，导入上限为 10MB';
    }
    return null;
  }

  static String? validateRows(int rows) {
    if (rows > maxRows) {
      return '记录过多，单次导入上限为 $maxRows 条';
    }
    return null;
  }

  static String? validateSheets(int sheets) {
    if (sheets > maxSheets) {
      return '工作表过多，单次导入上限为 $maxSheets 个';
    }
    return null;
  }

  static String? validateCells(int cells) {
    if (cells > maxCells) {
      return '单元格过多，单次导入上限为 $maxCells 个';
    }
    return null;
  }
}
