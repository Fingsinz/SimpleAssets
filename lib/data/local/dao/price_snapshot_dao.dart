import 'package:drift/drift.dart';

import '../database.dart';

part 'price_snapshot_dao.g.dart';

@DriftAccessor(tables: [PriceSnapshots])
class PriceSnapshotDao extends DatabaseAccessor<AppDatabase>
    with _$PriceSnapshotDaoMixin {
  PriceSnapshotDao(super.attachedDatabase);

  Future<int> addSnapshot({
    required String code,
    required String source,
    required String price,
    String currency = 'CNY',
  }) {
    return into(priceSnapshots).insert(
      PriceSnapshotsCompanion.insert(
        code: code,
        source: source,
        price: price,
        currency: Value(currency),
      ),
    );
  }

  Future<PriceSnapshotRow?> latestForCode(String code) {
    final query = select(priceSnapshots)
      ..where((t) => t.code.equals(code))
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<int> deleteAll() => delete(priceSnapshots).go();
}
