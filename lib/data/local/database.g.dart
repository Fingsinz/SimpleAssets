// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AssetCategoriesTable extends AssetCategories
    with TableInfo<$AssetCategoriesTable, AssetCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CNY'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, currency, icon, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AssetCategoriesTable createAlias(String alias) {
    return $AssetCategoriesTable(attachedDatabase, alias);
  }
}

class AssetCategoryRow extends DataClass
    implements Insertable<AssetCategoryRow> {
  final String id;
  final String name;
  final String currency;
  final String? icon;
  final int sortOrder;
  const AssetCategoryRow({
    required this.id,
    required this.name,
    required this.currency,
    this.icon,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AssetCategoriesCompanion toCompanion(bool nullToAbsent) {
    return AssetCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      currency: Value(currency),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      sortOrder: Value(sortOrder),
    );
  }

  factory AssetCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      currency: serializer.fromJson<String>(json['currency']),
      icon: serializer.fromJson<String?>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'currency': serializer.toJson<String>(currency),
      'icon': serializer.toJson<String?>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  AssetCategoryRow copyWith({
    String? id,
    String? name,
    String? currency,
    Value<String?> icon = const Value.absent(),
    int? sortOrder,
  }) => AssetCategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    icon: icon.present ? icon.value : this.icon,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  AssetCategoryRow copyWithCompanion(AssetCategoriesCompanion data) {
    return AssetCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      currency: data.currency.present ? data.currency.value : this.currency,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetCategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, currency, icon, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetCategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.currency == this.currency &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder);
}

class AssetCategoriesCompanion extends UpdateCompanion<AssetCategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> currency;
  final Value<String?> icon;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const AssetCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.currency = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetCategoriesCompanion.insert({
    required String id,
    required String name,
    this.currency = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<AssetCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? currency,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (currency != null) 'currency': currency,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? currency,
    Value<String?>? icon,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return AssetCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetHoldingsTable extends AssetHoldings
    with TableInfo<$AssetHoldingsTable, AssetHoldingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetHoldingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset_categories (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<String> costPrice = GeneratedColumn<String>(
    'cost_price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentPriceMeta = const VerificationMeta(
    'currentPrice',
  );
  @override
  late final GeneratedColumn<String> currentPrice = GeneratedColumn<String>(
    'current_price',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    name,
    code,
    unit,
    amount,
    quantity,
    costPrice,
    currentPrice,
    purchaseDate,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_holdings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetHoldingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_costPriceMeta);
    }
    if (data.containsKey('current_price')) {
      context.handle(
        _currentPriceMeta,
        currentPrice.isAcceptableOrUnknown(
          data['current_price']!,
          _currentPriceMeta,
        ),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetHoldingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetHoldingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_price'],
      )!,
      currentPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_price'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AssetHoldingsTable createAlias(String alias) {
    return $AssetHoldingsTable(attachedDatabase, alias);
  }
}

class AssetHoldingRow extends DataClass implements Insertable<AssetHoldingRow> {
  final int id;
  final String categoryId;
  final String name;
  final String? code;

  /// 贵金属持有单位原文，如 `10克`。
  final String? unit;

  /// 现金最新金额。
  final String? amount;
  final String quantity;
  final String costPrice;
  final String? currentPrice;
  final DateTime purchaseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AssetHoldingRow({
    required this.id,
    required this.categoryId,
    required this.name,
    this.code,
    this.unit,
    this.amount,
    required this.quantity,
    required this.costPrice,
    this.currentPrice,
    required this.purchaseDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<String>(amount);
    }
    map['quantity'] = Variable<String>(quantity);
    map['cost_price'] = Variable<String>(costPrice);
    if (!nullToAbsent || currentPrice != null) {
      map['current_price'] = Variable<String>(currentPrice);
    }
    map['purchase_date'] = Variable<DateTime>(purchaseDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AssetHoldingsCompanion toCompanion(bool nullToAbsent) {
    return AssetHoldingsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      quantity: Value(quantity),
      costPrice: Value(costPrice),
      currentPrice: currentPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPrice),
      purchaseDate: Value(purchaseDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AssetHoldingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetHoldingRow(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String?>(json['code']),
      unit: serializer.fromJson<String?>(json['unit']),
      amount: serializer.fromJson<String?>(json['amount']),
      quantity: serializer.fromJson<String>(json['quantity']),
      costPrice: serializer.fromJson<String>(json['costPrice']),
      currentPrice: serializer.fromJson<String?>(json['currentPrice']),
      purchaseDate: serializer.fromJson<DateTime>(json['purchaseDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String?>(code),
      'unit': serializer.toJson<String?>(unit),
      'amount': serializer.toJson<String?>(amount),
      'quantity': serializer.toJson<String>(quantity),
      'costPrice': serializer.toJson<String>(costPrice),
      'currentPrice': serializer.toJson<String?>(currentPrice),
      'purchaseDate': serializer.toJson<DateTime>(purchaseDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AssetHoldingRow copyWith({
    int? id,
    String? categoryId,
    String? name,
    Value<String?> code = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> amount = const Value.absent(),
    String? quantity,
    String? costPrice,
    Value<String?> currentPrice = const Value.absent(),
    DateTime? purchaseDate,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AssetHoldingRow(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    code: code.present ? code.value : this.code,
    unit: unit.present ? unit.value : this.unit,
    amount: amount.present ? amount.value : this.amount,
    quantity: quantity ?? this.quantity,
    costPrice: costPrice ?? this.costPrice,
    currentPrice: currentPrice.present ? currentPrice.value : this.currentPrice,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AssetHoldingRow copyWithCompanion(AssetHoldingsCompanion data) {
    return AssetHoldingRow(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      unit: data.unit.present ? data.unit.value : this.unit,
      amount: data.amount.present ? data.amount.value : this.amount,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      currentPrice: data.currentPrice.present
          ? data.currentPrice.value
          : this.currentPrice,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetHoldingRow(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('unit: $unit, ')
          ..write('amount: $amount, ')
          ..write('quantity: $quantity, ')
          ..write('costPrice: $costPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    name,
    code,
    unit,
    amount,
    quantity,
    costPrice,
    currentPrice,
    purchaseDate,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetHoldingRow &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.code == this.code &&
          other.unit == this.unit &&
          other.amount == this.amount &&
          other.quantity == this.quantity &&
          other.costPrice == this.costPrice &&
          other.currentPrice == this.currentPrice &&
          other.purchaseDate == this.purchaseDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AssetHoldingsCompanion extends UpdateCompanion<AssetHoldingRow> {
  final Value<int> id;
  final Value<String> categoryId;
  final Value<String> name;
  final Value<String?> code;
  final Value<String?> unit;
  final Value<String?> amount;
  final Value<String> quantity;
  final Value<String> costPrice;
  final Value<String?> currentPrice;
  final Value<DateTime> purchaseDate;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AssetHoldingsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.unit = const Value.absent(),
    this.amount = const Value.absent(),
    this.quantity = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AssetHoldingsCompanion.insert({
    this.id = const Value.absent(),
    required String categoryId,
    required String name,
    this.code = const Value.absent(),
    this.unit = const Value.absent(),
    this.amount = const Value.absent(),
    required String quantity,
    required String costPrice,
    this.currentPrice = const Value.absent(),
    required DateTime purchaseDate,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : categoryId = Value(categoryId),
       name = Value(name),
       quantity = Value(quantity),
       costPrice = Value(costPrice),
       purchaseDate = Value(purchaseDate);
  static Insertable<AssetHoldingRow> custom({
    Expression<int>? id,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? unit,
    Expression<String>? amount,
    Expression<String>? quantity,
    Expression<String>? costPrice,
    Expression<String>? currentPrice,
    Expression<DateTime>? purchaseDate,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (unit != null) 'unit': unit,
      if (amount != null) 'amount': amount,
      if (quantity != null) 'quantity': quantity,
      if (costPrice != null) 'cost_price': costPrice,
      if (currentPrice != null) 'current_price': currentPrice,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AssetHoldingsCompanion copyWith({
    Value<int>? id,
    Value<String>? categoryId,
    Value<String>? name,
    Value<String?>? code,
    Value<String?>? unit,
    Value<String?>? amount,
    Value<String>? quantity,
    Value<String>? costPrice,
    Value<String?>? currentPrice,
    Value<DateTime>? purchaseDate,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AssetHoldingsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      code: code ?? this.code,
      unit: unit ?? this.unit,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<String>(costPrice.value);
    }
    if (currentPrice.present) {
      map['current_price'] = Variable<String>(currentPrice.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetHoldingsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('unit: $unit, ')
          ..write('amount: $amount, ')
          ..write('quantity: $quantity, ')
          ..write('costPrice: $costPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _holdingIdMeta = const VerificationMeta(
    'holdingId',
  );
  @override
  late final GeneratedColumn<int> holdingId = GeneratedColumn<int>(
    'holding_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset_holdings (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<String> price = GeneratedColumn<String>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    holdingId,
    type,
    amount,
    price,
    quantity,
    date,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('holding_id')) {
      context.handle(
        _holdingIdMeta,
        holdingId.isAcceptableOrUnknown(data['holding_id']!, _holdingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_holdingIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      holdingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}holding_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final int holdingId;
  final String type;
  final String? amount;
  final String? price;
  final String? quantity;
  final DateTime date;
  final String? notes;
  const TransactionRow({
    required this.id,
    required this.holdingId,
    required this.type,
    this.amount,
    this.price,
    this.quantity,
    required this.date,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['holding_id'] = Variable<int>(holdingId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<String>(amount);
    }
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<String>(price);
    }
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<String>(quantity);
    }
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      holdingId: Value(holdingId),
      type: Value(type),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      date: Value(date),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      holdingId: serializer.fromJson<int>(json['holdingId']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<String?>(json['amount']),
      price: serializer.fromJson<String?>(json['price']),
      quantity: serializer.fromJson<String?>(json['quantity']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'holdingId': serializer.toJson<int>(holdingId),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<String?>(amount),
      'price': serializer.toJson<String?>(price),
      'quantity': serializer.toJson<String?>(quantity),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  TransactionRow copyWith({
    int? id,
    int? holdingId,
    String? type,
    Value<String?> amount = const Value.absent(),
    Value<String?> price = const Value.absent(),
    Value<String?> quantity = const Value.absent(),
    DateTime? date,
    Value<String?> notes = const Value.absent(),
  }) => TransactionRow(
    id: id ?? this.id,
    holdingId: holdingId ?? this.holdingId,
    type: type ?? this.type,
    amount: amount.present ? amount.value : this.amount,
    price: price.present ? price.value : this.price,
    quantity: quantity.present ? quantity.value : this.quantity,
    date: date ?? this.date,
    notes: notes.present ? notes.value : this.notes,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      holdingId: data.holdingId.present ? data.holdingId.value : this.holdingId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      price: data.price.present ? data.price.value : this.price,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('holdingId: $holdingId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('date: $date, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, holdingId, type, amount, price, quantity, date, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.holdingId == this.holdingId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.price == this.price &&
          other.quantity == this.quantity &&
          other.date == this.date &&
          other.notes == this.notes);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<int> holdingId;
  final Value<String> type;
  final Value<String?> amount;
  final Value<String?> price;
  final Value<String?> quantity;
  final Value<DateTime> date;
  final Value<String?> notes;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.holdingId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int holdingId,
    required String type,
    this.amount = const Value.absent(),
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    required DateTime date,
    this.notes = const Value.absent(),
  }) : holdingId = Value(holdingId),
       type = Value(type),
       date = Value(date);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<int>? holdingId,
    Expression<String>? type,
    Expression<String>? amount,
    Expression<String>? price,
    Expression<String>? quantity,
    Expression<DateTime>? date,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (holdingId != null) 'holding_id': holdingId,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? holdingId,
    Value<String>? type,
    Value<String?>? amount,
    Value<String?>? price,
    Value<String?>? quantity,
    Value<DateTime>? date,
    Value<String?>? notes,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      holdingId: holdingId ?? this.holdingId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (holdingId.present) {
      map['holding_id'] = Variable<int>(holdingId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (price.present) {
      map['price'] = Variable<String>(price.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('holdingId: $holdingId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('date: $date, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $PriceSnapshotsTable extends PriceSnapshots
    with TableInfo<$PriceSnapshotsTable, PriceSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<String> price = GeneratedColumn<String>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CNY'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    source,
    price,
    currency,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PriceSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceSnapshotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $PriceSnapshotsTable createAlias(String alias) {
    return $PriceSnapshotsTable(attachedDatabase, alias);
  }
}

class PriceSnapshotRow extends DataClass
    implements Insertable<PriceSnapshotRow> {
  final int id;
  final String code;
  final String source;
  final String price;
  final String currency;
  final DateTime timestamp;
  const PriceSnapshotRow({
    required this.id,
    required this.code,
    required this.source,
    required this.price,
    required this.currency,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['source'] = Variable<String>(source);
    map['price'] = Variable<String>(price);
    map['currency'] = Variable<String>(currency);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  PriceSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return PriceSnapshotsCompanion(
      id: Value(id),
      code: Value(code),
      source: Value(source),
      price: Value(price),
      currency: Value(currency),
      timestamp: Value(timestamp),
    );
  }

  factory PriceSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceSnapshotRow(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      source: serializer.fromJson<String>(json['source']),
      price: serializer.fromJson<String>(json['price']),
      currency: serializer.fromJson<String>(json['currency']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'source': serializer.toJson<String>(source),
      'price': serializer.toJson<String>(price),
      'currency': serializer.toJson<String>(currency),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  PriceSnapshotRow copyWith({
    int? id,
    String? code,
    String? source,
    String? price,
    String? currency,
    DateTime? timestamp,
  }) => PriceSnapshotRow(
    id: id ?? this.id,
    code: code ?? this.code,
    source: source ?? this.source,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    timestamp: timestamp ?? this.timestamp,
  );
  PriceSnapshotRow copyWithCompanion(PriceSnapshotsCompanion data) {
    return PriceSnapshotRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      source: data.source.present ? data.source.value : this.source,
      price: data.price.present ? data.price.value : this.price,
      currency: data.currency.present ? data.currency.value : this.currency,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceSnapshotRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('source: $source, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, source, price, currency, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceSnapshotRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.source == this.source &&
          other.price == this.price &&
          other.currency == this.currency &&
          other.timestamp == this.timestamp);
}

class PriceSnapshotsCompanion extends UpdateCompanion<PriceSnapshotRow> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> source;
  final Value<String> price;
  final Value<String> currency;
  final Value<DateTime> timestamp;
  const PriceSnapshotsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.source = const Value.absent(),
    this.price = const Value.absent(),
    this.currency = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  PriceSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String source,
    required String price,
    this.currency = const Value.absent(),
    this.timestamp = const Value.absent(),
  }) : code = Value(code),
       source = Value(source),
       price = Value(price);
  static Insertable<PriceSnapshotRow> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? source,
    Expression<String>? price,
    Expression<String>? currency,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (source != null) 'source': source,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  PriceSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? source,
    Value<String>? price,
    Value<String>? currency,
    Value<DateTime>? timestamp,
  }) {
    return PriceSnapshotsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      source: source ?? this.source,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (price.present) {
      map['price'] = Variable<String>(price.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('source: $source, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $CashRecordsTable extends CashRecords
    with TableInfo<$CashRecordsTable, CashRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _holdingIdMeta = const VerificationMeta(
    'holdingId',
  );
  @override
  late final GeneratedColumn<int> holdingId = GeneratedColumn<int>(
    'holding_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset_holdings (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordDateMeta = const VerificationMeta(
    'recordDate',
  );
  @override
  late final GeneratedColumn<DateTime> recordDate = GeneratedColumn<DateTime>(
    'record_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    holdingId,
    amount,
    recordDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('holding_id')) {
      context.handle(
        _holdingIdMeta,
        holdingId.isAcceptableOrUnknown(data['holding_id']!, _holdingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_holdingIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('record_date')) {
      context.handle(
        _recordDateMeta,
        recordDate.isAcceptableOrUnknown(data['record_date']!, _recordDateMeta),
      );
    } else if (isInserting) {
      context.missing(_recordDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      holdingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}holding_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount'],
      )!,
      recordDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}record_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CashRecordsTable createAlias(String alias) {
    return $CashRecordsTable(attachedDatabase, alias);
  }
}

class CashRecordRow extends DataClass implements Insertable<CashRecordRow> {
  final int id;
  final int holdingId;
  final String amount;
  final DateTime recordDate;
  final DateTime createdAt;
  const CashRecordRow({
    required this.id,
    required this.holdingId,
    required this.amount,
    required this.recordDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['holding_id'] = Variable<int>(holdingId);
    map['amount'] = Variable<String>(amount);
    map['record_date'] = Variable<DateTime>(recordDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CashRecordsCompanion toCompanion(bool nullToAbsent) {
    return CashRecordsCompanion(
      id: Value(id),
      holdingId: Value(holdingId),
      amount: Value(amount),
      recordDate: Value(recordDate),
      createdAt: Value(createdAt),
    );
  }

  factory CashRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashRecordRow(
      id: serializer.fromJson<int>(json['id']),
      holdingId: serializer.fromJson<int>(json['holdingId']),
      amount: serializer.fromJson<String>(json['amount']),
      recordDate: serializer.fromJson<DateTime>(json['recordDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'holdingId': serializer.toJson<int>(holdingId),
      'amount': serializer.toJson<String>(amount),
      'recordDate': serializer.toJson<DateTime>(recordDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CashRecordRow copyWith({
    int? id,
    int? holdingId,
    String? amount,
    DateTime? recordDate,
    DateTime? createdAt,
  }) => CashRecordRow(
    id: id ?? this.id,
    holdingId: holdingId ?? this.holdingId,
    amount: amount ?? this.amount,
    recordDate: recordDate ?? this.recordDate,
    createdAt: createdAt ?? this.createdAt,
  );
  CashRecordRow copyWithCompanion(CashRecordsCompanion data) {
    return CashRecordRow(
      id: data.id.present ? data.id.value : this.id,
      holdingId: data.holdingId.present ? data.holdingId.value : this.holdingId,
      amount: data.amount.present ? data.amount.value : this.amount,
      recordDate: data.recordDate.present
          ? data.recordDate.value
          : this.recordDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashRecordRow(')
          ..write('id: $id, ')
          ..write('holdingId: $holdingId, ')
          ..write('amount: $amount, ')
          ..write('recordDate: $recordDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, holdingId, amount, recordDate, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashRecordRow &&
          other.id == this.id &&
          other.holdingId == this.holdingId &&
          other.amount == this.amount &&
          other.recordDate == this.recordDate &&
          other.createdAt == this.createdAt);
}

class CashRecordsCompanion extends UpdateCompanion<CashRecordRow> {
  final Value<int> id;
  final Value<int> holdingId;
  final Value<String> amount;
  final Value<DateTime> recordDate;
  final Value<DateTime> createdAt;
  const CashRecordsCompanion({
    this.id = const Value.absent(),
    this.holdingId = const Value.absent(),
    this.amount = const Value.absent(),
    this.recordDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CashRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int holdingId,
    required String amount,
    required DateTime recordDate,
    this.createdAt = const Value.absent(),
  }) : holdingId = Value(holdingId),
       amount = Value(amount),
       recordDate = Value(recordDate);
  static Insertable<CashRecordRow> custom({
    Expression<int>? id,
    Expression<int>? holdingId,
    Expression<String>? amount,
    Expression<DateTime>? recordDate,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (holdingId != null) 'holding_id': holdingId,
      if (amount != null) 'amount': amount,
      if (recordDate != null) 'record_date': recordDate,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CashRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? holdingId,
    Value<String>? amount,
    Value<DateTime>? recordDate,
    Value<DateTime>? createdAt,
  }) {
    return CashRecordsCompanion(
      id: id ?? this.id,
      holdingId: holdingId ?? this.holdingId,
      amount: amount ?? this.amount,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (holdingId.present) {
      map['holding_id'] = Variable<int>(holdingId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (recordDate.present) {
      map['record_date'] = Variable<DateTime>(recordDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashRecordsCompanion(')
          ..write('id: $id, ')
          ..write('holdingId: $holdingId, ')
          ..write('amount: $amount, ')
          ..write('recordDate: $recordDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AssetCategoriesTable assetCategories = $AssetCategoriesTable(
    this,
  );
  late final $AssetHoldingsTable assetHoldings = $AssetHoldingsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $PriceSnapshotsTable priceSnapshots = $PriceSnapshotsTable(this);
  late final $CashRecordsTable cashRecords = $CashRecordsTable(this);
  late final AssetDao assetDao = AssetDao(this as AppDatabase);
  late final TransactionDao transactionDao = TransactionDao(
    this as AppDatabase,
  );
  late final PriceSnapshotDao priceSnapshotDao = PriceSnapshotDao(
    this as AppDatabase,
  );
  late final CashRecordDao cashRecordDao = CashRecordDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    assetCategories,
    assetHoldings,
    transactions,
    priceSnapshots,
    cashRecords,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'asset_holdings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transactions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'asset_holdings',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cash_records', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AssetCategoriesTableCreateCompanionBuilder =
    AssetCategoriesCompanion Function({
      required String id,
      required String name,
      Value<String> currency,
      Value<String?> icon,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$AssetCategoriesTableUpdateCompanionBuilder =
    AssetCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> currency,
      Value<String?> icon,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$AssetCategoriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $AssetCategoriesTable, AssetCategoryRow> {
  $$AssetCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$AssetHoldingsTable, List<AssetHoldingRow>>
  _assetHoldingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assetHoldings,
    aliasName: 'asset_categories__id__asset_holdings__category_id',
  );

  $$AssetHoldingsTableProcessedTableManager get assetHoldingsRefs {
    final manager = $$AssetHoldingsTableTableManager(
      $_db,
      $_db.assetHoldings,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetHoldingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssetCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $AssetCategoriesTable> {
  $$AssetCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> assetHoldingsRefs(
    Expression<bool> Function($$AssetHoldingsTableFilterComposer f) f,
  ) {
    final $$AssetHoldingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetHoldings,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetHoldingsTableFilterComposer(
            $db: $db,
            $table: $db.assetHoldings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetCategoriesTable> {
  $$AssetCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetCategoriesTable> {
  $$AssetCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> assetHoldingsRefs<T extends Object>(
    Expression<T> Function($$AssetHoldingsTableAnnotationComposer a) f,
  ) {
    final $$AssetHoldingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetHoldings,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetHoldingsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetHoldings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetCategoriesTable,
          AssetCategoryRow,
          $$AssetCategoriesTableFilterComposer,
          $$AssetCategoriesTableOrderingComposer,
          $$AssetCategoriesTableAnnotationComposer,
          $$AssetCategoriesTableCreateCompanionBuilder,
          $$AssetCategoriesTableUpdateCompanionBuilder,
          (AssetCategoryRow, $$AssetCategoriesTableReferences),
          AssetCategoryRow,
          PrefetchHooks Function({bool assetHoldingsRefs})
        > {
  $$AssetCategoriesTableTableManager(
    _$AppDatabase db,
    $AssetCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetCategoriesCompanion(
                id: id,
                name: name,
                currency: currency,
                icon: icon,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> currency = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetCategoriesCompanion.insert(
                id: id,
                name: name,
                currency: currency,
                icon: icon,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetCategoriesTable, AssetCategoryRow>(table),
                  $$AssetCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetHoldingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (assetHoldingsRefs) db.assetHoldings,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (assetHoldingsRefs)
                    await $_getPrefetchedDataByColumns<
                      AssetCategoryRow,
                      $AssetCategoriesTable,
                      AssetHoldingRow,
                      $AssetHoldingsTable
                    >(
                      currentTable: table,
                      referencedTable: $$AssetCategoriesTableReferences
                          ._assetHoldingsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AssetCategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).assetHoldingsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AssetCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetCategoriesTable,
      AssetCategoryRow,
      $$AssetCategoriesTableFilterComposer,
      $$AssetCategoriesTableOrderingComposer,
      $$AssetCategoriesTableAnnotationComposer,
      $$AssetCategoriesTableCreateCompanionBuilder,
      $$AssetCategoriesTableUpdateCompanionBuilder,
      (AssetCategoryRow, $$AssetCategoriesTableReferences),
      AssetCategoryRow,
      PrefetchHooks Function({bool assetHoldingsRefs})
    >;
typedef $$AssetHoldingsTableCreateCompanionBuilder =
    AssetHoldingsCompanion Function({
      Value<int> id,
      required String categoryId,
      required String name,
      Value<String?> code,
      Value<String?> unit,
      Value<String?> amount,
      required String quantity,
      required String costPrice,
      Value<String?> currentPrice,
      required DateTime purchaseDate,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$AssetHoldingsTableUpdateCompanionBuilder =
    AssetHoldingsCompanion Function({
      Value<int> id,
      Value<String> categoryId,
      Value<String> name,
      Value<String?> code,
      Value<String?> unit,
      Value<String?> amount,
      Value<String> quantity,
      Value<String> costPrice,
      Value<String?> currentPrice,
      Value<DateTime> purchaseDate,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$AssetHoldingsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AssetHoldingsTable, AssetHoldingRow> {
  $$AssetHoldingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AssetCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .assetCategories
      .createAlias('asset_holdings__category_id__asset_categories__id');

  $$AssetCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$AssetCategoriesTableTableManager(
      $_db,
      $_db.assetCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'asset_holdings__id__transactions__holding_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.holdingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CashRecordsTable, List<CashRecordRow>>
  _cashRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cashRecords,
    aliasName: 'asset_holdings__id__cash_records__holding_id',
  );

  $$CashRecordsTableProcessedTableManager get cashRecordsRefs {
    final manager = $$CashRecordsTableTableManager(
      $_db,
      $_db.cashRecords,
    ).filter((f) => f.holdingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cashRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssetHoldingsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetHoldingsTable> {
  $$AssetHoldingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetCategoriesTableFilterComposer get categoryId {
    final $$AssetCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.assetCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.assetCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.holdingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cashRecordsRefs(
    Expression<bool> Function($$CashRecordsTableFilterComposer f) f,
  ) {
    final $$CashRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashRecords,
      getReferencedColumn: (t) => t.holdingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashRecordsTableFilterComposer(
            $db: $db,
            $table: $db.cashRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetHoldingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetHoldingsTable> {
  $$AssetHoldingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetCategoriesTableOrderingComposer get categoryId {
    final $$AssetCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.assetCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.assetCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetHoldingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetHoldingsTable> {
  $$AssetHoldingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<String> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AssetCategoriesTableAnnotationComposer get categoryId {
    final $$AssetCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.assetCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.assetCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.holdingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cashRecordsRefs<T extends Object>(
    Expression<T> Function($$CashRecordsTableAnnotationComposer a) f,
  ) {
    final $$CashRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashRecords,
      getReferencedColumn: (t) => t.holdingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.cashRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetHoldingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetHoldingsTable,
          AssetHoldingRow,
          $$AssetHoldingsTableFilterComposer,
          $$AssetHoldingsTableOrderingComposer,
          $$AssetHoldingsTableAnnotationComposer,
          $$AssetHoldingsTableCreateCompanionBuilder,
          $$AssetHoldingsTableUpdateCompanionBuilder,
          (AssetHoldingRow, $$AssetHoldingsTableReferences),
          AssetHoldingRow,
          PrefetchHooks Function({
            bool categoryId,
            bool transactionsRefs,
            bool cashRecordsRefs,
          })
        > {
  $$AssetHoldingsTableTableManager(_$AppDatabase db, $AssetHoldingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetHoldingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetHoldingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetHoldingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> amount = const Value.absent(),
                Value<String> quantity = const Value.absent(),
                Value<String> costPrice = const Value.absent(),
                Value<String?> currentPrice = const Value.absent(),
                Value<DateTime> purchaseDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AssetHoldingsCompanion(
                id: id,
                categoryId: categoryId,
                name: name,
                code: code,
                unit: unit,
                amount: amount,
                quantity: quantity,
                costPrice: costPrice,
                currentPrice: currentPrice,
                purchaseDate: purchaseDate,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String categoryId,
                required String name,
                Value<String?> code = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> amount = const Value.absent(),
                required String quantity,
                required String costPrice,
                Value<String?> currentPrice = const Value.absent(),
                required DateTime purchaseDate,
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AssetHoldingsCompanion.insert(
                id: id,
                categoryId: categoryId,
                name: name,
                code: code,
                unit: unit,
                amount: amount,
                quantity: quantity,
                costPrice: costPrice,
                currentPrice: currentPrice,
                purchaseDate: purchaseDate,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetHoldingsTable, AssetHoldingRow>(table),
                  $$AssetHoldingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                transactionsRefs = false,
                cashRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (cashRecordsRefs) db.cashRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$AssetHoldingsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$AssetHoldingsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedDataByColumns<
                          AssetHoldingRow,
                          $AssetHoldingsTable,
                          TransactionRow,
                          $TransactionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$AssetHoldingsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetHoldingsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'holding_id',
                          typedResults: items,
                        ),
                      if (cashRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          AssetHoldingRow,
                          $AssetHoldingsTable,
                          CashRecordRow,
                          $CashRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$AssetHoldingsTableReferences
                              ._cashRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetHoldingsTableReferences(
                                db,
                                table,
                                p0,
                              ).cashRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'holding_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AssetHoldingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetHoldingsTable,
      AssetHoldingRow,
      $$AssetHoldingsTableFilterComposer,
      $$AssetHoldingsTableOrderingComposer,
      $$AssetHoldingsTableAnnotationComposer,
      $$AssetHoldingsTableCreateCompanionBuilder,
      $$AssetHoldingsTableUpdateCompanionBuilder,
      (AssetHoldingRow, $$AssetHoldingsTableReferences),
      AssetHoldingRow,
      PrefetchHooks Function({
        bool categoryId,
        bool transactionsRefs,
        bool cashRecordsRefs,
      })
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required int holdingId,
      required String type,
      Value<String?> amount,
      Value<String?> price,
      Value<String?> quantity,
      required DateTime date,
      Value<String?> notes,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int> holdingId,
      Value<String> type,
      Value<String?> amount,
      Value<String?> price,
      Value<String?> quantity,
      Value<DateTime> date,
      Value<String?> notes,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetHoldingsTable _holdingIdTable(_$AppDatabase db) => db
      .assetHoldings
      .createAlias('transactions__holding_id__asset_holdings__id');

  $$AssetHoldingsTableProcessedTableManager get holdingId {
    final $_column = $_itemColumn<int>('holding_id')!;

    final manager = $$AssetHoldingsTableTableManager(
      $_db,
      $_db.assetHoldings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_holdingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetHoldingsTableFilterComposer get holdingId {
    final $$AssetHoldingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.assetHoldings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetHoldingsTableFilterComposer(
            $db: $db,
            $table: $db.assetHoldings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetHoldingsTableOrderingComposer get holdingId {
    final $$AssetHoldingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.assetHoldings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetHoldingsTableOrderingComposer(
            $db: $db,
            $table: $db.assetHoldings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$AssetHoldingsTableAnnotationComposer get holdingId {
    final $$AssetHoldingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.assetHoldings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetHoldingsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetHoldings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({bool holdingId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> holdingId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> amount = const Value.absent(),
                Value<String?> price = const Value.absent(),
                Value<String?> quantity = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                holdingId: holdingId,
                type: type,
                amount: amount,
                price: price,
                quantity: quantity,
                date: date,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int holdingId,
                required String type,
                Value<String?> amount = const Value.absent(),
                Value<String?> price = const Value.absent(),
                Value<String?> quantity = const Value.absent(),
                required DateTime date,
                Value<String?> notes = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                holdingId: holdingId,
                type: type,
                amount: amount,
                price: price,
                quantity: quantity,
                date: date,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({holdingId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (holdingId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.holdingId,
                        referencedTable: $$TransactionsTableReferences
                            ._holdingIdTable(db),
                        referencedColumn: $$TransactionsTableReferences
                            ._holdingIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({bool holdingId})
    >;
typedef $$PriceSnapshotsTableCreateCompanionBuilder =
    PriceSnapshotsCompanion Function({
      Value<int> id,
      required String code,
      required String source,
      required String price,
      Value<String> currency,
      Value<DateTime> timestamp,
    });
typedef $$PriceSnapshotsTableUpdateCompanionBuilder =
    PriceSnapshotsCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> source,
      Value<String> price,
      Value<String> currency,
      Value<DateTime> timestamp,
    });

class $$PriceSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $PriceSnapshotsTable> {
  $$PriceSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PriceSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceSnapshotsTable> {
  $$PriceSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PriceSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceSnapshotsTable> {
  $$PriceSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$PriceSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceSnapshotsTable,
          PriceSnapshotRow,
          $$PriceSnapshotsTableFilterComposer,
          $$PriceSnapshotsTableOrderingComposer,
          $$PriceSnapshotsTableAnnotationComposer,
          $$PriceSnapshotsTableCreateCompanionBuilder,
          $$PriceSnapshotsTableUpdateCompanionBuilder,
          (
            PriceSnapshotRow,
            BaseReferences<
              _$AppDatabase,
              $PriceSnapshotsTable,
              PriceSnapshotRow
            >,
          ),
          PriceSnapshotRow,
          PrefetchHooks Function()
        > {
  $$PriceSnapshotsTableTableManager(
    _$AppDatabase db,
    $PriceSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriceSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> price = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => PriceSnapshotsCompanion(
                id: id,
                code: code,
                source: source,
                price: price,
                currency: currency,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String source,
                required String price,
                Value<String> currency = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => PriceSnapshotsCompanion.insert(
                id: id,
                code: code,
                source: source,
                price: price,
                currency: currency,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PriceSnapshotsTable, PriceSnapshotRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PriceSnapshotsTable,
                    PriceSnapshotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PriceSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceSnapshotsTable,
      PriceSnapshotRow,
      $$PriceSnapshotsTableFilterComposer,
      $$PriceSnapshotsTableOrderingComposer,
      $$PriceSnapshotsTableAnnotationComposer,
      $$PriceSnapshotsTableCreateCompanionBuilder,
      $$PriceSnapshotsTableUpdateCompanionBuilder,
      (
        PriceSnapshotRow,
        BaseReferences<_$AppDatabase, $PriceSnapshotsTable, PriceSnapshotRow>,
      ),
      PriceSnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$CashRecordsTableCreateCompanionBuilder =
    CashRecordsCompanion Function({
      Value<int> id,
      required int holdingId,
      required String amount,
      required DateTime recordDate,
      Value<DateTime> createdAt,
    });
typedef $$CashRecordsTableUpdateCompanionBuilder =
    CashRecordsCompanion Function({
      Value<int> id,
      Value<int> holdingId,
      Value<String> amount,
      Value<DateTime> recordDate,
      Value<DateTime> createdAt,
    });

final class $$CashRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $CashRecordsTable, CashRecordRow> {
  $$CashRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetHoldingsTable _holdingIdTable(_$AppDatabase db) => db
      .assetHoldings
      .createAlias('cash_records__holding_id__asset_holdings__id');

  $$AssetHoldingsTableProcessedTableManager get holdingId {
    final $_column = $_itemColumn<int>('holding_id')!;

    final manager = $$AssetHoldingsTableTableManager(
      $_db,
      $_db.assetHoldings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_holdingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CashRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CashRecordsTable> {
  $$CashRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordDate => $composableBuilder(
    column: $table.recordDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetHoldingsTableFilterComposer get holdingId {
    final $$AssetHoldingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.assetHoldings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetHoldingsTableFilterComposer(
            $db: $db,
            $table: $db.assetHoldings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashRecordsTable> {
  $$CashRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordDate => $composableBuilder(
    column: $table.recordDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetHoldingsTableOrderingComposer get holdingId {
    final $$AssetHoldingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.assetHoldings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetHoldingsTableOrderingComposer(
            $db: $db,
            $table: $db.assetHoldings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashRecordsTable> {
  $$CashRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get recordDate => $composableBuilder(
    column: $table.recordDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AssetHoldingsTableAnnotationComposer get holdingId {
    final $$AssetHoldingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.assetHoldings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetHoldingsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetHoldings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashRecordsTable,
          CashRecordRow,
          $$CashRecordsTableFilterComposer,
          $$CashRecordsTableOrderingComposer,
          $$CashRecordsTableAnnotationComposer,
          $$CashRecordsTableCreateCompanionBuilder,
          $$CashRecordsTableUpdateCompanionBuilder,
          (CashRecordRow, $$CashRecordsTableReferences),
          CashRecordRow,
          PrefetchHooks Function({bool holdingId})
        > {
  $$CashRecordsTableTableManager(_$AppDatabase db, $CashRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> holdingId = const Value.absent(),
                Value<String> amount = const Value.absent(),
                Value<DateTime> recordDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CashRecordsCompanion(
                id: id,
                holdingId: holdingId,
                amount: amount,
                recordDate: recordDate,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int holdingId,
                required String amount,
                required DateTime recordDate,
                Value<DateTime> createdAt = const Value.absent(),
              }) => CashRecordsCompanion.insert(
                id: id,
                holdingId: holdingId,
                amount: amount,
                recordDate: recordDate,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CashRecordsTable, CashRecordRow>(table),
                  $$CashRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({holdingId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (holdingId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.holdingId,
                        referencedTable: $$CashRecordsTableReferences
                            ._holdingIdTable(db),
                        referencedColumn: $$CashRecordsTableReferences
                            ._holdingIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CashRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashRecordsTable,
      CashRecordRow,
      $$CashRecordsTableFilterComposer,
      $$CashRecordsTableOrderingComposer,
      $$CashRecordsTableAnnotationComposer,
      $$CashRecordsTableCreateCompanionBuilder,
      $$CashRecordsTableUpdateCompanionBuilder,
      (CashRecordRow, $$CashRecordsTableReferences),
      CashRecordRow,
      PrefetchHooks Function({bool holdingId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AssetCategoriesTableTableManager get assetCategories =>
      $$AssetCategoriesTableTableManager(_db, _db.assetCategories);
  $$AssetHoldingsTableTableManager get assetHoldings =>
      $$AssetHoldingsTableTableManager(_db, _db.assetHoldings);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$PriceSnapshotsTableTableManager get priceSnapshots =>
      $$PriceSnapshotsTableTableManager(_db, _db.priceSnapshots);
  $$CashRecordsTableTableManager get cashRecords =>
      $$CashRecordsTableTableManager(_db, _db.cashRecords);
}
