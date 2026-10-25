import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/asset_repository_impl.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/repositories/asset_repository.dart';
import 'database_provider.dart';

final assetRepositoryProvider = Provider<AssetRepository>(
  (ref) => AssetRepositoryImpl(ref.watch(databaseProvider)),
);

/// 响应式持仓列表，数据库变化自动刷新 UI。
final allHoldingsProvider = StreamProvider<List<AssetHolding>>(
  (ref) => ref.watch(assetRepositoryProvider).watchHoldings(),
);

final categoriesProvider = StreamProvider<List<AssetCategory>>(
  (ref) => ref.watch(assetRepositoryProvider).watchCategories(),
);

/// 持仓页的品类筛选 null 表示全部。
final categoryFilterProvider = StateProvider<String?>((ref) => null);

final filteredHoldingsProvider =
    Provider<AsyncValue<List<AssetHolding>>>((ref) {
  final holdings = ref.watch(allHoldingsProvider);
  final filter = ref.watch(categoryFilterProvider);
  return holdings.whenData((list) {
    if (filter == null) return list;
    return list.where((item) => item.categoryId == filter).toList();
  });
});

/// 响应式单笔持仓。列表尚未加载时返回 loading。
final holdingByIdProvider =
    Provider.family<AsyncValue<AssetHolding?>, int>((ref, id) {
  return ref.watch(allHoldingsProvider).whenData((list) {
    for (final holding in list) {
      if (holding.id == id) return holding;
    }
    return null;
  });
});
