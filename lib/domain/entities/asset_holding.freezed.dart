// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_holding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssetHolding {

 int get id; String get categoryId; String get name; String? get code;/// 贵金属持有单位原文，如 `10克`。
 String? get unit;/// 现金最新金额。
 Decimal? get amount; Decimal get quantity; Decimal get costPrice; Decimal? get currentPrice; DateTime get purchaseDate; String? get notes; DateTime get createdAt; DateTime get updatedAt;/// 联表查询得到的品类名，仅用于展示。
 String? get categoryName;
/// Create a copy of AssetHolding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetHoldingCopyWith<AssetHolding> get copyWith => _$AssetHoldingCopyWithImpl<AssetHolding>(this as AssetHolding, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AssetHolding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetHolding&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.costPrice, _this.costPrice) || other.costPrice == _this.costPrice)&&(identical(other.currentPrice, _this.currentPrice) || other.currentPrice == _this.currentPrice)&&(identical(other.purchaseDate, _this.purchaseDate) || other.purchaseDate == _this.purchaseDate)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.categoryName, _this.categoryName) || other.categoryName == _this.categoryName));
}


@override
int get hashCode {
  final _this = this as AssetHolding;
  return Object.hash(runtimeType,_this.id,_this.categoryId,_this.name,_this.code,_this.unit,_this.amount,_this.quantity,_this.costPrice,_this.currentPrice,_this.purchaseDate,_this.notes,_this.createdAt,_this.updatedAt,_this.categoryName);
}

@override
String toString() {
  final _this = this as AssetHolding;
  return 'AssetHolding(id: ${_this.id}, categoryId: ${_this.categoryId}, name: ${_this.name}, code: ${_this.code}, unit: ${_this.unit}, amount: ${_this.amount}, quantity: ${_this.quantity}, costPrice: ${_this.costPrice}, currentPrice: ${_this.currentPrice}, purchaseDate: ${_this.purchaseDate}, notes: ${_this.notes}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, categoryName: ${_this.categoryName})';
}


}

/// @nodoc
abstract mixin class $AssetHoldingCopyWith<$Res>  {
  factory $AssetHoldingCopyWith(AssetHolding value, $Res Function(AssetHolding) _then) = _$AssetHoldingCopyWithImpl;
@useResult
$Res call({
 int id, String categoryId, String name, String? code, String? unit, Decimal? amount, Decimal quantity, Decimal costPrice, Decimal? currentPrice, DateTime purchaseDate, String? notes, DateTime createdAt, DateTime updatedAt, String? categoryName
});




}
/// @nodoc
class _$AssetHoldingCopyWithImpl<$Res>
    implements $AssetHoldingCopyWith<$Res> {
  _$AssetHoldingCopyWithImpl(this._self, this._then);

  final AssetHolding _self;
  final $Res Function(AssetHolding) _then;

/// Create a copy of AssetHolding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? categoryId = null,Object? name = null,Object? code = freezed,Object? unit = freezed,Object? amount = freezed,Object? quantity = null,Object? costPrice = null,Object? currentPrice = freezed,Object? purchaseDate = null,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,Object? categoryName = freezed,}) {
  return _then(AssetHolding(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Decimal,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as Decimal,currentPrice: freezed == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,purchaseDate: null == purchaseDate ? _self.purchaseDate : purchaseDate // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetHolding].
extension AssetHoldingPatterns on AssetHolding {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetHolding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetHolding() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetHolding value)  $default,){
final _that = this;
switch (_that) {
case _AssetHolding():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetHolding value)?  $default,){
final _that = this;
switch (_that) {
case _AssetHolding() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String categoryId,  String name,  String? code,  String? unit,  Decimal? amount,  Decimal quantity,  Decimal costPrice,  Decimal? currentPrice,  DateTime purchaseDate,  String? notes,  DateTime createdAt,  DateTime updatedAt,  String? categoryName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetHolding() when $default != null:
return $default(_that.id,_that.categoryId,_that.name,_that.code,_that.unit,_that.amount,_that.quantity,_that.costPrice,_that.currentPrice,_that.purchaseDate,_that.notes,_that.createdAt,_that.updatedAt,_that.categoryName);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String categoryId,  String name,  String? code,  String? unit,  Decimal? amount,  Decimal quantity,  Decimal costPrice,  Decimal? currentPrice,  DateTime purchaseDate,  String? notes,  DateTime createdAt,  DateTime updatedAt,  String? categoryName)  $default,) {final _that = this;
switch (_that) {
case _AssetHolding():
return $default(_that.id,_that.categoryId,_that.name,_that.code,_that.unit,_that.amount,_that.quantity,_that.costPrice,_that.currentPrice,_that.purchaseDate,_that.notes,_that.createdAt,_that.updatedAt,_that.categoryName);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String categoryId,  String name,  String? code,  String? unit,  Decimal? amount,  Decimal quantity,  Decimal costPrice,  Decimal? currentPrice,  DateTime purchaseDate,  String? notes,  DateTime createdAt,  DateTime updatedAt,  String? categoryName)?  $default,) {final _that = this;
switch (_that) {
case _AssetHolding() when $default != null:
return $default(_that.id,_that.categoryId,_that.name,_that.code,_that.unit,_that.amount,_that.quantity,_that.costPrice,_that.currentPrice,_that.purchaseDate,_that.notes,_that.createdAt,_that.updatedAt,_that.categoryName);case _:
  return null;

}
}

}

/// @nodoc


class _AssetHolding extends AssetHolding {
  const _AssetHolding({required this.id, required this.categoryId, required this.name, this.code, this.unit, this.amount, required this.quantity, required this.costPrice, this.currentPrice, required this.purchaseDate, this.notes, required this.createdAt, required this.updatedAt, this.categoryName}): super._();
  

@override final  int id;
@override final  String categoryId;
@override final  String name;
@override final  String? code;
/// 贵金属持有单位原文，如 `10克`。
@override final  String? unit;
/// 现金最新金额。
@override final  Decimal? amount;
@override final  Decimal quantity;
@override final  Decimal costPrice;
@override final  Decimal? currentPrice;
@override final  DateTime purchaseDate;
@override final  String? notes;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// 联表查询得到的品类名，仅用于展示。
@override final  String? categoryName;

/// Create a copy of AssetHolding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetHoldingCopyWith<_AssetHolding> get copyWith => __$AssetHoldingCopyWithImpl<_AssetHolding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetHolding&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,categoryId,name,code,unit,amount,quantity,costPrice,currentPrice,purchaseDate,notes,createdAt,updatedAt,categoryName);
}

@override
String toString() {
    return 'AssetHolding(id: $id, categoryId: $categoryId, name: $name, code: $code, unit: $unit, amount: $amount, quantity: $quantity, costPrice: $costPrice, currentPrice: $currentPrice, purchaseDate: $purchaseDate, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class _$AssetHoldingCopyWith<$Res> implements $AssetHoldingCopyWith<$Res> {
  factory _$AssetHoldingCopyWith(_AssetHolding value, $Res Function(_AssetHolding) _then) = __$AssetHoldingCopyWithImpl;
@override @useResult
$Res call({
 int id, String categoryId, String name, String? code, String? unit, Decimal? amount, Decimal quantity, Decimal costPrice, Decimal? currentPrice, DateTime purchaseDate, String? notes, DateTime createdAt, DateTime updatedAt, String? categoryName
});




}
/// @nodoc
class __$AssetHoldingCopyWithImpl<$Res>
    implements _$AssetHoldingCopyWith<$Res> {
  __$AssetHoldingCopyWithImpl(this._self, this._then);

  final _AssetHolding _self;
  final $Res Function(_AssetHolding) _then;

/// Create a copy of AssetHolding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? categoryId = null,Object? name = null,Object? code = freezed,Object? unit = freezed,Object? amount = freezed,Object? quantity = null,Object? costPrice = null,Object? currentPrice = freezed,Object? purchaseDate = null,Object? notes = freezed,Object? createdAt = null,Object? updatedAt = null,Object? categoryName = freezed,}) {
  return _then(_AssetHolding(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Decimal,costPrice: null == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as Decimal,currentPrice: freezed == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,purchaseDate: null == purchaseDate ? _self.purchaseDate : purchaseDate // ignore: cast_nullable_to_non_nullable
as DateTime,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
