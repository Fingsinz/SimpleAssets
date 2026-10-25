/// 日期格式化工具，避免额外初始化 intl 的 locale 数据。
class DateFormatter {
  DateFormatter._();

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String date(DateTime value) =>
      '${value.year}-${_two(value.month)}-${_two(value.day)}';

  static String dateTime(DateTime value) =>
      '${date(value)} ${_two(value.hour)}:${_two(value.minute)}';

  static String relative(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 30) return '${diff.inDays} 天前';
    return date(value);
  }

  static int holdingDays(DateTime purchaseDate) {
    final days = DateTime.now().difference(purchaseDate).inDays;
    return days < 0 ? 0 : days;
  }
}
