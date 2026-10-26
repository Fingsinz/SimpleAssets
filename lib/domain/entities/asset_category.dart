/// 内置品类 id，避免业务代码里散落字符串。
class AssetCategoryIds {
  AssetCategoryIds._();

  static const String cash = 'cash';
  static const String preciousMetal = 'gold';
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
