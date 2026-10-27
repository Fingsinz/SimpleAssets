import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/data/local/database.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.assetDao.insertHolding(
      AssetHoldingsCompanion.insert(
        categoryId: 'fund',
        name: '测试基金',
        quantity: '0',
        costPrice: '0',
        purchaseDate: DateTime(2026, 1, 1),
      ),
    );
  });

  tearDown(() => database.close());

  test('同月多次 upsert 只保留一行且覆盖价格', () async {
    final dao = database.priceHistoryDao;
    await dao.upsertMonth(
      holdingId: 1,
      period: '2026-10',
      price: '1.0',
      observedAt: DateTime(2026, 10, 3),
    );
    await dao.upsertMonth(
      holdingId: 1,
      period: '2026-10',
      price: '1.2',
      observedAt: DateTime(2026, 10, 28),
    );

    final rows = await dao.getForHolding(1);
    expect(rows, hasLength(1));
    expect(rows.single.price, '1.2');
    expect(rows.single.observedAt, DateTime(2026, 10, 28));
  });

  test('不同月份各保留一行', () async {
    final dao = database.priceHistoryDao;
    await dao.upsertMonth(holdingId: 1, period: '2026-09', price: '1.0');
    await dao.upsertMonth(holdingId: 1, period: '2026-10', price: '1.2');

    final rows = await dao.getForHolding(1);
    expect(rows, hasLength(2));
    expect(rows.map((row) => row.period), ['2026-09', '2026-10']);
  });
}
