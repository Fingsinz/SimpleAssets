import 'package:decimal/decimal.dart';

import '../../core/result.dart';
import '../entities/asset_holding.dart';

/// 价格仓库：负责拉取实时价格并回写持仓。
abstract class PriceRepository {
  Future<Result<Decimal>> fetchPrice({
    required String categoryId,
    required String code,
  });

  Future<PriceRefreshReport> refreshAll(List<AssetHolding> holdings);
}

/// 一次批量刷新价格的结果。
class PriceRefreshReport {
  final int updated;
  final int failed;
  final int skipped;
  final List<String> errors;

  const PriceRefreshReport({
    this.updated = 0,
    this.failed = 0,
    this.skipped = 0,
    this.errors = const [],
  });

  bool get hasFailures => failed > 0;

  bool get isEmpty => updated == 0 && failed == 0 && skipped == 0;

  String get message {
    if (updated == 0 && failed == 0) {
      return skipped > 0 ? '没有可自动更新价格的资产' : '暂无持仓';
    }
    final buffer = StringBuffer('已更新 $updated 项');
    if (failed > 0) buffer.write('，$failed 项失败');
    if (skipped > 0) buffer.write('，$skipped 项跳过');
    return buffer.toString();
  }
}
