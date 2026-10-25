import 'package:decimal/decimal.dart';

import '../entities/asset_category.dart';
import '../entities/asset_holding.dart';
import '../entities/asset_holding_draft.dart';

/// 持仓数据仓库抽象。表现层只依赖此接口。
abstract class AssetRepository {
  Stream<List<AssetHolding>> watchHoldings();

  Stream<List<AssetCategory>> watchCategories();

  Future<List<AssetCategory>> getCategories();

  Future<AssetHolding?> getHoldingById(int id);

  Future<int> addHolding(AssetHoldingDraft draft);

  Future<void> updateHolding(int id, AssetHoldingDraft draft);

  Future<void> deleteHolding(int id);

  Future<void> updateCurrentPrice(int id, Decimal price);

  /// 清空持仓、交易与价格快照，保留品类字典。
  Future<void> clearAllData();
}
