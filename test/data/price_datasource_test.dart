import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/remote/datasources/fund_price_datasource.dart';
import 'package:simple_assets/data/remote/datasources/stock_price_datasource.dart';

class _FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(ResponseBody Function(RequestOptions options) handler) {
  final dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent': 'test-agent',
      },
    ),
  );
  dio.httpClientAdapter = _FakeAdapter(handler);
  return dio;
}

ResponseBody _json(Object data) => ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );

ResponseBody _bytes(String body) => ResponseBody.fromBytes(
      utf8.encode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/javascript; charset=GBK'],
      },
    );

void main() {
  group('FundPriceDataSource', () {
    test('解析东方财富最新净值', () async {
      final dio = _dioWith(
        (options) => _json({
          'Data': {
            'LSJZList': [
              {'FSRQ': '2026-10-23', 'DWJZ': '1.0460'},
            ],
          },
          'ErrCode': 0,
        }),
      );
      final result = await FundPriceDataSource(dio).fetchPrice('000001');

      expect(result.isSuccess, isTrue);
      expect(result.data, Decimal.parse('1.0460'));
    });

    test('东方财富无数据时降级到新浪基金接口', () async {
      final dio = _dioWith((options) {
        if (options.uri.host.contains('eastmoney')) {
          return _json({'Data': null, 'ErrCode': 500});
        }
        return _bytes('var hq_str_f_000001="fund,1.234,2.345,1.2,2026-10-23";');
      });

      final result = await FundPriceDataSource(dio).fetchPrice('000001');

      expect(result.isSuccess, isTrue);
      expect(result.data, Decimal.parse('1.234'));
    });

    test('非法基金代码直接返回失败', () async {
      final dio = _dioWith((options) => _bytes(''));
      final result = await FundPriceDataSource(dio).fetchPrice('abc');

      expect(result.isFailure, isTrue);
      expect(result.error, contains('6 位数字'));
    });
  });

  group('StockPriceDataSource', () {
    test('解析新浪股票当前价并补全 sh 前缀', () async {
      late RequestOptions captured;
      final dio = _dioWith((options) {
        captured = options;
        return _bytes(
          'var hq_str_sh600519="Moutai,1311.840,1318.490,1335.000,'
          '1343.880,1310.000,2026-10-23,15:34:59";',
        );
      });

      final result = await StockPriceDataSource(dio).fetchPrice('600519');

      expect(captured.uri.toString(), contains('list=sh600519'));
      expect(result.isSuccess, isTrue);
      expect(result.data, Decimal.parse('1335.000'));
    });

    test('ETF 代码自动使用 sz 前缀', () async {
      late RequestOptions captured;
      final dio = _dioWith((options) {
        captured = options;
        return _bytes('var hq_str_sz159915="ETF,1.0,1.1,2.345,2.4,1.0";');
      });

      final result = await StockPriceDataSource(dio).fetchPrice('159915');

      expect(captured.uri.toString(), contains('list=sz159915'));
      expect(result.data, Decimal.parse('2.345'));
    });

    test('空行情返回失败', () async {
      final dio = _dioWith((options) => _bytes('var hq_str_sh600519="";'));
      final result = await StockPriceDataSource(dio).fetchPrice('600519');

      expect(result.isFailure, isTrue);
    });
  });

}
