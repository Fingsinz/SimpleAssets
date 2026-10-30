import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/domain/entities/asset_transaction.dart';
import 'package:simple_assets/domain/entities/asset_transaction_draft.dart';
import 'package:simple_assets/domain/usecases/replay_transactions.dart';

String _monthKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}';

void main() {
  late AppDatabase database;
  late AssetRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AssetRepositoryImpl(database);
  });

  tearDown(() => database.close());

  Future<int> createFund({
    String quantity = '100',
    String costPrice = '10',
    String fee = '0',
  }) {
    return repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '测试基金',
        quantity: Decimal.parse(quantity),
        costPrice: Decimal.parse(costPrice),
        fee: Decimal.parse(fee),
        purchaseDate: DateTime(2026, 1, 1),
      ),
    );
  }

  test('新增持仓同时写入首笔买入', () async {
    final id = await createFund(fee: '2');

    final txns = await repository.getTransactions(id);
    expect(txns, hasLength(1));
    expect(txns.single.type, TransactionType.buy);
    expect(txns.single.fee, Decimal.parse('2'));

    final holding = (await repository.getHoldings()).single;
    expect(holding.quantity, Decimal.parse('100'));
    expect(holding.costPrice, Decimal.parse('10.02'));
    expect(holding.totalBuy, Decimal.parse('1002'));
  });

  test('加仓、卖出、分红与折算后缓存同步', () async {
    final id = await createFund();

    await repository.addTransaction(
      AssetTransactionDraft(
        holdingId: id,
        type: TransactionType.buy,
        quantity: Decimal.parse('100'),
        price: Decimal.parse('20'),
        date: DateTime(2026, 1, 2),
      ),
    );
    await repository.addTransaction(
      AssetTransactionDraft(
        holdingId: id,
        type: TransactionType.sell,
        quantity: Decimal.parse('40'),
        price: Decimal.parse('12'),
        date: DateTime(2026, 1, 3),
      ),
    );
    await repository.addTransaction(
      AssetTransactionDraft(
        holdingId: id,
        type: TransactionType.dividend,
        amount: Decimal.parse('50'),
        date: DateTime(2026, 1, 4),
      ),
    );
    await repository.addTransaction(
      AssetTransactionDraft(
        holdingId: id,
        type: TransactionType.split,
        ratio: Decimal.parse('2'),
        date: DateTime(2026, 1, 5),
      ),
    );

    final holding = (await repository.getHoldings()).single;
    expect(holding.quantity, Decimal.parse('320'));
    expect(holding.costPrice, Decimal.parse('7.875'));
    expect(holding.totalBuy, Decimal.parse('3000'));
    expect(holding.totalSell, Decimal.parse('480'));
    expect(holding.totalDividends, Decimal.parse('50'));
    expect(holding.realizedProfit, Decimal.parse('-120'));

    // 缓存同步的是摊薄成本单价：(3000 − 480) / 320。
    final cached = await database.assetDao.getHoldingById(id);
    expect(cached!.holding.costPrice, '7.875');
  });

  test('卖出超过持有会抛错且不写入', () async {
    final id = await createFund();

    await expectLater(
      repository.addTransaction(
        AssetTransactionDraft(
          holdingId: id,
          type: TransactionType.sell,
          quantity: Decimal.parse('999'),
          price: Decimal.parse('12'),
          date: DateTime(2026, 1, 2),
        ),
      ),
      throwsA(isA<TransactionValidationException>()),
    );

    expect(
      (await repository.getHoldings()).single.quantity,
      Decimal.parse('100'),
    );
    expect(await repository.getTransactions(id), hasLength(1));
  });

  test('修改历史流水导致超卖会回滚', () async {
    final id = await createFund();
    await repository.addTransaction(
      AssetTransactionDraft(
        holdingId: id,
        type: TransactionType.sell,
        quantity: Decimal.parse('100'),
        price: Decimal.parse('12'),
        date: DateTime(2026, 1, 2),
      ),
    );
    final buy = (await repository.getTransactions(id))
        .firstWhere((txn) => txn.type == TransactionType.buy);

    await expectLater(
      repository.updateTransaction(
        buy.id,
        AssetTransactionDraft(
          holdingId: id,
          type: TransactionType.buy,
          quantity: Decimal.parse('50'),
          price: Decimal.parse('10'),
          date: buy.date,
        ),
      ),
      throwsA(isA<TransactionValidationException>()),
    );

    final after = await repository.getTransactions(id);
    expect(
      after.firstWhere((txn) => txn.id == buy.id).quantity,
      Decimal.parse('100'),
    );
    expect((await repository.getHoldings()).single.quantity, Decimal.zero);
  });

  test('更新现价写入当月价格历史', () async {
    final id = await createFund();

    await repository.updateCurrentPrice(id, Decimal.parse('12'));

    final points = await repository.getPriceHistory(id);
    expect(points, hasLength(1));
    expect(points.single.price, Decimal.parse('12'));
    expect(points.single.period, _monthKey(DateTime.now()));
  });

  test('删除持仓级联删除流水与价格历史', () async {
    final id = await createFund();
    await repository.updateCurrentPrice(id, Decimal.parse('12'));

    await repository.deleteHolding(id);

    expect(await database.transactionDao.getAll(), isEmpty);
    expect(await database.priceHistoryDao.getAll(), isEmpty);
  });

  test('零成本期初流水可以只改日期', () async {
    final id = await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'fund',
        name: '零成本',
        quantity: Decimal.parse('100'),
        costPrice: Decimal.zero,
        purchaseDate: DateTime(2026, 1, 1),
      ),
    );
    final buy = (await repository.getTransactions(id)).single;

    await repository.updateTransaction(
      buy.id,
      AssetTransactionDraft(
        holdingId: id,
        type: TransactionType.buy,
        quantity: Decimal.parse('100'),
        price: Decimal.zero,
        date: DateTime(2026, 1, 5),
        notes: '修正日期',
      ),
    );

    final updated = (await repository.getTransactions(id)).single;
    expect(updated.notes, '修正日期');
    expect(updated.price, Decimal.zero);
    expect((await repository.getHoldings()).single.quantity, Decimal.parse('100'));
  });

  test('贵金属单位保持为纯标签', () async {
    final id = await repository.addHolding(
      AssetHoldingDraft(
        categoryId: 'gold',
        name: '黄金',
        unit: '克',
        quantity: Decimal.parse('10'),
        costPrice: Decimal.parse('600'),
        purchaseDate: DateTime(2026, 1, 1),
      ),
    );

    final holding = (await repository.getHoldings()).single;
    expect(holding.unit, '克');
    expect(holding.quantity, Decimal.parse('10'));
    expect(await repository.getTransactions(id), hasLength(1));
  });

  test('全部流水流按初始化数据返回', () async {
    final id = await createFund();
    await repository.addTransaction(
      AssetTransactionDraft(
        holdingId: id,
        type: TransactionType.buy,
        quantity: Decimal.parse('50'),
        price: Decimal.parse('20'),
        date: DateTime(2026, 1, 2),
      ),
    );

    final all = await repository.watchAllTransactions().first;
    expect(all, hasLength(2));
    expect(all.map((txn) => txn.type), containsAll([
      TransactionType.buy,
    ]));
  });
}
