// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_record_dao.dart';

// ignore_for_file: type=lint
mixin _$CashRecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $AssetCategoriesTable get assetCategories => attachedDatabase.assetCategories;
  $AssetHoldingsTable get assetHoldings => attachedDatabase.assetHoldings;
  $CashRecordsTable get cashRecords => attachedDatabase.cashRecords;
  CashRecordDaoManager get managers => CashRecordDaoManager(this);
}

class CashRecordDaoManager {
  final _$CashRecordDaoMixin _db;
  CashRecordDaoManager(this._db);
  $$AssetCategoriesTableTableManager get assetCategories =>
      $$AssetCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.assetCategories,
      );
  $$AssetHoldingsTableTableManager get assetHoldings =>
      $$AssetHoldingsTableTableManager(_db.attachedDatabase, _db.assetHoldings);
  $$CashRecordsTableTableManager get cashRecords =>
      $$CashRecordsTableTableManager(_db.attachedDatabase, _db.cashRecords);
}
