import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import '../../../core/result.dart';
import 'abstract_price_datasource.dart';

/// 黄金价格数据源（Au99.99，元/克）。
///
/// 优先使用上海黄金交易所官方行情接口，失败时降级到新浪财经。
class GoldPriceDataSource implements AbstractPriceDataSource {
  final Dio _dio;

  GoldPriceDataSource(this._dio);

  @override
  String get sourceName => '上海黄金交易所';

  @override
  List<String> supportedCategories() => const ['gold'];

  @override
  Future<Result<Decimal>> fetchPrice(String code) async {
    final sge = await _fetchFromSge();
    if (sge.isSuccess) return sge;

    final sina = await _fetchFromSina();
    if (sina.isSuccess) return sina;

    return Result.failure('暂未获取到黄金实时价格，请手动填写现价');
  }

  Future<Result<Decimal>> _fetchFromSge() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://www.sge.com.cn/graph/quotations',
        data: {'instid': 'Au99.99'},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Referer': 'https://www.sge.com.cn/',
            'Origin': 'https://www.sge.com.cn',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );
      final data = response.data?['data'];
      if (data is List && data.isNotEmpty) {
        // data 是按分钟排列的现价序列，取最新的一个有效值。
        for (var i = data.length - 1; i >= 0; i--) {
          final price = Decimal.tryParse(data[i].toString());
          if (price != null && price > Decimal.zero) {
            return Result.success(price);
          }
        }
      }
      return Result.failure('上金所未返回有效价格');
    } on DioException catch (e) {
      return Result.failure('上金所请求失败：${e.message ?? '网络异常'}');
    } catch (e) {
      return Result.failure('上金所行情解析失败：$e');
    }
  }

  Future<Result<Decimal>> _fetchFromSina() async {
    try {
      final response = await _dio.get<List<int>>(
        'https://hq.sinajs.cn/list=SGE_AU9999',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Referer': 'https://finance.sina.com.cn/'},
        ),
      );
      final body = latin1.decode(response.data ?? const []);
      final match = RegExp(r'"([^"]*)"').firstMatch(body);
      final content = match?.group(1) ?? '';
      if (content.isEmpty) {
        return Result.failure('新浪未返回黄金行情');
      }
      final fields = content.split(',');
      if (fields.length > 3) {
        final price = Decimal.tryParse(fields[3]);
        if (price != null && price > Decimal.zero) {
          return Result.success(price);
        }
      }
      return Result.failure('新浪黄金行情格式异常');
    } on DioException catch (e) {
      return Result.failure('新浪黄金请求失败：${e.message ?? '网络异常'}');
    } catch (e) {
      return Result.failure('新浪黄金解析失败：$e');
    }
  }
}
