import 'package:decimal/decimal.dart';

import '../../../core/result.dart';
import 'abstract_price_datasource.dart';

/// 价格数据源注册中心：根据品类路由到具体数据源。
class PriceDataSourceRegistry {
  final List<AbstractPriceDataSource> sources;

  const PriceDataSourceRegistry(this.sources);

  AbstractPriceDataSource? findForCategory(String categoryId) {
    for (final source in sources) {
      if (source.supportedCategories().contains(categoryId)) {
        return source;
      }
    }
    return null;
  }

  bool supports(String categoryId) => findForCategory(categoryId) != null;

  String? sourceNameFor(String categoryId) =>
      findForCategory(categoryId)?.sourceName;

  Future<Result<Decimal>> fetchPrice(String categoryId, String code) {
    final source = findForCategory(categoryId);
    if (source == null) {
      return Future.value(Result.failure('品类 $categoryId 暂不支持自动更新价格'));
    }
    return source.fetchPrice(code);
  }
}
