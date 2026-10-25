/// 导入文件的防护上限，避免一次性读入超大文件或构造过的表格造成内存峰值。
class ImportLimits {
  const ImportLimits._();

  /// 单个导入文件的大小上限：10MB。
  static const int maxBytes = 10 * 1024 * 1024;

  /// 单次导入的最大记录数。
  static const int maxRows = 10000;

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
}
