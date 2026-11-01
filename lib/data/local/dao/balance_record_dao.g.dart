// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_record_dao.dart';

// ignore_for_file: type=lint
mixin _$BalanceRecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $AssetCategoriesTable get assetCategories => attachedDatabase.assetCategories;
  $AssetHoldingsTable get assetHoldings => attachedDatabase.assetHoldings;
  $BalanceRecordsTable get balanceRecords => attachedDatabase.balanceRecords;
  BalanceRecordDaoManager get managers => BalanceRecordDaoManager(this);
}

class BalanceRecordDaoManager {
  final _$BalanceRecordDaoMixin _db;
  BalanceRecordDaoManager(this._db);
  $$AssetCategoriesTableTableManager get assetCategories =>
      $$AssetCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.assetCategories,
      );
  $$AssetHoldingsTableTableManager get assetHoldings =>
      $$AssetHoldingsTableTableManager(_db.attachedDatabase, _db.assetHoldings);
  $$BalanceRecordsTableTableManager get balanceRecords =>
      $$BalanceRecordsTableTableManager(
        _db.attachedDatabase,
        _db.balanceRecords,
      );
}
