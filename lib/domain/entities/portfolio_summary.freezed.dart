// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortfolioSummary {

 Decimal get totalCost; Decimal get totalMarketValue; Decimal get totalProfit; double get totalReturnRate; List<CategoryAllocation> get allocations;
/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortfolioSummaryCopyWith<PortfolioSummary> get copyWith => _$PortfolioSummaryCopyWithImpl<PortfolioSummary>(this as PortfolioSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PortfolioSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortfolioSummary&&(identical(other.totalCost, _this.totalCost) || other.totalCost == _this.totalCost)&&(identical(other.totalMarketValue, _this.totalMarketValue) || other.totalMarketValue == _this.totalMarketValue)&&(identical(other.totalProfit, _this.totalProfit) || other.totalProfit == _this.totalProfit)&&(identical(other.totalReturnRate, _this.totalReturnRate) || other.totalReturnRate == _this.totalReturnRate)&&const DeepCollectionEquality().equals(other.allocations, _this.allocations));
}


@override
int get hashCode {
  final _this = this as PortfolioSummary;
  return Object.hash(runtimeType,_this.totalCost,_this.totalMarketValue,_this.totalProfit,_this.totalReturnRate,const DeepCollectionEquality().hash(_this.allocations));
}

@override
String toString() {
  final _this = this as PortfolioSummary;
  return 'PortfolioSummary(totalCost: ${_this.totalCost}, totalMarketValue: ${_this.totalMarketValue}, totalProfit: ${_this.totalProfit}, totalReturnRate: ${_this.totalReturnRate}, allocations: ${_this.allocations})';
}


}

/// @nodoc
abstract mixin class $PortfolioSummaryCopyWith<$Res>  {
  factory $PortfolioSummaryCopyWith(PortfolioSummary value, $Res Function(PortfolioSummary) _then) = _$PortfolioSummaryCopyWithImpl;
@useResult
$Res call({
 Decimal totalCost, Decimal totalMarketValue, Decimal totalProfit, double totalReturnRate, List<CategoryAllocation> allocations
});




}
/// @nodoc
class _$PortfolioSummaryCopyWithImpl<$Res>
    implements $PortfolioSummaryCopyWith<$Res> {
  _$PortfolioSummaryCopyWithImpl(this._self, this._then);

  final PortfolioSummary _self;
  final $Res Function(PortfolioSummary) _then;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalCost = null,Object? totalMarketValue = null,Object? totalProfit = null,Object? totalReturnRate = null,Object? allocations = null,}) {
  return _then(PortfolioSummary(
totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as Decimal,totalMarketValue: null == totalMarketValue ? _self.totalMarketValue : totalMarketValue // ignore: cast_nullable_to_non_nullable
as Decimal,totalProfit: null == totalProfit ? _self.totalProfit : totalProfit // ignore: cast_nullable_to_non_nullable
as Decimal,totalReturnRate: null == totalReturnRate ? _self.totalReturnRate : totalReturnRate // ignore: cast_nullable_to_non_nullable
as double,allocations: null == allocations ? _self.allocations : allocations // ignore: cast_nullable_to_non_nullable
as List<CategoryAllocation>,
  ));
}

}


/// Adds pattern-matching-related methods to [PortfolioSummary].
extension PortfolioSummaryPatterns on PortfolioSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortfolioSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortfolioSummary value)  $default,){
final _that = this;
switch (_that) {
case _PortfolioSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortfolioSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Decimal totalCost,  Decimal totalMarketValue,  Decimal totalProfit,  double totalReturnRate,  List<CategoryAllocation> allocations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
return $default(_that.totalCost,_that.totalMarketValue,_that.totalProfit,_that.totalReturnRate,_that.allocations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Decimal totalCost,  Decimal totalMarketValue,  Decimal totalProfit,  double totalReturnRate,  List<CategoryAllocation> allocations)  $default,) {final _that = this;
switch (_that) {
case _PortfolioSummary():
return $default(_that.totalCost,_that.totalMarketValue,_that.totalProfit,_that.totalReturnRate,_that.allocations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Decimal totalCost,  Decimal totalMarketValue,  Decimal totalProfit,  double totalReturnRate,  List<CategoryAllocation> allocations)?  $default,) {final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
return $default(_that.totalCost,_that.totalMarketValue,_that.totalProfit,_that.totalReturnRate,_that.allocations);case _:
  return null;

}
}

}

/// @nodoc


class _PortfolioSummary extends PortfolioSummary {
  const _PortfolioSummary({required this.totalCost, required this.totalMarketValue, required this.totalProfit, required this.totalReturnRate, required  List<CategoryAllocation> allocations}): _allocations = allocations,super._();
  

@override final  Decimal totalCost;
@override final  Decimal totalMarketValue;
@override final  Decimal totalProfit;
@override final  double totalReturnRate;
 final  List<CategoryAllocation> _allocations;
@override List<CategoryAllocation> get allocations {
  if (_allocations is EqualUnmodifiableListView) return _allocations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allocations);
}


/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortfolioSummaryCopyWith<_PortfolioSummary> get copyWith => __$PortfolioSummaryCopyWithImpl<_PortfolioSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortfolioSummary&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.totalMarketValue, totalMarketValue) || other.totalMarketValue == totalMarketValue)&&(identical(other.totalProfit, totalProfit) || other.totalProfit == totalProfit)&&(identical(other.totalReturnRate, totalReturnRate) || other.totalReturnRate == totalReturnRate)&&const DeepCollectionEquality().equals(other.allocations, _allocations));
}


@override
int get hashCode {
    return Object.hash(runtimeType,totalCost,totalMarketValue,totalProfit,totalReturnRate,const DeepCollectionEquality().hash(_allocations));
}

@override
String toString() {
    return 'PortfolioSummary(totalCost: $totalCost, totalMarketValue: $totalMarketValue, totalProfit: $totalProfit, totalReturnRate: $totalReturnRate, allocations: $allocations)';
}


}

/// @nodoc
abstract mixin class _$PortfolioSummaryCopyWith<$Res> implements $PortfolioSummaryCopyWith<$Res> {
  factory _$PortfolioSummaryCopyWith(_PortfolioSummary value, $Res Function(_PortfolioSummary) _then) = __$PortfolioSummaryCopyWithImpl;
@override @useResult
$Res call({
 Decimal totalCost, Decimal totalMarketValue, Decimal totalProfit, double totalReturnRate, List<CategoryAllocation> allocations
});




}
/// @nodoc
class __$PortfolioSummaryCopyWithImpl<$Res>
    implements _$PortfolioSummaryCopyWith<$Res> {
  __$PortfolioSummaryCopyWithImpl(this._self, this._then);

  final _PortfolioSummary _self;
  final $Res Function(_PortfolioSummary) _then;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalCost = null,Object? totalMarketValue = null,Object? totalProfit = null,Object? totalReturnRate = null,Object? allocations = null,}) {
  return _then(_PortfolioSummary(
totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as Decimal,totalMarketValue: null == totalMarketValue ? _self.totalMarketValue : totalMarketValue // ignore: cast_nullable_to_non_nullable
as Decimal,totalProfit: null == totalProfit ? _self.totalProfit : totalProfit // ignore: cast_nullable_to_non_nullable
as Decimal,totalReturnRate: null == totalReturnRate ? _self.totalReturnRate : totalReturnRate // ignore: cast_nullable_to_non_nullable
as double,allocations: null == allocations ? _self._allocations : allocations // ignore: cast_nullable_to_non_nullable
as List<CategoryAllocation>,
  ));
}


}

/// @nodoc
mixin _$CategoryAllocation {

 String get categoryId; String get categoryName; Decimal get marketValue; double get percentage; Decimal get profit; double get returnRate;
/// Create a copy of CategoryAllocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryAllocationCopyWith<CategoryAllocation> get copyWith => _$CategoryAllocationCopyWithImpl<CategoryAllocation>(this as CategoryAllocation, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CategoryAllocation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryAllocation&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.categoryName, _this.categoryName) || other.categoryName == _this.categoryName)&&(identical(other.marketValue, _this.marketValue) || other.marketValue == _this.marketValue)&&(identical(other.percentage, _this.percentage) || other.percentage == _this.percentage)&&(identical(other.profit, _this.profit) || other.profit == _this.profit)&&(identical(other.returnRate, _this.returnRate) || other.returnRate == _this.returnRate));
}


@override
int get hashCode {
  final _this = this as CategoryAllocation;
  return Object.hash(runtimeType,_this.categoryId,_this.categoryName,_this.marketValue,_this.percentage,_this.profit,_this.returnRate);
}

@override
String toString() {
  final _this = this as CategoryAllocation;
  return 'CategoryAllocation(categoryId: ${_this.categoryId}, categoryName: ${_this.categoryName}, marketValue: ${_this.marketValue}, percentage: ${_this.percentage}, profit: ${_this.profit}, returnRate: ${_this.returnRate})';
}


}

/// @nodoc
abstract mixin class $CategoryAllocationCopyWith<$Res>  {
  factory $CategoryAllocationCopyWith(CategoryAllocation value, $Res Function(CategoryAllocation) _then) = _$CategoryAllocationCopyWithImpl;
@useResult
$Res call({
 String categoryId, String categoryName, Decimal marketValue, double percentage, Decimal profit, double returnRate
});




}
/// @nodoc
class _$CategoryAllocationCopyWithImpl<$Res>
    implements $CategoryAllocationCopyWith<$Res> {
  _$CategoryAllocationCopyWithImpl(this._self, this._then);

  final CategoryAllocation _self;
  final $Res Function(CategoryAllocation) _then;

/// Create a copy of CategoryAllocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = null,Object? categoryName = null,Object? marketValue = null,Object? percentage = null,Object? profit = null,Object? returnRate = null,}) {
  return _then(CategoryAllocation(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as Decimal,returnRate: null == returnRate ? _self.returnRate : returnRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryAllocation].
extension CategoryAllocationPatterns on CategoryAllocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryAllocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryAllocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryAllocation value)  $default,){
final _that = this;
switch (_that) {
case _CategoryAllocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryAllocation value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryAllocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categoryId,  String categoryName,  Decimal marketValue,  double percentage,  Decimal profit,  double returnRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryAllocation() when $default != null:
return $default(_that.categoryId,_that.categoryName,_that.marketValue,_that.percentage,_that.profit,_that.returnRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categoryId,  String categoryName,  Decimal marketValue,  double percentage,  Decimal profit,  double returnRate)  $default,) {final _that = this;
switch (_that) {
case _CategoryAllocation():
return $default(_that.categoryId,_that.categoryName,_that.marketValue,_that.percentage,_that.profit,_that.returnRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categoryId,  String categoryName,  Decimal marketValue,  double percentage,  Decimal profit,  double returnRate)?  $default,) {final _that = this;
switch (_that) {
case _CategoryAllocation() when $default != null:
return $default(_that.categoryId,_that.categoryName,_that.marketValue,_that.percentage,_that.profit,_that.returnRate);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryAllocation extends CategoryAllocation {
  const _CategoryAllocation({required this.categoryId, required this.categoryName, required this.marketValue, required this.percentage, required this.profit, required this.returnRate}): super._();
  

@override final  String categoryId;
@override final  String categoryName;
@override final  Decimal marketValue;
@override final  double percentage;
@override final  Decimal profit;
@override final  double returnRate;

/// Create a copy of CategoryAllocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryAllocationCopyWith<_CategoryAllocation> get copyWith => __$CategoryAllocationCopyWithImpl<_CategoryAllocation>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryAllocation&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.percentage, percentage) || other.percentage == percentage)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.returnRate, returnRate) || other.returnRate == returnRate));
}


@override
int get hashCode {
    return Object.hash(runtimeType,categoryId,categoryName,marketValue,percentage,profit,returnRate);
}

@override
String toString() {
    return 'CategoryAllocation(categoryId: $categoryId, categoryName: $categoryName, marketValue: $marketValue, percentage: $percentage, profit: $profit, returnRate: $returnRate)';
}


}

/// @nodoc
abstract mixin class _$CategoryAllocationCopyWith<$Res> implements $CategoryAllocationCopyWith<$Res> {
  factory _$CategoryAllocationCopyWith(_CategoryAllocation value, $Res Function(_CategoryAllocation) _then) = __$CategoryAllocationCopyWithImpl;
@override @useResult
$Res call({
 String categoryId, String categoryName, Decimal marketValue, double percentage, Decimal profit, double returnRate
});




}
/// @nodoc
class __$CategoryAllocationCopyWithImpl<$Res>
    implements _$CategoryAllocationCopyWith<$Res> {
  __$CategoryAllocationCopyWithImpl(this._self, this._then);

  final _CategoryAllocation _self;
  final $Res Function(_CategoryAllocation) _then;

/// Create a copy of CategoryAllocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? categoryName = null,Object? marketValue = null,Object? percentage = null,Object? profit = null,Object? returnRate = null,}) {
  return _then(_CategoryAllocation(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as Decimal,returnRate: null == returnRate ? _self.returnRate : returnRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
