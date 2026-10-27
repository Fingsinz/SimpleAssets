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

 Decimal get totalCost; Decimal get totalInvested; Decimal get currentValue; Decimal get profit; double get returnRate; double? get annualizedRate; bool get hasPrice; Decimal? get realizedProfit; Decimal? get totalDividends; Decimal? get totalFees;
/// Create a copy of ReturnResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReturnResultCopyWith<ReturnResult> get copyWith => _$ReturnResultCopyWithImpl<ReturnResult>(this as ReturnResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReturnResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReturnResult&&(identical(other.totalCost, _this.totalCost) || other.totalCost == _this.totalCost)&&(identical(other.totalInvested, _this.totalInvested) || other.totalInvested == _this.totalInvested)&&(identical(other.currentValue, _this.currentValue) || other.currentValue == _this.currentValue)&&(identical(other.profit, _this.profit) || other.profit == _this.profit)&&(identical(other.returnRate, _this.returnRate) || other.returnRate == _this.returnRate)&&(identical(other.annualizedRate, _this.annualizedRate) || other.annualizedRate == _this.annualizedRate)&&(identical(other.hasPrice, _this.hasPrice) || other.hasPrice == _this.hasPrice)&&(identical(other.realizedProfit, _this.realizedProfit) || other.realizedProfit == _this.realizedProfit)&&(identical(other.totalDividends, _this.totalDividends) || other.totalDividends == _this.totalDividends)&&(identical(other.totalFees, _this.totalFees) || other.totalFees == _this.totalFees));
}


@override
int get hashCode {
  final _this = this as ReturnResult;
  return Object.hash(runtimeType,_this.totalCost,_this.totalInvested,_this.currentValue,_this.profit,_this.returnRate,_this.annualizedRate,_this.hasPrice,_this.realizedProfit,_this.totalDividends,_this.totalFees);
}

@override
String toString() {
  final _this = this as ReturnResult;
  return 'ReturnResult(totalCost: ${_this.totalCost}, totalInvested: ${_this.totalInvested}, currentValue: ${_this.currentValue}, profit: ${_this.profit}, returnRate: ${_this.returnRate}, annualizedRate: ${_this.annualizedRate}, hasPrice: ${_this.hasPrice}, realizedProfit: ${_this.realizedProfit}, totalDividends: ${_this.totalDividends}, totalFees: ${_this.totalFees})';
}


}

/// @nodoc
abstract mixin class $ReturnResultCopyWith<$Res>  {
  factory $ReturnResultCopyWith(ReturnResult value, $Res Function(ReturnResult) _then) = _$ReturnResultCopyWithImpl;
@useResult
$Res call({
 Decimal totalCost, Decimal totalInvested, Decimal currentValue, Decimal profit, double returnRate, double? annualizedRate, bool hasPrice, Decimal? realizedProfit, Decimal? totalDividends, Decimal? totalFees
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
@pragma('vm:prefer-inline') @override $Res call({Object? totalCost = null,Object? totalInvested = null,Object? currentValue = null,Object? profit = null,Object? returnRate = null,Object? annualizedRate = freezed,Object? hasPrice = null,Object? realizedProfit = freezed,Object? totalDividends = freezed,Object? totalFees = freezed,}) {
  return _then(ReturnResult(
totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as Decimal,totalInvested: null == totalInvested ? _self.totalInvested : totalInvested // ignore: cast_nullable_to_non_nullable
as Decimal,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as Decimal,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as Decimal,returnRate: null == returnRate ? _self.returnRate : returnRate // ignore: cast_nullable_to_non_nullable
as double,annualizedRate: freezed == annualizedRate ? _self.annualizedRate : annualizedRate // ignore: cast_nullable_to_non_nullable
as double?,hasPrice: null == hasPrice ? _self.hasPrice : hasPrice // ignore: cast_nullable_to_non_nullable
as bool,realizedProfit: freezed == realizedProfit ? _self.realizedProfit : realizedProfit // ignore: cast_nullable_to_non_nullable
as Decimal?,totalDividends: freezed == totalDividends ? _self.totalDividends : totalDividends // ignore: cast_nullable_to_non_nullable
as Decimal?,totalFees: freezed == totalFees ? _self.totalFees : totalFees // ignore: cast_nullable_to_non_nullable
as Decimal?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Decimal totalCost,  Decimal totalInvested,  Decimal currentValue,  Decimal profit,  double returnRate,  double? annualizedRate,  bool hasPrice,  Decimal? realizedProfit,  Decimal? totalDividends,  Decimal? totalFees)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReturnResult() when $default != null:
return $default(_that.totalCost,_that.totalInvested,_that.currentValue,_that.profit,_that.returnRate,_that.annualizedRate,_that.hasPrice,_that.realizedProfit,_that.totalDividends,_that.totalFees);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Decimal totalCost,  Decimal totalInvested,  Decimal currentValue,  Decimal profit,  double returnRate,  double? annualizedRate,  bool hasPrice,  Decimal? realizedProfit,  Decimal? totalDividends,  Decimal? totalFees)  $default,) {final _that = this;
switch (_that) {
case _ReturnResult():
return $default(_that.totalCost,_that.totalInvested,_that.currentValue,_that.profit,_that.returnRate,_that.annualizedRate,_that.hasPrice,_that.realizedProfit,_that.totalDividends,_that.totalFees);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Decimal totalCost,  Decimal totalInvested,  Decimal currentValue,  Decimal profit,  double returnRate,  double? annualizedRate,  bool hasPrice,  Decimal? realizedProfit,  Decimal? totalDividends,  Decimal? totalFees)?  $default,) {final _that = this;
switch (_that) {
case _ReturnResult() when $default != null:
return $default(_that.totalCost,_that.totalInvested,_that.currentValue,_that.profit,_that.returnRate,_that.annualizedRate,_that.hasPrice,_that.realizedProfit,_that.totalDividends,_that.totalFees);case _:
  return null;

}
}

}

/// @nodoc


class _ReturnResult extends ReturnResult {
  const _ReturnResult({required this.totalCost, required this.totalInvested, required this.currentValue, required this.profit, required this.returnRate, this.annualizedRate, this.hasPrice = false, this.realizedProfit, this.totalDividends, this.totalFees}): super._();
  

@override final  Decimal totalCost;
@override final  Decimal totalInvested;
@override final  Decimal currentValue;
@override final  Decimal profit;
@override final  double returnRate;
@override final  double? annualizedRate;
@override@JsonKey() final  bool hasPrice;
@override final  Decimal? realizedProfit;
@override final  Decimal? totalDividends;
@override final  Decimal? totalFees;

/// Create a copy of ReturnResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReturnResultCopyWith<_ReturnResult> get copyWith => __$ReturnResultCopyWithImpl<_ReturnResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReturnResult&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.totalInvested, totalInvested) || other.totalInvested == totalInvested)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.returnRate, returnRate) || other.returnRate == returnRate)&&(identical(other.annualizedRate, annualizedRate) || other.annualizedRate == annualizedRate)&&(identical(other.hasPrice, hasPrice) || other.hasPrice == hasPrice)&&(identical(other.realizedProfit, realizedProfit) || other.realizedProfit == realizedProfit)&&(identical(other.totalDividends, totalDividends) || other.totalDividends == totalDividends)&&(identical(other.totalFees, totalFees) || other.totalFees == totalFees));
}


@override
int get hashCode {
    return Object.hash(runtimeType,totalCost,totalInvested,currentValue,profit,returnRate,annualizedRate,hasPrice,realizedProfit,totalDividends,totalFees);
}

@override
String toString() {
    return 'ReturnResult(totalCost: $totalCost, totalInvested: $totalInvested, currentValue: $currentValue, profit: $profit, returnRate: $returnRate, annualizedRate: $annualizedRate, hasPrice: $hasPrice, realizedProfit: $realizedProfit, totalDividends: $totalDividends, totalFees: $totalFees)';
}


}

/// @nodoc
abstract mixin class _$ReturnResultCopyWith<$Res> implements $ReturnResultCopyWith<$Res> {
  factory _$ReturnResultCopyWith(_ReturnResult value, $Res Function(_ReturnResult) _then) = __$ReturnResultCopyWithImpl;
@override @useResult
$Res call({
 Decimal totalCost, Decimal totalInvested, Decimal currentValue, Decimal profit, double returnRate, double? annualizedRate, bool hasPrice, Decimal? realizedProfit, Decimal? totalDividends, Decimal? totalFees
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
@override @pragma('vm:prefer-inline') $Res call({Object? totalCost = null,Object? totalInvested = null,Object? currentValue = null,Object? profit = null,Object? returnRate = null,Object? annualizedRate = freezed,Object? hasPrice = null,Object? realizedProfit = freezed,Object? totalDividends = freezed,Object? totalFees = freezed,}) {
  return _then(_ReturnResult(
totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as Decimal,totalInvested: null == totalInvested ? _self.totalInvested : totalInvested // ignore: cast_nullable_to_non_nullable
as Decimal,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as Decimal,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as Decimal,returnRate: null == returnRate ? _self.returnRate : returnRate // ignore: cast_nullable_to_non_nullable
as double,annualizedRate: freezed == annualizedRate ? _self.annualizedRate : annualizedRate // ignore: cast_nullable_to_non_nullable
as double?,hasPrice: null == hasPrice ? _self.hasPrice : hasPrice // ignore: cast_nullable_to_non_nullable
as bool,realizedProfit: freezed == realizedProfit ? _self.realizedProfit : realizedProfit // ignore: cast_nullable_to_non_nullable
as Decimal?,totalDividends: freezed == totalDividends ? _self.totalDividends : totalDividends // ignore: cast_nullable_to_non_nullable
as Decimal?,totalFees: freezed == totalFees ? _self.totalFees : totalFees // ignore: cast_nullable_to_non_nullable
as Decimal?,
  ));
}


}

// dart format on
