import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/local/database.dart';
import 'package:simple_assets/data/repositories/asset_repository_impl.dart';
import 'package:simple_assets/domain/entities/asset_holding_draft.dart';
import 'package:simple_assets/domain/entities/cash_record.dart';
import 'package:simple_assets/domain/usecases/build_performance.dart';
import 'package:simple_assets/domain/usecases/valuate_portfolio.dart';

void main() {
  late AppDatabase database;
  late AssetRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AssetRepositoryImpl(database);
  });

  tearDown(() => database.close());

  Future<int> seedHolding() => repository.addHolding(
    AssetHoldingDraft(
      categoryId: 'fund',
      name: '测试基金',
      code: '000001',
      quantity: Decimal.parse('100'),
      costPrice: Decimal.parse('10'),
      purchaseDate: DateTime(2026, 1, 5),
    ),
  );

  test('补录月末价格写入该月最后一天', () async {
    final id = await seedHolding();

    await repository.saveMonthEndPrice(
      id,
      DateTime(2026, 2),
      Decimal.parse('12'),
    );

    final rows = await database.priceHistoryDao.getForHolding(id);
    expect(rows, hasLength(1));
    expect(rows.single.period, '2026-02');
    expect(rows.single.price, '12');
    expect(rows.single.observedAt, DateTime(2026, 2, 28));
  });

  test('闰年二月取 29 日', () async {
    final id = await seedHolding();

    await repository.saveMonthEndPrice(
      id,
      DateTime(2024, 2),
      Decimal.parse('9.5'),
    );

    final rows = await database.priceHistoryDao.getForHolding(id);
    expect(rows.single.observedAt, DateTime(2024, 2, 29));
  });

  test('同月重复补录覆盖已有价格', () async {
    final id = await seedHolding();

    await repository.saveMonthEndPrice(
      id,
      DateTime(2026, 2),
      Decimal.parse('12'),
    );
    await repository.saveMonthEndPrice(
      id,
      DateTime(2026, 2),
      Decimal.parse('12.6'),
    );

    final rows = await database.priceHistoryDao.getForHolding(id);
    expect(rows, hasLength(1));
    expect(rows.single.price, '12.6');
  });

  test('拒绝补录当月与未来月份', () async {
    final id = await seedHolding();
    final now = DateTime.now();

    expect(
      () => repository.saveMonthEndPrice(id, now, Decimal.parse('1')),
      throwsArgumentError,
    );
    expect(
      () => repository.saveMonthEndPrice(
        id,
        DateTime(now.year, now.month + 1),
        Decimal.parse('1'),
      ),
      throwsArgumentError,
    );
  });

  test('补录的月末价格参与收益分析', () async {
    final id = await seedHolding();
    await repository.saveMonthEndPrice(
      id,
      DateTime(2026, 1),
      Decimal.parse('10'),
    );
    await repository.saveMonthEndPrice(
      id,
      DateTime(2026, 2),
      Decimal.parse('12'),
    );

    final holding = (await repository.getHoldings()).single;
    final result = BuildPerformance.build(
      holdings: [
        HoldingPerformanceInput(
          holding: holding,
          transactions: await repository.getTransactions(id),
        ),
      ],
      priceHistory: await repository.getAllPriceHistory(),
      cashRecords: const <CashRecord>[],
      includeCash: false,
      today: DateTime(2026, 3, 15),
    );

    final february = result.months.firstWhere(
      (month) => month.key == '2026-02',
    );
    expect(february.directReturnRate, closeTo(20, 0.0001));
  });
}
