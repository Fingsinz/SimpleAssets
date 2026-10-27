import 'package:decimal/decimal.dart';

import '../../core/result.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/repositories/price_repository.dart';
import '../remote/datasources/price_datasource_registry.dart';

class PriceRepositoryImpl implements PriceRepository {
  final PriceDataSourceRegistry registry;
  final Future<void> Function(int id, Decimal price) onPriceFetched;

  PriceRepositoryImpl({
    required this.registry,
    required this.onPriceFetched,
  });

  @override
  Future<Result<Decimal>> fetchPrice({
    required String categoryId,
    required String code,
  }) =>
      registry.fetchPrice(categoryId, code);

  @override
  Future<PriceRefreshReport> refreshAll(List<AssetHolding> holdings) async {
    var updated = 0;
    var failed = 0;
    var skipped = 0;
    final errors = <String>[];

    for (final holding in holdings) {
      final code = holding.code?.trim();
      final source = registry.findForCategory(holding.categoryId);
      if (code == null || code.isEmpty) {
        skipped++;
        continue;
      }
      if (source == null) {
        skipped++;
        continue;
      }

      final result = await registry.fetchPrice(holding.categoryId, code);
      if (result.isFailure) {
        failed++;
        errors.add('${holding.name}: ${result.error}');
        continue;
      }

      final price = result.data!;
      try {
        await onPriceFetched(holding.id, price);
        updated++;
      } catch (e) {
        failed++;
        errors.add('${holding.name}: 保存价格失败 ($e)');
      }
    }

    return PriceRefreshReport(
      updated: updated,
      failed: failed,
      skipped: skipped,
      errors: errors,
    );
  }
}
