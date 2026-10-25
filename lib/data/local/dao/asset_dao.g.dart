// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetDaoMixin on DatabaseAccessor<AppDatabase> {
  $AssetCategoriesTable get assetCategories => attachedDatabase.assetCategories;
  $AssetHoldingsTable get assetHoldings => attachedDatabase.assetHoldings;
  AssetDaoManager get managers => AssetDaoManager(this);
}

class AssetDaoManager {
  final _$AssetDaoMixin _db;
  AssetDaoManager(this._db);
  $$AssetCategoriesTableTableManager get assetCategories =>
      $$AssetCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.assetCategories,
      );
  $$AssetHoldingsTableTableManager get assetHoldings =>
      $$AssetHoldingsTableTableManager(_db.attachedDatabase, _db.assetHoldings);
}
