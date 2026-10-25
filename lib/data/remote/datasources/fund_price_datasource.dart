import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import '../../../core/result.dart';
import 'abstract_price_datasource.dart';

/// 开放式基金最新净值。
///
/// 原天天基金 `fundgz` 估值接口已失效，改为：
/// 1. 东方财富历史净值接口（JSON，最新公布净值）
/// 2. 新浪基金接口作为兜底
class FundPriceDataSource implements AbstractPriceDataSource {
  final Dio _dio;

  FundPriceDataSource(this._dio);

  @override
  String get sourceName => '天天基金';

  @override
  List<String> supportedCategories() => const ['fund'];

  @override
  Future<Result<Decimal>> fetchPrice(String code) async {
    final normalized = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(normalized)) {
      return Result.failure('基金代码应为 6 位数字：$code');
    }

    final eastmoney = await _fetchFromEastmoney(normalized);
    if (eastmoney.isSuccess) return eastmoney;

    final sina = await _fetchFromSina(normalized);
    if (sina.isSuccess) return sina;

    return Result.failure(
      '未获取到基金 $normalized 的净值（${eastmoney.error}）',
    );
  }

  Future<Result<Decimal>> _fetchFromEastmoney(String code) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.fund.eastmoney.com/f10/lsjz',
        queryParameters: {
          'fundCode': code,
          'pageIndex': 1,
          'pageSize': 1,
        },
        options: Options(
          headers: {'Referer': 'http://fundf10.eastmoney.com/'},
        ),
      );

      final data = response.data?['Data'];
      if (data is Map<String, dynamic>) {
        final list = data['LSJZList'];
        if (list is List && list.isNotEmpty) {
          final first = list.first;
          if (first is Map<String, dynamic>) {
            final price = Decimal.tryParse(first['DWJZ']?.toString() ?? '');
            if (price != null && price > Decimal.zero) {
              return Result.success(price);
            }
          }
        }
      }
      return Result.failure('东方财富未返回净值数据');
    } on DioException catch (e) {
      return Result.failure('基金净值请求失败：${_dioMessage(e)}');
    } catch (e) {
      return Result.failure('基金净值解析失败：$e');
    }
  }

  Future<Result<Decimal>> _fetchFromSina(String code) async {
    try {
      final response = await _dio.get<List<int>>(
        'https://hq.sinajs.cn/list=f_$code',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Referer': 'https://finance.sina.com.cn/'},
        ),
      );
      final body = latin1.decode(response.data ?? const []);
      final match = RegExp(r'"([^"]*)"').firstMatch(body);
      final content = match?.group(1) ?? '';
      if (content.isEmpty) {
        return Result.failure('新浪未返回基金净值');
      }
      final fields = content.split(',');
      if (fields.length > 1) {
        final price = Decimal.tryParse(fields[1]);
        if (price != null && price > Decimal.zero) {
          return Result.success(price);
        }
      }
      return Result.failure('新浪基金净值格式异常');
    } on DioException catch (e) {
      return Result.failure('新浪基金请求失败：${_dioMessage(e)}');
    } catch (e) {
      return Result.failure('新浪基金解析失败：$e');
    }
  }

  String _dioMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return '网络超时';
      case DioExceptionType.badResponse:
        return 'HTTP ${e.response?.statusCode}';
      default:
        return e.message ?? '网络异常';
    }
  }
}
