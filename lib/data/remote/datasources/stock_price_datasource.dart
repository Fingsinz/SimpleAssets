import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import '../../../core/result.dart';
import 'abstract_price_datasource.dart';

/// 新浪财经行情接口，支持 A 股与 ETF。
/// 返回格式：var hq_str_sh600519="贵州茅台,开盘,昨收,现价,最高,最低,...";
///
/// 注意：接口返回 GBK 编码，这里按 latin1 解码，价格数字均为 ASCII，不受影响。
class StockPriceDataSource implements AbstractPriceDataSource {
  final Dio _dio;

  StockPriceDataSource(this._dio);

  @override
  String get sourceName => '新浪财经';

  @override
  List<String> supportedCategories() => const ['stock', 'etf'];

  @override
  Future<Result<Decimal>> fetchPrice(String code) async {
    final symbol = _normalizeSymbol(code);
    if (symbol == null) {
      return Result.failure('无法识别股票代码：$code');
    }
    try {
      final response = await _dio.get<List<int>>(
        'https://hq.sinajs.cn/list=$symbol',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Referer': 'https://finance.sina.com.cn'},
        ),
      );
      final body = latin1.decode(response.data ?? const []);
      final match = RegExp(r'"([^"]*)"').firstMatch(body);
      final content = match?.group(1) ?? '';
      if (content.isEmpty) {
        return Result.failure('未获取到 $symbol 的行情');
      }
      final fields = content.split(',');
      if (fields.length <= 3) {
        return Result.failure('$symbol 行情格式异常');
      }
      final price = Decimal.tryParse(fields[3]);
      if (price == null || price <= Decimal.zero) {
        return Result.failure('$symbol 当前价格无效');
      }
      return Result.success(price);
    } on DioException catch (e) {
      return Result.failure('股票价格请求失败：${e.message ?? '网络异常'}');
    } catch (e) {
      return Result.failure('股票价格解析失败：$e');
    }
  }

  /// 支持用户输入 600519 / sh600519 / sz159915 等格式。
  String? _normalizeSymbol(String raw) {
    final code = raw.trim().toLowerCase();
    if (code.isEmpty) return null;
    if (RegExp(r'^(sh|sz|bj)\d{6}$').hasMatch(code)) return code;

    final digits = RegExp(r'^\d{6}$').hasMatch(code) ? code : null;
    if (digits == null) return null;

    final head = digits[0];
    if ('569'.contains(head)) return 'sh$digits';
    if ('0123'.contains(head)) return 'sz$digits';
    if ('48'.contains(head)) return 'bj$digits';
    return 'sh$digits';
  }
}
