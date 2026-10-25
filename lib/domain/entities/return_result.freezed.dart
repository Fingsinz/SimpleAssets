// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'return_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReturnResult {

 Decimal get totalCost; Decimal get currentValue; Decimal get profit; double get returnRate; double? get annualizedRate; bool get hasPrice;
/// Create a copy of ReturnResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReturnResultCopyWith<ReturnResult> get copyWith => _$ReturnResultCopyWithImpl<ReturnResult>(this as ReturnResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReturnResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReturnResult&&(identical(other.totalCost, _this.totalCost) || other.totalCost == _this.totalCost)&&(identical(other.currentValue, _this.currentValue) || other.currentValue == _this.currentValue)&&(identical(other.profit, _this.profit) || other.profit == _this.profit)&&(identical(other.returnRate, _this.returnRate) || other.returnRate == _this.returnRate)&&(identical(other.annualizedRate, _this.annualizedRate) || other.annualizedRate == _this.annualizedRate)&&(identical(other.hasPrice, _this.hasPrice) || other.hasPrice == _this.hasPrice));
}


@override
int get hashCode {
  final _this = this as ReturnResult;
  return Object.hash(runtimeType,_this.totalCost,_this.currentValue,_this.profit,_this.returnRate,_this.annualizedRate,_this.hasPrice);
}

@override
String toString() {
  final _this = this as ReturnResult;
  return 'ReturnResult(totalCost: ${_this.totalCost}, currentValue: ${_this.currentValue}, profit: ${_this.profit}, returnRate: ${_this.returnRate}, annualizedRate: ${_this.annualizedRate}, hasPrice: ${_this.hasPrice})';
}


}

/// @nodoc
abstract mixin class $ReturnResultCopyWith<$Res>  {
  factory $ReturnResultCopyWith(ReturnResult value, $Res Function(ReturnResult) _then) = _$ReturnResultCopyWithImpl;
@useResult
$Res call({
 Decimal totalCost, Decimal currentValue, Decimal profit, double returnRate, double? annualizedRate, bool hasPrice
});




}
/// @nodoc
class _$ReturnResultCopyWithImpl<$Res>
    implements $ReturnResultCopyWith<$Res> {
  _$ReturnResultCopyWithImpl(this._self, this._then);

  final ReturnResult _self;
  final $Res Function(ReturnResult) _then;

/// Create a copy of ReturnResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalCost = null,Object? currentValue = null,Object? profit = null,Object? returnRate = null,Object? annualizedRate = freezed,Object? hasPrice = null,}) {
  return _then(ReturnResult(
totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as Decimal,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as Decimal,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as Decimal,returnRate: null == returnRate ? _self.returnRate : returnRate // ignore: cast_nullable_to_non_nullable
as double,annualizedRate: freezed == annualizedRate ? _self.annualizedRate : annualizedRate // ignore: cast_nullable_to_non_nullable
as double?,hasPrice: null == hasPrice ? _self.hasPrice : hasPrice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ReturnResult].
extension ReturnResultPatterns on ReturnResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReturnResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReturnResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReturnResult value)  $default,){
final _that = this;
switch (_that) {
case _ReturnResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReturnResult value)?  $default,){
final _that = this;
switch (_that) {
case _ReturnResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Decimal totalCost,  Decimal currentValue,  Decimal profit,  double returnRate,  double? annualizedRate,  bool hasPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReturnResult() when $default != null:
return $default(_that.totalCost,_that.currentValue,_that.profit,_that.returnRate,_that.annualizedRate,_that.hasPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Decimal totalCost,  Decimal currentValue,  Decimal profit,  double returnRate,  double? annualizedRate,  bool hasPrice)  $default,) {final _that = this;
switch (_that) {
case _ReturnResult():
return $default(_that.totalCost,_that.currentValue,_that.profit,_that.returnRate,_that.annualizedRate,_that.hasPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Decimal totalCost,  Decimal currentValue,  Decimal profit,  double returnRate,  double? annualizedRate,  bool hasPrice)?  $default,) {final _that = this;
switch (_that) {
case _ReturnResult() when $default != null:
return $default(_that.totalCost,_that.currentValue,_that.profit,_that.returnRate,_that.annualizedRate,_that.hasPrice);case _:
  return null;

}
}

}

/// @nodoc


class _ReturnResult extends ReturnResult {
  const _ReturnResult({required this.totalCost, required this.currentValue, required this.profit, required this.returnRate, this.annualizedRate, this.hasPrice = false}): super._();
  

@override final  Decimal totalCost;
@override final  Decimal currentValue;
@override final  Decimal profit;
@override final  double returnRate;
@override final  double? annualizedRate;
@override@JsonKey() final  bool hasPrice;

/// Create a copy of ReturnResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReturnResultCopyWith<_ReturnResult> get copyWith => __$ReturnResultCopyWithImpl<_ReturnResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReturnResult&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.returnRate, returnRate) || other.returnRate == returnRate)&&(identical(other.annualizedRate, annualizedRate) || other.annualizedRate == annualizedRate)&&(identical(other.hasPrice, hasPrice) || other.hasPrice == hasPrice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,totalCost,currentValue,profit,returnRate,annualizedRate,hasPrice);
}

@override
String toString() {
    return 'ReturnResult(totalCost: $totalCost, currentValue: $currentValue, profit: $profit, returnRate: $returnRate, annualizedRate: $annualizedRate, hasPrice: $hasPrice)';
}


}

/// @nodoc
abstract mixin class _$ReturnResultCopyWith<$Res> implements $ReturnResultCopyWith<$Res> {
  factory _$ReturnResultCopyWith(_ReturnResult value, $Res Function(_ReturnResult) _then) = __$ReturnResultCopyWithImpl;
@override @useResult
$Res call({
 Decimal totalCost, Decimal currentValue, Decimal profit, double returnRate, double? annualizedRate, bool hasPrice
});




}
/// @nodoc
class __$ReturnResultCopyWithImpl<$Res>
    implements _$ReturnResultCopyWith<$Res> {
  __$ReturnResultCopyWithImpl(this._self, this._then);

  final _ReturnResult _self;
  final $Res Function(_ReturnResult) _then;

/// Create a copy of ReturnResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalCost = null,Object? currentValue = null,Object? profit = null,Object? returnRate = null,Object? annualizedRate = freezed,Object? hasPrice = null,}) {
  return _then(_ReturnResult(
totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as Decimal,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as Decimal,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as Decimal,returnRate: null == returnRate ? _self.returnRate : returnRate // ignore: cast_nullable_to_non_nullable
as double,annualizedRate: freezed == annualizedRate ? _self.annualizedRate : annualizedRate // ignore: cast_nullable_to_non_nullable
as double?,hasPrice: null == hasPrice ? _self.hasPrice : hasPrice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
