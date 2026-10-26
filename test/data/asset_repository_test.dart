import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';

void main() {
  late AppDatabase database;
  late AssetRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AssetRepositoryImpl(database);
  });

  tearDown(() => database.close());

  test('首次建库写入内置品类', () async {
    final categories = await repository.getCategories();
    final ids = categories.map((category) => category.id).toList();

    expect(ids, containsAll(['cash', 'bond', 'fund', 'stock', 'etf', 'gold']));
    expect(ids, hasLength(6));
    expect(
      categories.firstWhere((category) => category.id == 'gold').displayName,
      '贵金属',
    );
  });

  test('新增、更新价格、删除持仓', () async {
    final id = await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '测试基金',
        code: '000001',
        quantity: Decimal.parse('100'),
        costPrice: Decimal.parse('10'),
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );

    var holdings = await repository.watchHoldings().first;
    expect(holdings, hasLength(1));
    expect(holdings.first.id, id);
    expect(holdings.first.categoryName, '基金');
    expect(holdings.first.costValue, Decimal.parse('1000'));
    expect(holdings.first.hasCurrentPrice, isFalse);

    await repository.updateCurrentPrice(id, Decimal.parse('12.5'));
    holdings = await repository.watchHoldings().first;
    expect(holdings.first.currentPrice, Decimal.parse('12.5'));
    expect(holdings.first.currentValue, Decimal.parse('1250'));

    await repository.updateHolding(
      id,
      AssetHoldingDraft(
        categoryId: 'stock',
        name: '改名后的资产',
        quantity: Decimal.parse('200'),
        costPrice: Decimal.parse('5'),
        currentPrice: Decimal.parse('6'),
        purchaseDate: DateTime(2025, 2, 1),
        notes: '变更测试',
      ),
    );
    holdings = await repository.watchHoldings().first;
    expect(holdings.first.name, '改名后的资产');
    expect(holdings.first.categoryId, 'stock');
    expect(holdings.first.notes, '变更测试');

    await repository.deleteHolding(id);
    expect(await repository.watchHoldings().first, isEmpty);
  });

  test('清空数据保留品类字典', () async {
    await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '现金',
        quantity: Decimal.parse('1000'),
        costPrice: Decimal.one,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );

    await repository.clearAllData();

    expect(await repository.watchHoldings().first, isEmpty);
    expect(await repository.getCategories(), hasLength(6));
  });
}
