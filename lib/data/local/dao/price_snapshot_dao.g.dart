// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_snapshot_dao.dart';

// ignore_for_file: type=lint
mixin _$PriceSnapshotDaoMixin on DatabaseAccessor<AppDatabase> {
  $PriceSnapshotsTable get priceSnapshots => attachedDatabase.priceSnapshots;
  PriceSnapshotDaoManager get managers => PriceSnapshotDaoManager(this);
}

class PriceSnapshotDaoManager {
  final _$PriceSnapshotDaoMixin _db;
  PriceSnapshotDaoManager(this._db);
  $$PriceSnapshotsTableTableManager get priceSnapshots =>
      $$PriceSnapshotsTableTableManager(
        _db.attachedDatabase,
        _db.priceSnapshots,
      );
}
