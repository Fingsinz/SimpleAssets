import 'package:drift/drift.dart';

import '../database.dart';

part 'price_history_dao.g.dart';

@DriftAccessor(tables: [PriceHistory])
class PriceHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$PriceHistoryDaoMixin {
  PriceHistoryDao(super.attachedDatabase);

  Stream<List<PriceHistoryRow>> watchAll() {
    final query = select(priceHistory)
      ..orderBy([
        (t) => OrderingTerm.asc(t.observedAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch();
  }

  Stream<List<PriceHistoryRow>> watchForHolding(int holdingId) {
    final query = select(priceHistory)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.observedAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch();
  }

  Future<List<PriceHistoryRow>> getAll() {
    final query = select(priceHistory)
      ..orderBy([
        (t) => OrderingTerm.asc(t.observedAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  Future<List<PriceHistoryRow>> getForHolding(int holdingId) {
    final query = select(priceHistory)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.observedAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  Future<PriceHistoryRow?> latestObservedForHolding(int holdingId) {
    final query = select(priceHistory)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.observedAt),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// 同一持仓同一月份只保留一行：存在则覆盖，不存在则插入。
  Future<void> upsertMonth({
    required int holdingId,
    required String period,
    required String price,
    DateTime? observedAt,
    String currency = 'CNY',
  }) async {
    final at = observedAt ?? DateTime.now();
    final existing = await (select(priceHistory)
          ..where(
            (t) => t.holdingId.equals(holdingId) & t.period.equals(period),
          ))
        .getSingleOrNull();

    if (existing == null) {
      await into(priceHistory).insert(
        PriceHistoryCompanion.insert(
          holdingId: holdingId,
          period: period,
          price: price,
          currency: Value(currency),
          observedAt: at,
        ),
      );
      return;
    }

    await (update(priceHistory)..where((t) => t.id.equals(existing.id))).write(
      PriceHistoryCompanion(
        price: Value(price),
        currency: Value(currency),
        observedAt: Value(at),
      ),
    );
  }
}
