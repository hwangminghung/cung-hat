// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'keo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Keo {

 String get id; String get title;@JsonKey(name: 'area_label') String? get areaLabel;@JsonKey(name: 'distance_band') String? get distanceBand;@JsonKey(name: 'time_window_start') String? get timeWindowStart;@JsonKey(name: 'time_window_end') String? get timeWindowEnd;@JsonKey(name: 'size_target') int get sizeTarget;@JsonKey(name: 'slots_filled') int get slotsFilled; List<String> get genres;@JsonKey(name: 'host_name') String? get hostName; String get status;@JsonKey(name: 'join_mode') String get joinMode;@JsonKey(name: 'is_boosted') bool get isBoosted;@JsonKey(name: 'boost_ends_at') String? get boostEndsAt;
/// Create a copy of Keo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeoCopyWith<Keo> get copyWith => _$KeoCopyWithImpl<Keo>(this as Keo, _$identity);

  /// Serializes this Keo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Keo&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.areaLabel, areaLabel) || other.areaLabel == areaLabel)&&(identical(other.distanceBand, distanceBand) || other.distanceBand == distanceBand)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&(identical(other.sizeTarget, sizeTarget) || other.sizeTarget == sizeTarget)&&(identical(other.slotsFilled, slotsFilled) || other.slotsFilled == slotsFilled)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.hostName, hostName) || other.hostName == hostName)&&(identical(other.status, status) || other.status == status)&&(identical(other.joinMode, joinMode) || other.joinMode == joinMode)&&(identical(other.isBoosted, isBoosted) || other.isBoosted == isBoosted)&&(identical(other.boostEndsAt, boostEndsAt) || other.boostEndsAt == boostEndsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,areaLabel,distanceBand,timeWindowStart,timeWindowEnd,sizeTarget,slotsFilled,const DeepCollectionEquality().hash(genres),hostName,status,joinMode,isBoosted,boostEndsAt);

@override
String toString() {
  return 'Keo(id: $id, title: $title, areaLabel: $areaLabel, distanceBand: $distanceBand, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, sizeTarget: $sizeTarget, slotsFilled: $slotsFilled, genres: $genres, hostName: $hostName, status: $status, joinMode: $joinMode, isBoosted: $isBoosted, boostEndsAt: $boostEndsAt)';
}


}

/// @nodoc
abstract mixin class $KeoCopyWith<$Res>  {
  factory $KeoCopyWith(Keo value, $Res Function(Keo) _then) = _$KeoCopyWithImpl;
@useResult
$Res call({
 String id, String title,@JsonKey(name: 'area_label') String? areaLabel,@JsonKey(name: 'distance_band') String? distanceBand,@JsonKey(name: 'time_window_start') String? timeWindowStart,@JsonKey(name: 'time_window_end') String? timeWindowEnd,@JsonKey(name: 'size_target') int sizeTarget,@JsonKey(name: 'slots_filled') int slotsFilled, List<String> genres,@JsonKey(name: 'host_name') String? hostName, String status,@JsonKey(name: 'join_mode') String joinMode,@JsonKey(name: 'is_boosted') bool isBoosted,@JsonKey(name: 'boost_ends_at') String? boostEndsAt
});




}
/// @nodoc
class _$KeoCopyWithImpl<$Res>
    implements $KeoCopyWith<$Res> {
  _$KeoCopyWithImpl(this._self, this._then);

  final Keo _self;
  final $Res Function(Keo) _then;

/// Create a copy of Keo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? areaLabel = freezed,Object? distanceBand = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? sizeTarget = null,Object? slotsFilled = null,Object? genres = null,Object? hostName = freezed,Object? status = null,Object? joinMode = null,Object? isBoosted = null,Object? boostEndsAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,areaLabel: freezed == areaLabel ? _self.areaLabel : areaLabel // ignore: cast_nullable_to_non_nullable
as String?,distanceBand: freezed == distanceBand ? _self.distanceBand : distanceBand // ignore: cast_nullable_to_non_nullable
as String?,timeWindowStart: freezed == timeWindowStart ? _self.timeWindowStart : timeWindowStart // ignore: cast_nullable_to_non_nullable
as String?,timeWindowEnd: freezed == timeWindowEnd ? _self.timeWindowEnd : timeWindowEnd // ignore: cast_nullable_to_non_nullable
as String?,sizeTarget: null == sizeTarget ? _self.sizeTarget : sizeTarget // ignore: cast_nullable_to_non_nullable
as int,slotsFilled: null == slotsFilled ? _self.slotsFilled : slotsFilled // ignore: cast_nullable_to_non_nullable
as int,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,hostName: freezed == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,joinMode: null == joinMode ? _self.joinMode : joinMode // ignore: cast_nullable_to_non_nullable
as String,isBoosted: null == isBoosted ? _self.isBoosted : isBoosted // ignore: cast_nullable_to_non_nullable
as bool,boostEndsAt: freezed == boostEndsAt ? _self.boostEndsAt : boostEndsAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Keo].
extension KeoPatterns on Keo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Keo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Keo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Keo value)  $default,){
final _that = this;
switch (_that) {
case _Keo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Keo value)?  $default,){
final _that = this;
switch (_that) {
case _Keo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(name: 'area_label')  String? areaLabel, @JsonKey(name: 'distance_band')  String? distanceBand, @JsonKey(name: 'time_window_start')  String? timeWindowStart, @JsonKey(name: 'time_window_end')  String? timeWindowEnd, @JsonKey(name: 'size_target')  int sizeTarget, @JsonKey(name: 'slots_filled')  int slotsFilled,  List<String> genres, @JsonKey(name: 'host_name')  String? hostName,  String status, @JsonKey(name: 'join_mode')  String joinMode, @JsonKey(name: 'is_boosted')  bool isBoosted, @JsonKey(name: 'boost_ends_at')  String? boostEndsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Keo() when $default != null:
return $default(_that.id,_that.title,_that.areaLabel,_that.distanceBand,_that.timeWindowStart,_that.timeWindowEnd,_that.sizeTarget,_that.slotsFilled,_that.genres,_that.hostName,_that.status,_that.joinMode,_that.isBoosted,_that.boostEndsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title, @JsonKey(name: 'area_label')  String? areaLabel, @JsonKey(name: 'distance_band')  String? distanceBand, @JsonKey(name: 'time_window_start')  String? timeWindowStart, @JsonKey(name: 'time_window_end')  String? timeWindowEnd, @JsonKey(name: 'size_target')  int sizeTarget, @JsonKey(name: 'slots_filled')  int slotsFilled,  List<String> genres, @JsonKey(name: 'host_name')  String? hostName,  String status, @JsonKey(name: 'join_mode')  String joinMode, @JsonKey(name: 'is_boosted')  bool isBoosted, @JsonKey(name: 'boost_ends_at')  String? boostEndsAt)  $default,) {final _that = this;
switch (_that) {
case _Keo():
return $default(_that.id,_that.title,_that.areaLabel,_that.distanceBand,_that.timeWindowStart,_that.timeWindowEnd,_that.sizeTarget,_that.slotsFilled,_that.genres,_that.hostName,_that.status,_that.joinMode,_that.isBoosted,_that.boostEndsAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title, @JsonKey(name: 'area_label')  String? areaLabel, @JsonKey(name: 'distance_band')  String? distanceBand, @JsonKey(name: 'time_window_start')  String? timeWindowStart, @JsonKey(name: 'time_window_end')  String? timeWindowEnd, @JsonKey(name: 'size_target')  int sizeTarget, @JsonKey(name: 'slots_filled')  int slotsFilled,  List<String> genres, @JsonKey(name: 'host_name')  String? hostName,  String status, @JsonKey(name: 'join_mode')  String joinMode, @JsonKey(name: 'is_boosted')  bool isBoosted, @JsonKey(name: 'boost_ends_at')  String? boostEndsAt)?  $default,) {final _that = this;
switch (_that) {
case _Keo() when $default != null:
return $default(_that.id,_that.title,_that.areaLabel,_that.distanceBand,_that.timeWindowStart,_that.timeWindowEnd,_that.sizeTarget,_that.slotsFilled,_that.genres,_that.hostName,_that.status,_that.joinMode,_that.isBoosted,_that.boostEndsAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Keo implements Keo {
  const _Keo({required this.id, required this.title, @JsonKey(name: 'area_label') this.areaLabel, @JsonKey(name: 'distance_band') this.distanceBand, @JsonKey(name: 'time_window_start') this.timeWindowStart, @JsonKey(name: 'time_window_end') this.timeWindowEnd, @JsonKey(name: 'size_target') this.sizeTarget = 2, @JsonKey(name: 'slots_filled') this.slotsFilled = 0, final  List<String> genres = const [], @JsonKey(name: 'host_name') this.hostName, this.status = 'open', @JsonKey(name: 'join_mode') this.joinMode = 'approval', @JsonKey(name: 'is_boosted') this.isBoosted = false, @JsonKey(name: 'boost_ends_at') this.boostEndsAt}): _genres = genres;
  factory _Keo.fromJson(Map<String, dynamic> json) => _$KeoFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey(name: 'area_label') final  String? areaLabel;
@override@JsonKey(name: 'distance_band') final  String? distanceBand;
@override@JsonKey(name: 'time_window_start') final  String? timeWindowStart;
@override@JsonKey(name: 'time_window_end') final  String? timeWindowEnd;
@override@JsonKey(name: 'size_target') final  int sizeTarget;
@override@JsonKey(name: 'slots_filled') final  int slotsFilled;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

@override@JsonKey(name: 'host_name') final  String? hostName;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'join_mode') final  String joinMode;
@override@JsonKey(name: 'is_boosted') final  bool isBoosted;
@override@JsonKey(name: 'boost_ends_at') final  String? boostEndsAt;

/// Create a copy of Keo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KeoCopyWith<_Keo> get copyWith => __$KeoCopyWithImpl<_Keo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KeoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Keo&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.areaLabel, areaLabel) || other.areaLabel == areaLabel)&&(identical(other.distanceBand, distanceBand) || other.distanceBand == distanceBand)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&(identical(other.sizeTarget, sizeTarget) || other.sizeTarget == sizeTarget)&&(identical(other.slotsFilled, slotsFilled) || other.slotsFilled == slotsFilled)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.hostName, hostName) || other.hostName == hostName)&&(identical(other.status, status) || other.status == status)&&(identical(other.joinMode, joinMode) || other.joinMode == joinMode)&&(identical(other.isBoosted, isBoosted) || other.isBoosted == isBoosted)&&(identical(other.boostEndsAt, boostEndsAt) || other.boostEndsAt == boostEndsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,areaLabel,distanceBand,timeWindowStart,timeWindowEnd,sizeTarget,slotsFilled,const DeepCollectionEquality().hash(_genres),hostName,status,joinMode,isBoosted,boostEndsAt);

@override
String toString() {
  return 'Keo(id: $id, title: $title, areaLabel: $areaLabel, distanceBand: $distanceBand, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, sizeTarget: $sizeTarget, slotsFilled: $slotsFilled, genres: $genres, hostName: $hostName, status: $status, joinMode: $joinMode, isBoosted: $isBoosted, boostEndsAt: $boostEndsAt)';
}


}

/// @nodoc
abstract mixin class _$KeoCopyWith<$Res> implements $KeoCopyWith<$Res> {
  factory _$KeoCopyWith(_Keo value, $Res Function(_Keo) _then) = __$KeoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title,@JsonKey(name: 'area_label') String? areaLabel,@JsonKey(name: 'distance_band') String? distanceBand,@JsonKey(name: 'time_window_start') String? timeWindowStart,@JsonKey(name: 'time_window_end') String? timeWindowEnd,@JsonKey(name: 'size_target') int sizeTarget,@JsonKey(name: 'slots_filled') int slotsFilled, List<String> genres,@JsonKey(name: 'host_name') String? hostName, String status,@JsonKey(name: 'join_mode') String joinMode,@JsonKey(name: 'is_boosted') bool isBoosted,@JsonKey(name: 'boost_ends_at') String? boostEndsAt
});




}
/// @nodoc
class __$KeoCopyWithImpl<$Res>
    implements _$KeoCopyWith<$Res> {
  __$KeoCopyWithImpl(this._self, this._then);

  final _Keo _self;
  final $Res Function(_Keo) _then;

/// Create a copy of Keo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? areaLabel = freezed,Object? distanceBand = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? sizeTarget = null,Object? slotsFilled = null,Object? genres = null,Object? hostName = freezed,Object? status = null,Object? joinMode = null,Object? isBoosted = null,Object? boostEndsAt = freezed,}) {
  return _then(_Keo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,areaLabel: freezed == areaLabel ? _self.areaLabel : areaLabel // ignore: cast_nullable_to_non_nullable
as String?,distanceBand: freezed == distanceBand ? _self.distanceBand : distanceBand // ignore: cast_nullable_to_non_nullable
as String?,timeWindowStart: freezed == timeWindowStart ? _self.timeWindowStart : timeWindowStart // ignore: cast_nullable_to_non_nullable
as String?,timeWindowEnd: freezed == timeWindowEnd ? _self.timeWindowEnd : timeWindowEnd // ignore: cast_nullable_to_non_nullable
as String?,sizeTarget: null == sizeTarget ? _self.sizeTarget : sizeTarget // ignore: cast_nullable_to_non_nullable
as int,slotsFilled: null == slotsFilled ? _self.slotsFilled : slotsFilled // ignore: cast_nullable_to_non_nullable
as int,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,hostName: freezed == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,joinMode: null == joinMode ? _self.joinMode : joinMode // ignore: cast_nullable_to_non_nullable
as String,isBoosted: null == isBoosted ? _self.isBoosted : isBoosted // ignore: cast_nullable_to_non_nullable
as bool,boostEndsAt: freezed == boostEndsAt ? _self.boostEndsAt : boostEndsAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
