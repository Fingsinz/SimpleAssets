import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/entities/asset_transaction_draft.dart';
import 'package:simple_assets/domain/entities/balance_record.dart';

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

    expect(
      ids,
      containsAll([
        'cash',
        'bond',
        'fund',
        'stock',
        'etf',
        'gold',
        'custom',
        'liability',
      ]),
    );
    expect(ids, hasLength(8));
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
    expect(await repository.getCategories(), hasLength(8));
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

    final records = await repository.getBalanceRecords(id);
    expect(records, hasLength(1));
    expect(records.single.amount, Decimal.parse('5000'));
    expect(records.single.recordDate, DateTime(2025, 1, 1));
    expect(await repository.watchBalanceRecords(id).first, hasLength(1));
  });

  test('新增较新记录后持仓取最新金额', () async {
    final id = await createCash();

    await repository.addBalanceRecord(id, BalanceRecordDraft(amount: Decimal.parse('6000'), recordDate: DateTime(2025, 2, 1)));

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('6000'));
    expect(cash.purchaseDate, DateTime(2025, 2, 1));
    expect(await repository.getBalanceRecords(id), hasLength(2));
  });

  test('新增较旧记录不改变持仓最新值', () async {
    final id = await createCash();
    await repository.addBalanceRecord(id, BalanceRecordDraft(amount: Decimal.parse('6000'), recordDate: DateTime(2025, 2, 1)));

    await repository.addBalanceRecord(id, BalanceRecordDraft(amount: Decimal.parse('5500'), recordDate: DateTime(2025, 1, 15)));

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('6000'));
    expect(cash.purchaseDate, DateTime(2025, 2, 1));
  });

  test('编辑最新记录后持仓同步', () async {
    final id = await createCash();
    final recordId = (await repository.getBalanceRecords(id)).single.id;

    await repository.updateBalanceRecord(
      recordId,
      BalanceRecordDraft(
        amount: Decimal.parse('6500'),
        recordDate: DateTime(2025, 3, 1),
      ),
    );

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('6500'));
    expect(cash.purchaseDate, DateTime(2025, 3, 1));
  });

  test('删除非最新记录不改变持仓', () async {
    final id = await createCash();
    await repository.addBalanceRecord(id, BalanceRecordDraft(amount: Decimal.parse('6000'), recordDate: DateTime(2025, 2, 1)));
    final older = (await repository.getBalanceRecords(id))[1];

    await repository.deleteBalanceRecord(older.id);

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('6000'));
    expect(cash.purchaseDate, DateTime(2025, 2, 1));
    expect(await repository.getBalanceRecords(id), hasLength(1));
  });

  test('删除最新记录回退到上一条', () async {
    final id = await createCash();
    await repository.addBalanceRecord(id, BalanceRecordDraft(amount: Decimal.parse('6000'), recordDate: DateTime(2025, 2, 1)));
    final latest = (await repository.getBalanceRecords(id)).first;

    await repository.deleteBalanceRecord(latest.id);

    final cash = (await repository.watchHoldings().first).single;
    expect(cash.amount, Decimal.parse('5000'));
    expect(cash.purchaseDate, DateTime(2025, 1, 1));
  });

  test('最后一条记录不可删除', () async {
    final id = await createCash();
    final record = (await repository.getBalanceRecords(id)).single;

    await expectLater(
      repository.deleteBalanceRecord(record.id),
      throwsStateError,
    );
    expect(await repository.getBalanceRecords(id), hasLength(1));
  });

  test('删除现金平台级联删除记录', () async {
    final id = await createCash();
    await repository.addBalanceRecord(id, BalanceRecordDraft(amount: Decimal.parse('6000'), recordDate: DateTime(2025, 2, 1)));

    await repository.deleteHolding(id);

    expect(await repository.getBalanceRecords(id), isEmpty);
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

    final records = await repository.getBalanceRecords(id);
    expect(records, hasLength(1));
    expect(records.single.amount, Decimal.parse('5000'));
  });

  Future<int> createLiability({
    String name = '招商银行信用卡',
    String amount = '-3000',
    DateTime? recordDate,
  }) {
    return repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'liability',
        name: name,
        amount: Decimal.parse(amount),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: recordDate ?? DateTime(2025, 1, 1),
      ),
    );
  }

  Future<int> createCustom({
    String name = '某银行理财',
    String amount = '5000',
    String fee = '5',
    DateTime? purchaseDate,
  }) {
    return repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'custom',
        name: name,
        amount: Decimal.parse(amount),
        fee: Decimal.parse(fee),
        quantity: Decimal.zero,
        costPrice: Decimal.zero,
        purchaseDate: purchaseDate ?? DateTime(2025, 1, 1),
      ),
    );
  }

  test('负债按负数金额创建并写入余额记录', () async {
    final id = await createLiability();

    final liability = (await repository.getHoldings()).single;
    expect(liability.isLiability, isTrue);
    expect(liability.effectiveValue, Decimal.parse('-3000'));
    expect(liability.profit, Decimal.zero);
    expect(liability.hasValuation, isFalse);

    final records = await repository.getBalanceRecords(id);
    expect(records, hasLength(1));
    expect(records.single.amount, Decimal.parse('-3000'));
    expect(records.single.flowKind, BalanceFlowKind.none);
  });

  test('负债拒绝非负金额', () async {
    for (final amount in ['3000', '0']) {
      await expectLater(
        () async => createLiability(amount: amount),
        throwsArgumentError,
      );
    }
  });

  test('自定义产品创建写入投入记录并汇总', () async {
    final id = await createCustom();

    final custom = (await repository.getHoldings()).single;
    expect(custom.isCustom, isTrue);
    expect(custom.totalBuy, Decimal.parse('5005'));
    expect(custom.totalFees, Decimal.parse('5'));
    expect(custom.amount, Decimal.parse('5000'));
    expect(custom.profit, Decimal.parse('-5'));

    final records = await repository.getBalanceRecords(id);
    expect(records, hasLength(1));
    expect(records.single.flowKind, BalanceFlowKind.invest);
    expect(records.single.flowAmount, Decimal.parse('5000'));
    expect(records.single.fee, Decimal.parse('5'));
  });

  test('自定义产品追加投入与卖出', () async {
    final id = await createCustom();

    await repository.addBalanceRecord(
      id,
      BalanceRecordDraft(
        amount: Decimal.parse('6300'),
        flowKind: BalanceFlowKind.invest,
        flowAmount: Decimal.parse('1000'),
        recordDate: DateTime(2025, 2, 1),
      ),
    );
    await repository.addBalanceRecord(
      id,
      BalanceRecordDraft(
        amount: Decimal.parse('5600'),
        flowKind: BalanceFlowKind.sell,
        flowAmount: Decimal.parse('500'),
        recordDate: DateTime(2025, 3, 1),
      ),
    );

    final custom = (await repository.getHoldings()).single;
    expect(custom.totalBuy, Decimal.parse('6005'));
    expect(custom.totalSell, Decimal.parse('500'));
    expect(custom.amount, Decimal.parse('5600'));
    expect(custom.profit, Decimal.parse('95'));
    // 首笔买入日期保持不变，不被后续更新覆盖。
    expect(custom.purchaseDate, DateTime(2025, 1, 1));
  });

  test('自定义产品删除最后一条记录后金额归零', () async {
    final id = await createCustom();
    final record = (await repository.getBalanceRecords(id)).single;

    await repository.deleteBalanceRecord(record.id);

    final custom = (await repository.getHoldings()).single;
    expect(custom.amount, Decimal.zero);
    expect(custom.profit, Decimal.zero);
    expect(await repository.getBalanceRecords(id), isEmpty);
  });

  test('现金与负债至少保留一条记录', () async {
    final id = await createLiability();
    final record = (await repository.getBalanceRecords(id)).single;

    await expectLater(
      repository.deleteBalanceRecord(record.id),
      throwsStateError,
    );
    expect(await repository.getBalanceRecords(id), hasLength(1));
  });

  test('负债记录只接受负数并同步最新余额', () async {
    final id = await createLiability();

    await repository.addBalanceRecord(
      id,
      BalanceRecordDraft(
        amount: Decimal.parse('-2500'),
        recordDate: DateTime(2025, 2, 1),
      ),
    );

    final liability = (await repository.getHoldings()).single;
    expect(liability.amount, Decimal.parse('-2500'));
    expect(liability.purchaseDate, DateTime(2025, 2, 1));

    await expectLater(() async {
      await repository.addBalanceRecord(
        id,
        BalanceRecordDraft(
          amount: Decimal.parse('100'),
          recordDate: DateTime(2025, 3, 1),
        ),
      );
    }, throwsArgumentError);
  });

  test('自定义产品拒绝负数金额与非法流水', () async {
    final id = await createCustom();

    await expectLater(() async {
      await repository.addBalanceRecord(
        id,
        BalanceRecordDraft(
          amount: Decimal.parse('-1'),
          recordDate: DateTime(2025, 2, 1),
        ),
      );
    }, throwsArgumentError);
    await expectLater(() async {
      await repository.addBalanceRecord(
        id,
        BalanceRecordDraft(
          amount: Decimal.parse('6000'),
          flowKind: BalanceFlowKind.invest,
          recordDate: DateTime(2025, 2, 1),
        ),
      );
    }, throwsArgumentError);
    await expectLater(() async {
      await repository.addBalanceRecord(
        id,
        BalanceRecordDraft(
          amount: Decimal.parse('6000'),
          flowKind: BalanceFlowKind.sell,
          flowAmount: Decimal.parse('0'),
          recordDate: DateTime(2025, 2, 1),
        ),
      );
    }, throwsArgumentError);
    await expectLater(() async {
      await repository.addBalanceRecord(
        id,
        BalanceRecordDraft(
          amount: Decimal.parse('6000'),
          fee: Decimal.parse('-1'),
          recordDate: DateTime(2025, 2, 1),
        ),
      );
    }, throwsArgumentError);
  });

  test('金额型资产同品类名称唯一', () async {
    await createCash();
    await expectLater(() async {
      await createCash();
    }, throwsArgumentError);

    // 不同品类允许同名。
    await createLiability(name: '招商银行');

    await createCustom(name: '产品A');
    await createCustom(name: '产品B');
    await expectLater(() async {
      await createCustom(name: '产品A');
    }, throwsArgumentError);

    final custom = (await repository.getHoldings())
        .firstWhere((holding) => holding.name == '产品B');
    await expectLater(() async {
      await repository.updateHolding(
        custom.id,
        AssetHoldingDraft(
          categoryId: 'custom',
          name: '产品A',
          amount: Decimal.parse('5000'),
          quantity: Decimal.zero,
          costPrice: Decimal.zero,
          purchaseDate: DateTime(2025, 1, 1),
        ),
      );
    }, throwsArgumentError);
  });

  test('金额型资产不能写入交易流水', () async {
    final id = await createCustom();

    await expectLater(() async {
      await repository.addTransaction(
        AssetTransactionDraft(
          holdingId: id,
          type: TransactionType.buy,
          quantity: Decimal.one,
          price: Decimal.one,
          date: DateTime(2025, 2, 1),
        ),
      );
    }, throwsArgumentError);
  });
}
