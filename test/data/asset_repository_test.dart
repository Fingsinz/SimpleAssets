import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/entities/asset_transaction_draft.dart';

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
    // 派生字段来自流水，编辑表单里的数量 / 成本 / 日期不应覆盖缓存。
    expect(holdings.first.quantity, Decimal.parse('100'));
    expect(holdings.first.costPrice, Decimal.parse('10'));
    expect(holdings.first.purchaseDate, DateTime(2025, 1, 1));

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

  Future<int> createCash({
    String name = '招商银行',
    String amount = '5000',
    DateTime? recordDate,
  }) {
    return repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: name,
        amount: Decimal.parse(amount),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: recordDate ?? DateTime(2025, 1, 1),
      ),
    );
  }

  test('现金建仓写入金额与首条记录', () async {
    final id = await createCash();

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('5000'));
    expect(cash.costValue, Decimal.parse('5000'));
    expect(cash.purchaseDate, DateTime(2025, 1, 1));

    final records = await repository.getCashRecords(id);
    expect(records, hasLength(1));
    expect(records.single.amount, Decimal.parse('5000'));
    expect(records.single.recordDate, DateTime(2025, 1, 1));
    expect(await repository.watchCashRecords(id).first, hasLength(1));
  });

  test('新增较新记录后持仓取最新金额', () async {
    final id = await createCash();

    await repository.addCashRecord(id, Decimal.parse('6000'), DateTime(2025, 2, 1));

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('6000'));
    expect(cash.purchaseDate, DateTime(2025, 2, 1));
    expect(await repository.getCashRecords(id), hasLength(2));
  });

  test('新增较旧记录不改变持仓最新值', () async {
    final id = await createCash();
    await repository.addCashRecord(id, Decimal.parse('6000'), DateTime(2025, 2, 1));

    await repository.addCashRecord(id, Decimal.parse('5500'), DateTime(2025, 1, 15));

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('6000'));
    expect(cash.purchaseDate, DateTime(2025, 2, 1));
  });

  test('编辑最新记录后持仓同步', () async {
    final id = await createCash();
    final recordId = (await repository.getCashRecords(id)).single.id;

    await repository.updateCashRecord(
      recordId,
      Decimal.parse('6500'),
      DateTime(2025, 3, 1),
    );

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('6500'));
    expect(cash.purchaseDate, DateTime(2025, 3, 1));
  });

  test('删除非最新记录不改变持仓', () async {
    final id = await createCash();
    await repository.addCashRecord(id, Decimal.parse('6000'), DateTime(2025, 2, 1));
    final older = (await repository.getCashRecords(id))[1];

    await repository.deleteCashRecord(older.id);

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('6000'));
    expect(cash.purchaseDate, DateTime(2025, 2, 1));
    expect(await repository.getCashRecords(id), hasLength(1));
  });

  test('删除最新记录回退到上一条', () async {
    final id = await createCash();
    await repository.addCashRecord(id, Decimal.parse('6000'), DateTime(2025, 2, 1));
    final latest = (await repository.getCashRecords(id)).first;

    await repository.deleteCashRecord(latest.id);

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('5000'));
    expect(cash.purchaseDate, DateTime(2025, 1, 1));
  });

  test('最后一条记录不可删除', () async {
    final id = await createCash();
    final record = (await repository.getCashRecords(id)).single;

    await expectLater(
      repository.deleteCashRecord(record.id),
      throwsStateError,
    );
    expect(await repository.getCashRecords(id), hasLength(1));
  });

  test('删除现金平台级联删除记录', () async {
    final id = await createCash();
    await repository.addCashRecord(id, Decimal.parse('6000'), DateTime(2025, 2, 1));

    await repository.deleteHolding(id);

    expect(await repository.getCashRecords(id), isEmpty);
  });

  test('拆股后只改名称不会写入新的价格观察', () async {
    final id = await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '测试基金',
        quantity: Decimal.parse('100'),
        costPrice: Decimal.parse('10'),
        currentPrice: Decimal.parse('10'),
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );
    // 让最后一次价格观察早于折算日：模拟「上次看价 → 后来发生折算」。
    final pricePeriod =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    await database.priceHistoryDao.upsertMonth(
      holdingId: id,
      period: pricePeriod,
      price: '10',
      observedAt: DateTime(2026, 9, 1),
    );
    await repository.addTransaction(
      AssetTransactionDraft(
        holdingId: id,
        type: TransactionType.split,
        ratio: Decimal.parse('2'),
        date: DateTime(2026, 10, 1),
      ),
    );

    final before = (await repository.getHoldings()).single;
    expect(before.currentPrice, Decimal.parse('5'));
    final rawBefore =
        (await database.assetDao.getHoldingById(id))!.holding.currentPrice;
    expect(rawBefore, '10');
    final pointsBefore = await repository.getPriceHistory(id);
    expect(pointsBefore.single.price, Decimal.parse('10'));

    await repository.updateHolding(
      id,
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '改名后的基金',
        quantity: before.quantity,
        costPrice: before.costPrice,
        currentPrice: before.currentPrice,
        purchaseDate: before.purchaseDate,
      ),
    );

    final rawAfter =
        (await database.assetDao.getHoldingById(id))!.holding.currentPrice;
    expect(rawAfter, '10');
    final pointsAfter = await repository.getPriceHistory(id);
    expect(pointsAfter, hasLength(1));
    expect(pointsAfter.single.price, Decimal.parse('10'));
  });

  test('旧式现金 draft 用 quantity 作为金额', () async {
    final id = await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'cash',
        name: '旧现金',
        quantity: Decimal.parse('5000'),
        costPrice: Decimal.one,
        purchaseDate: DateTime(2025, 1, 1),
      ),
    );

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('5000'));
    expect(cash.costValue, Decimal.parse('5000'));

    final records = await repository.getCashRecords(id);
    expect(records, hasLength(1));
    expect(records.single.amount, Decimal.parse('5000'));
  });
}
