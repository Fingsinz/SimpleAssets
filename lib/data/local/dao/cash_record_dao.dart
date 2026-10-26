import 'package:drift/drift.dart';

import '../database.dart';

part 'cash_record_dao.g.dart';

@DriftAccessor(tables: [CashRecords])
class CashRecordDao extends DatabaseAccessor<AppDatabase>
    with _$CashRecordDaoMixin {
  CashRecordDao(super.attachedDatabase);

  Stream<List<CashRecordRow>> watchForHolding(int holdingId) {
    final query = select(cashRecords)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.recordDate),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch();
  }

  Future<List<CashRecordRow>> getForHolding(int holdingId) {
    final query = select(cashRecords)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.recordDate),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.get();
  }

  Future<List<CashRecordRow>> getAllRecords() {
    final query = select(cashRecords)
      ..orderBy([
        (t) => OrderingTerm.asc(t.holdingId),
        (t) => OrderingTerm.asc(t.recordDate),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  Future<CashRecordRow?> getById(int id) {
    return (select(cashRecords)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<CashRecordRow?> latestForHolding(int holdingId) {
    final query = select(cashRecords)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.recordDate),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<int> countForHolding(int holdingId) async {
    final countExpression = cashRecords.id.count();
    final query = selectOnly(cashRecords)
      ..addColumns([countExpression])
      ..where(cashRecords.holdingId.equals(holdingId));
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<int> insertRecord(CashRecordsCompanion companion) =>
      into(cashRecords).insert(companion);

  Future<void> updateRecord(int id, CashRecordsCompanion companion) async {
    await (update(cashRecords)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteRecord(int id) async {
    await (delete(cashRecords)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteForHolding(int holdingId) async {
    await (delete(cashRecords)..where((t) => t.holdingId.equals(holdingId)))
        .go();
  }
}
