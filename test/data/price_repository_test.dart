import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/core/result.dart';
import 'package:simple_assets/data/remote/datasources/abstract_price_datasource.dart';
import 'package:simple_assets/data/remote/datasources/price_datasource_registry.dart';
import 'package:simple_assets/data/repositories/price_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';

class _FakeSource implements AbstractPriceDataSource {
  final Decimal price;

  _FakeSource(this.price);

  @override
  String get sourceName => '测试源';

  @override
  List<String> supportedCategories() => const ['fund'];

  @override
  Future<Result<Decimal>> fetchPrice(String code) async =>
      Result.success(price);
}

PriceDataSourceRegistry _registryReturning(Decimal price) =>
    PriceDataSourceRegistry([_FakeSource(price)]);

AssetHolding _fundHolding({int id = 7, String? code = '000001'}) {
  final now = DateTime(2026, 1, 1);
  return AssetHolding(
    id: id,
    categoryId: 'fund',
    name: '测试基金',
    code: code,
    quantity: Decimal.one,
    costPrice: Decimal.ten,
    purchaseDate: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('刷新成功后调用回调且不再依赖快照 DAO', () async {
    final calls = <int>[];
    final repository = PriceRepositoryImpl(
      registry: _registryReturning(Decimal.parse('12')),
      onPriceFetched: (id, price) async => calls.add(id),
    );

    final report = await repository.refreshAll([_fundHolding(id: 7)]);

    expect(report.updated, 1);
    expect(calls, [7]);
  });

  test('没有代码的持仓计入跳过', () async {
    final calls = <int>[];
    final repository = PriceRepositoryImpl(
      registry: _registryReturning(Decimal.parse('12')),
      onPriceFetched: (id, price) async => calls.add(id),
    );

    final report = await repository.refreshAll([_fundHolding(code: null)]);

    expect(report.skipped, 1);
    expect(calls, isEmpty);
  });
}
