/// 内置品类 id，避免业务代码里散落字符串。
class AssetCategoryIds {
  AssetCategoryIds._();

  static const String cash = 'cash';
  static const String preciousMetal = 'gold';
  static const String custom = 'custom';
  static const String liability = 'liability';
}

/// 品类展示顺序的唯一 token：资产列表排序、资产页筛选条共用。
///
/// 顺序表达的是「风险从高到低」：
/// 股票 → ETF → 基金 → 债券 → 贵金属 → 自定义产品 → 现金 → 负债。
/// 数据库的 sortOrder 只决定字典表的稳定存储顺序，不再直接暴露到界面。
class AssetCategoryOrder {
  AssetCategoryOrder._();

  static const List<String> ids = [
    'stock',
    'etf',
    'fund',
    'bond',
    'gold',
    'custom',
    'cash',
    'liability',
  ];

  static int rank(String id) {
    final index = ids.indexOf(id);
    return index >= 0 ? index : ids.length;
  }

  static int compare(String a, String b) => rank(a).compareTo(rank(b));

  static List<AssetCategory> sortCategories(Iterable<AssetCategory> source) {
    return source.toList()
      ..sort(
        (a, b) => compare(a.id, b.id),
      );
  }
}

/// 资产品类（来自数据库字典表，可扩展，无需修改现有代码）。
class AssetCategory {
  final String id;
  final String displayName;
  final String currencyCode;
  final String? icon;
  final int sortOrder;

  const AssetCategory({
    required this.id,
    required this.displayName,
    this.currencyCode = 'CNY',
    this.icon,
    this.sortOrder = 0,
  });

  /// 内置品类，仅用于首次建库时的种子数据。
  static const List<AssetCategory> builtIn = [
    AssetCategory(
      id: AssetCategoryIds.cash,
      displayName: '现金',
      icon: 'cash',
      sortOrder: 0,
    ),
    AssetCategory(id: 'bond', displayName: '债券', icon: 'bond', sortOrder: 1),
    AssetCategory(id: 'fund', displayName: '基金', icon: 'fund', sortOrder: 2),
    AssetCategory(id: 'stock', displayName: '股票', icon: 'stock', sortOrder: 3),
    AssetCategory(id: 'etf', displayName: 'ETF', icon: 'etf', sortOrder: 4),
    AssetCategory(
      id: AssetCategoryIds.preciousMetal,
      displayName: '贵金属',
      icon: 'gold',
      sortOrder: 5,
    ),
    AssetCategory(
      id: AssetCategoryIds.custom,
      displayName: '自定义产品',
      icon: 'custom',
      sortOrder: 6,
    ),
    AssetCategory(
      id: AssetCategoryIds.liability,
      displayName: '负债',
      icon: 'liability',
      sortOrder: 7,
    ),
  ];

  static AssetCategory? findBuiltIn(String id) {
    for (final category in builtIn) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  String toString() => 'AssetCategory($id, $displayName)';
}
