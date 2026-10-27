import 'package:drift/drift.dart';

import '../database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.attachedDatabase);

  Stream<List<TransactionRow>> watchForHolding(int holdingId) {
    final query = select(transactions)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch();
  }

  Stream<List<TransactionRow>> watchAll() {
    final query = select(transactions)
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch();
  }

  Future<List<TransactionRow>> getAll() {
    final query = select(transactions)
      ..orderBy([
        (t) => OrderingTerm.asc(t.date),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  Future<List<TransactionRow>> getForHoldingAsc(int holdingId) {
    final query = select(transactions)
      ..where((t) => t.holdingId.equals(holdingId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.date),
        (t) => OrderingTerm.asc(t.id),
      ]);
    return query.get();
  }

  Future<TransactionRow?> getById(int id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertTransaction(TransactionsCompanion companion) =>
      into(transactions).insert(companion);

  Future<int> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<void> deleteForHolding(int holdingId) async {
    await (delete(transactions)..where((t) => t.holdingId.equals(holdingId)))
        .go();
  }

  Future<int> deleteAll() => delete(transactions).go();
}
