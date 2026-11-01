import 'package:drift/drift.dart';

import '../database.dart';

part 'balance_record_dao.g.dart';

@DriftAccessor(tables: [BalanceRecords])
class BalanceRecordDao extends DatabaseAccessor<AppDatabase>
    with _$BalanceRecordDaoMixin {
  BalanceRecordDao(super.attachedDatabase);

  Stream<List<BalanceRecordRow>> watchForHolding(int holdingId) {
    final query = select(balanceRecords)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.recordDate),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch();
  }

  Stream<List<BalanceRecordRow>> watchAllRecords() {
    final query = select(balanceRecords)
      ..orderBy([
        (t) => OrderingTerm.asc(t.holdingId),
        (t) => OrderingTerm.asc(t.recordDate),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.watch();
  }

  Future<List<BalanceRecordRow>> getForHolding(int holdingId) {
    final query = select(balanceRecords)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.recordDate),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.get();
  }

  Future<List<BalanceRecordRow>> getAllRecords() {
    final query = select(balanceRecords)
      ..orderBy([
        (t) => OrderingTerm.asc(t.holdingId),
        (t) => OrderingTerm.asc(t.recordDate),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  Future<BalanceRecordRow?> getById(int id) {
    return (select(balanceRecords)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<BalanceRecordRow?> latestForHolding(int holdingId) {
    final query = select(balanceRecords)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.recordDate),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// 最早一条记录，用于自定义产品保持首笔买入日期。
  Future<BalanceRecordRow?> earliestForHolding(int holdingId) {
    final query = select(balanceRecords)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.recordDate),
        (t) => OrderingTerm.asc(t.id),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<int> countForHolding(int holdingId) async {
    final countExpression = balanceRecords.id.count();
    final query = selectOnly(balanceRecords)
      ..addColumns([countExpression])
      ..where(balanceRecords.holdingId.equals(holdingId));
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<int> insertRecord(BalanceRecordsCompanion companion) =>
      into(balanceRecords).insert(companion);

  Future<void> updateRecord(int id, BalanceRecordsCompanion companion) async {
    await (update(balanceRecords)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteRecord(int id) async {
    await (delete(balanceRecords)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteForHolding(int holdingId) async {
    await (delete(balanceRecords)..where((t) => t.holdingId.equals(holdingId)))
        .go();
  }
}
