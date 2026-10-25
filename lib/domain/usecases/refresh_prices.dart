import '../entities/asset_holding.dart';
import '../repositories/price_repository.dart';

/// 批量刷新持仓现价。
class RefreshPrices {
  final PriceRepository repository;

  const RefreshPrices(this.repository);

  Future<PriceRefreshReport> call(List<AssetHolding> holdings) =>
      repository.refreshAll(holdings);
}
