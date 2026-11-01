import '../entities/asset_category.dart';
import '../entities/asset_holding.dart';

/// 资产列表的排序方式。
enum HoldingSortMode {
  /// 按当前价值从高到低（默认）。
  amount,

  /// 按品类固定顺序，品类内按金额从高到低。
  category;

  String get label => switch (this) {
        HoldingSortMode.amount => '金额降序',
        HoldingSortMode.category => '品类',
      };
}

/// 资产列表排序（纯函数）。
class SortHoldings {
  SortHoldings._();

  /// 品类展示顺序与筛选条、配置图共用 [AssetCategoryOrder]。
  static const List<String> categoryOrder = AssetCategoryOrder.ids;

  static List<AssetHolding> apply(
    List<AssetHolding> holdings,
    HoldingSortMode mode,
  ) {
    final sorted = List<AssetHolding>.from(holdings);
    sorted.sort((a, b) => switch (mode) {
          HoldingSortMode.amount => _byAmount(a, b),
          HoldingSortMode.category => _byCategory(a, b),
        });
    return sorted;
  }

  static int _byAmount(AssetHolding a, AssetHolding b) {
    final byAmount = b.effectiveValue.compareTo(a.effectiveValue);
    return byAmount != 0 ? byAmount : _byName(a, b);
  }

  static int _byCategory(AssetHolding a, AssetHolding b) {
    final byCategory = _categoryRank(a).compareTo(_categoryRank(b));
    if (byCategory != 0) return byCategory;
    // 未知品类之间按 id 固定顺序，避免顺序随输入抖动。
    final byId = a.categoryId.compareTo(b.categoryId);
    if (byId != 0) return byId;
    return _byAmount(a, b);
  }

  static int _categoryRank(AssetHolding holding) {
    final index = categoryOrder.indexOf(holding.categoryId);
    return index >= 0 ? index : categoryOrder.length;
  }

  static int _byName(AssetHolding a, AssetHolding b) {
    final byName = a.name.compareTo(b.name);
    return byName != 0 ? byName : a.id.compareTo(b.id);
  }
}
