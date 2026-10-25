import 'package:decimal/decimal.dart';

import '../../../core/result.dart';

/// 价格数据源抽象。新增数据源只需实现本接口并注册，不修改既有代码。
abstract class AbstractPriceDataSource {
  /// 数据源名称，用于记录价格快照。
  String get sourceName;

  /// 支持的品类 ID。
  List<String> supportedCategories();

  Future<Result<Decimal>> fetchPrice(String code);
}
