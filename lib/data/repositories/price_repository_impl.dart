import 'package:decimal/decimal.dart';

import '../../core/result.dart';
import '../../domain/entities/asset_holding.dart';
import '../../domain/repositories/price_repository.dart';
import '../remote/datasources/price_datasource_registry.dart';

class PriceRepositoryImpl implements PriceRepository {
  final PriceDataSourceRegistry registry;
  final Future<void> Function(Map<int, Decimal> prices) onPricesFetched;

  PriceRepositoryImpl({
    required this.registry,
    required this.onPricesFetched,
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
    final fetched = <int, Decimal>{};

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

      fetched[holding.id] = result.data!;
    }

    // 所有价格一次事务写入，避免逐条写库触发 N 次列表重建。
    if (fetched.isNotEmpty) {
      try {
        await onPricesFetched(fetched);
        updated += fetched.length;
      } catch (e) {
        failed += fetched.length;
        errors.add('保存价格失败 ($e)');
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
