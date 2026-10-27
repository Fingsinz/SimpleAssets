// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_history_dao.dart';

// ignore_for_file: type=lint
mixin _$PriceHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $AssetCategoriesTable get assetCategories => attachedDatabase.assetCategories;
  $AssetHoldingsTable get assetHoldings => attachedDatabase.assetHoldings;
  $PriceHistoryTable get priceHistory => attachedDatabase.priceHistory;
  PriceHistoryDaoManager get managers => PriceHistoryDaoManager(this);
}

class PriceHistoryDaoManager {
  final _$PriceHistoryDaoMixin _db;
  PriceHistoryDaoManager(this._db);
  $$AssetCategoriesTableTableManager get assetCategories =>
      $$AssetCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.assetCategories,
      );
  $$AssetHoldingsTableTableManager get assetHoldings =>
      $$AssetHoldingsTableTableManager(_db.attachedDatabase, _db.assetHoldings);
  $$PriceHistoryTableTableManager get priceHistory =>
      $$PriceHistoryTableTableManager(_db.attachedDatabase, _db.priceHistory);
}
