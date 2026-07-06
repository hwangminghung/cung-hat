// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'keo_match_suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KeoMatchSuggestion {

@JsonKey(name: 'suggestion_type') String get suggestionType;@JsonKey(name: 'keo_id') String? get keoId; String get title;@JsonKey(name: 'area_label') String? get areaLabel;@JsonKey(name: 'distance_band') String? get distanceBand;@JsonKey(name: 'time_window_start') String? get timeWindowStart;@JsonKey(name: 'time_window_end') String? get timeWindowEnd;@JsonKey(name: 'size_target') int get sizeTarget;@JsonKey(name: 'slots_filled') int get slotsFilled; List<String> get genres;@JsonKey(name: 'host_name') String? get hostName;@JsonKey(name: 'join_mode') String get joinMode;@JsonKey(name: 'reason_labels') List<String> get reasonLabels;@JsonKey(name: 'proposed_start') String? get proposedStart;@JsonKey(name: 'proposed_end') String? get proposedEnd;
/// Create a copy of KeoMatchSuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeoMatchSuggestionCopyWith<KeoMatchSuggestion> get copyWith => _$KeoMatchSuggestionCopyWithImpl<KeoMatchSuggestion>(this as KeoMatchSuggestion, _$identity);

  /// Serializes this KeoMatchSuggestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeoMatchSuggestion&&(identical(other.suggestionType, suggestionType) || other.suggestionType == suggestionType)&&(identical(other.keoId, keoId) || other.keoId == keoId)&&(identical(other.title, title) || other.title == title)&&(identical(other.areaLabel, areaLabel) || other.areaLabel == areaLabel)&&(identical(other.distanceBand, distanceBand) || other.distanceBand == distanceBand)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&(identical(other.sizeTarget, sizeTarget) || other.sizeTarget == sizeTarget)&&(identical(other.slotsFilled, slotsFilled) || other.slotsFilled == slotsFilled)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.hostName, hostName) || other.hostName == hostName)&&(identical(other.joinMode, joinMode) || other.joinMode == joinMode)&&const DeepCollectionEquality().equals(other.reasonLabels, reasonLabels)&&(identical(other.proposedStart, proposedStart) || other.proposedStart == proposedStart)&&(identical(other.proposedEnd, proposedEnd) || other.proposedEnd == proposedEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,suggestionType,keoId,title,areaLabel,distanceBand,timeWindowStart,timeWindowEnd,sizeTarget,slotsFilled,const DeepCollectionEquality().hash(genres),hostName,joinMode,const DeepCollectionEquality().hash(reasonLabels),proposedStart,proposedEnd);

@override
String toString() {
  return 'KeoMatchSuggestion(suggestionType: $suggestionType, keoId: $keoId, title: $title, areaLabel: $areaLabel, distanceBand: $distanceBand, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, sizeTarget: $sizeTarget, slotsFilled: $slotsFilled, genres: $genres, hostName: $hostName, joinMode: $joinMode, reasonLabels: $reasonLabels, proposedStart: $proposedStart, proposedEnd: $proposedEnd)';
}


}

/// @nodoc
abstract mixin class $KeoMatchSuggestionCopyWith<$Res>  {
  factory $KeoMatchSuggestionCopyWith(KeoMatchSuggestion value, $Res Function(KeoMatchSuggestion) _then) = _$KeoMatchSuggestionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'suggestion_type') String suggestionType,@JsonKey(name: 'keo_id') String? keoId, String title,@JsonKey(name: 'area_label') String? areaLabel,@JsonKey(name: 'distance_band') String? distanceBand,@JsonKey(name: 'time_window_start') String? timeWindowStart,@JsonKey(name: 'time_window_end') String? timeWindowEnd,@JsonKey(name: 'size_target') int sizeTarget,@JsonKey(name: 'slots_filled') int slotsFilled, List<String> genres,@JsonKey(name: 'host_name') String? hostName,@JsonKey(name: 'join_mode') String joinMode,@JsonKey(name: 'reason_labels') List<String> reasonLabels,@JsonKey(name: 'proposed_start') String? proposedStart,@JsonKey(name: 'proposed_end') String? proposedEnd
});




}
/// @nodoc
class _$KeoMatchSuggestionCopyWithImpl<$Res>
    implements $KeoMatchSuggestionCopyWith<$Res> {
  _$KeoMatchSuggestionCopyWithImpl(this._self, this._then);

  final KeoMatchSuggestion _self;
  final $Res Function(KeoMatchSuggestion) _then;

/// Create a copy of KeoMatchSuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? suggestionType = null,Object? keoId = freezed,Object? title = null,Object? areaLabel = freezed,Object? distanceBand = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? sizeTarget = null,Object? slotsFilled = null,Object? genres = null,Object? hostName = freezed,Object? joinMode = null,Object? reasonLabels = null,Object? proposedStart = freezed,Object? proposedEnd = freezed,}) {
  return _then(_self.copyWith(
suggestionType: null == suggestionType ? _self.suggestionType : suggestionType // ignore: cast_nullable_to_non_nullable
as String,keoId: freezed == keoId ? _self.keoId : keoId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,areaLabel: freezed == areaLabel ? _self.areaLabel : areaLabel // ignore: cast_nullable_to_non_nullable
as String?,distanceBand: freezed == distanceBand ? _self.distanceBand : distanceBand // ignore: cast_nullable_to_non_nullable
as String?,timeWindowStart: freezed == timeWindowStart ? _self.timeWindowStart : timeWindowStart // ignore: cast_nullable_to_non_nullable
as String?,timeWindowEnd: freezed == timeWindowEnd ? _self.timeWindowEnd : timeWindowEnd // ignore: cast_nullable_to_non_nullable
as String?,sizeTarget: null == sizeTarget ? _self.sizeTarget : sizeTarget // ignore: cast_nullable_to_non_nullable
as int,slotsFilled: null == slotsFilled ? _self.slotsFilled : slotsFilled // ignore: cast_nullable_to_non_nullable
as int,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,hostName: freezed == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String?,joinMode: null == joinMode ? _self.joinMode : joinMode // ignore: cast_nullable_to_non_nullable
as String,reasonLabels: null == reasonLabels ? _self.reasonLabels : reasonLabels // ignore: cast_nullable_to_non_nullable
as List<String>,proposedStart: freezed == proposedStart ? _self.proposedStart : proposedStart // ignore: cast_nullable_to_non_nullable
as String?,proposedEnd: freezed == proposedEnd ? _self.proposedEnd : proposedEnd // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [KeoMatchSuggestion].
extension KeoMatchSuggestionPatterns on KeoMatchSuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KeoMatchSuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KeoMatchSuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KeoMatchSuggestion value)  $default,){
final _that = this;
switch (_that) {
case _KeoMatchSuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KeoMatchSuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _KeoMatchSuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'suggestion_type')  String suggestionType, @JsonKey(name: 'keo_id')  String? keoId,  String title, @JsonKey(name: 'area_label')  String? areaLabel, @JsonKey(name: 'distance_band')  String? distanceBand, @JsonKey(name: 'time_window_start')  String? timeWindowStart, @JsonKey(name: 'time_window_end')  String? timeWindowEnd, @JsonKey(name: 'size_target')  int sizeTarget, @JsonKey(name: 'slots_filled')  int slotsFilled,  List<String> genres, @JsonKey(name: 'host_name')  String? hostName, @JsonKey(name: 'join_mode')  String joinMode, @JsonKey(name: 'reason_labels')  List<String> reasonLabels, @JsonKey(name: 'proposed_start')  String? proposedStart, @JsonKey(name: 'proposed_end')  String? proposedEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KeoMatchSuggestion() when $default != null:
return $default(_that.suggestionType,_that.keoId,_that.title,_that.areaLabel,_that.distanceBand,_that.timeWindowStart,_that.timeWindowEnd,_that.sizeTarget,_that.slotsFilled,_that.genres,_that.hostName,_that.joinMode,_that.reasonLabels,_that.proposedStart,_that.proposedEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'suggestion_type')  String suggestionType, @JsonKey(name: 'keo_id')  String? keoId,  String title, @JsonKey(name: 'area_label')  String? areaLabel, @JsonKey(name: 'distance_band')  String? distanceBand, @JsonKey(name: 'time_window_start')  String? timeWindowStart, @JsonKey(name: 'time_window_end')  String? timeWindowEnd, @JsonKey(name: 'size_target')  int sizeTarget, @JsonKey(name: 'slots_filled')  int slotsFilled,  List<String> genres, @JsonKey(name: 'host_name')  String? hostName, @JsonKey(name: 'join_mode')  String joinMode, @JsonKey(name: 'reason_labels')  List<String> reasonLabels, @JsonKey(name: 'proposed_start')  String? proposedStart, @JsonKey(name: 'proposed_end')  String? proposedEnd)  $default,) {final _that = this;
switch (_that) {
case _KeoMatchSuggestion():
return $default(_that.suggestionType,_that.keoId,_that.title,_that.areaLabel,_that.distanceBand,_that.timeWindowStart,_that.timeWindowEnd,_that.sizeTarget,_that.slotsFilled,_that.genres,_that.hostName,_that.joinMode,_that.reasonLabels,_that.proposedStart,_that.proposedEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'suggestion_type')  String suggestionType, @JsonKey(name: 'keo_id')  String? keoId,  String title, @JsonKey(name: 'area_label')  String? areaLabel, @JsonKey(name: 'distance_band')  String? distanceBand, @JsonKey(name: 'time_window_start')  String? timeWindowStart, @JsonKey(name: 'time_window_end')  String? timeWindowEnd, @JsonKey(name: 'size_target')  int sizeTarget, @JsonKey(name: 'slots_filled')  int slotsFilled,  List<String> genres, @JsonKey(name: 'host_name')  String? hostName, @JsonKey(name: 'join_mode')  String joinMode, @JsonKey(name: 'reason_labels')  List<String> reasonLabels, @JsonKey(name: 'proposed_start')  String? proposedStart, @JsonKey(name: 'proposed_end')  String? proposedEnd)?  $default,) {final _that = this;
switch (_that) {
case _KeoMatchSuggestion() when $default != null:
return $default(_that.suggestionType,_that.keoId,_that.title,_that.areaLabel,_that.distanceBand,_that.timeWindowStart,_that.timeWindowEnd,_that.sizeTarget,_that.slotsFilled,_that.genres,_that.hostName,_that.joinMode,_that.reasonLabels,_that.proposedStart,_that.proposedEnd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KeoMatchSuggestion implements KeoMatchSuggestion {
  const _KeoMatchSuggestion({@JsonKey(name: 'suggestion_type') required this.suggestionType, @JsonKey(name: 'keo_id') this.keoId, required this.title, @JsonKey(name: 'area_label') this.areaLabel, @JsonKey(name: 'distance_band') this.distanceBand, @JsonKey(name: 'time_window_start') this.timeWindowStart, @JsonKey(name: 'time_window_end') this.timeWindowEnd, @JsonKey(name: 'size_target') this.sizeTarget = 4, @JsonKey(name: 'slots_filled') this.slotsFilled = 0, final  List<String> genres = const [], @JsonKey(name: 'host_name') this.hostName, @JsonKey(name: 'join_mode') this.joinMode = 'open', @JsonKey(name: 'reason_labels') final  List<String> reasonLabels = const [], @JsonKey(name: 'proposed_start') this.proposedStart, @JsonKey(name: 'proposed_end') this.proposedEnd}): _genres = genres,_reasonLabels = reasonLabels;
  factory _KeoMatchSuggestion.fromJson(Map<String, dynamic> json) => _$KeoMatchSuggestionFromJson(json);

@override@JsonKey(name: 'suggestion_type') final  String suggestionType;
@override@JsonKey(name: 'keo_id') final  String? keoId;
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
@override@JsonKey(name: 'join_mode') final  String joinMode;
 final  List<String> _reasonLabels;
@override@JsonKey(name: 'reason_labels') List<String> get reasonLabels {
  if (_reasonLabels is EqualUnmodifiableListView) return _reasonLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reasonLabels);
}

@override@JsonKey(name: 'proposed_start') final  String? proposedStart;
@override@JsonKey(name: 'proposed_end') final  String? proposedEnd;

/// Create a copy of KeoMatchSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KeoMatchSuggestionCopyWith<_KeoMatchSuggestion> get copyWith => __$KeoMatchSuggestionCopyWithImpl<_KeoMatchSuggestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KeoMatchSuggestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KeoMatchSuggestion&&(identical(other.suggestionType, suggestionType) || other.suggestionType == suggestionType)&&(identical(other.keoId, keoId) || other.keoId == keoId)&&(identical(other.title, title) || other.title == title)&&(identical(other.areaLabel, areaLabel) || other.areaLabel == areaLabel)&&(identical(other.distanceBand, distanceBand) || other.distanceBand == distanceBand)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&(identical(other.sizeTarget, sizeTarget) || other.sizeTarget == sizeTarget)&&(identical(other.slotsFilled, slotsFilled) || other.slotsFilled == slotsFilled)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.hostName, hostName) || other.hostName == hostName)&&(identical(other.joinMode, joinMode) || other.joinMode == joinMode)&&const DeepCollectionEquality().equals(other._reasonLabels, _reasonLabels)&&(identical(other.proposedStart, proposedStart) || other.proposedStart == proposedStart)&&(identical(other.proposedEnd, proposedEnd) || other.proposedEnd == proposedEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,suggestionType,keoId,title,areaLabel,distanceBand,timeWindowStart,timeWindowEnd,sizeTarget,slotsFilled,const DeepCollectionEquality().hash(_genres),hostName,joinMode,const DeepCollectionEquality().hash(_reasonLabels),proposedStart,proposedEnd);

@override
String toString() {
  return 'KeoMatchSuggestion(suggestionType: $suggestionType, keoId: $keoId, title: $title, areaLabel: $areaLabel, distanceBand: $distanceBand, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, sizeTarget: $sizeTarget, slotsFilled: $slotsFilled, genres: $genres, hostName: $hostName, joinMode: $joinMode, reasonLabels: $reasonLabels, proposedStart: $proposedStart, proposedEnd: $proposedEnd)';
}


}

/// @nodoc
abstract mixin class _$KeoMatchSuggestionCopyWith<$Res> implements $KeoMatchSuggestionCopyWith<$Res> {
  factory _$KeoMatchSuggestionCopyWith(_KeoMatchSuggestion value, $Res Function(_KeoMatchSuggestion) _then) = __$KeoMatchSuggestionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'suggestion_type') String suggestionType,@JsonKey(name: 'keo_id') String? keoId, String title,@JsonKey(name: 'area_label') String? areaLabel,@JsonKey(name: 'distance_band') String? distanceBand,@JsonKey(name: 'time_window_start') String? timeWindowStart,@JsonKey(name: 'time_window_end') String? timeWindowEnd,@JsonKey(name: 'size_target') int sizeTarget,@JsonKey(name: 'slots_filled') int slotsFilled, List<String> genres,@JsonKey(name: 'host_name') String? hostName,@JsonKey(name: 'join_mode') String joinMode,@JsonKey(name: 'reason_labels') List<String> reasonLabels,@JsonKey(name: 'proposed_start') String? proposedStart,@JsonKey(name: 'proposed_end') String? proposedEnd
});




}
/// @nodoc
class __$KeoMatchSuggestionCopyWithImpl<$Res>
    implements _$KeoMatchSuggestionCopyWith<$Res> {
  __$KeoMatchSuggestionCopyWithImpl(this._self, this._then);

  final _KeoMatchSuggestion _self;
  final $Res Function(_KeoMatchSuggestion) _then;

/// Create a copy of KeoMatchSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? suggestionType = null,Object? keoId = freezed,Object? title = null,Object? areaLabel = freezed,Object? distanceBand = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? sizeTarget = null,Object? slotsFilled = null,Object? genres = null,Object? hostName = freezed,Object? joinMode = null,Object? reasonLabels = null,Object? proposedStart = freezed,Object? proposedEnd = freezed,}) {
  return _then(_KeoMatchSuggestion(
suggestionType: null == suggestionType ? _self.suggestionType : suggestionType // ignore: cast_nullable_to_non_nullable
as String,keoId: freezed == keoId ? _self.keoId : keoId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,areaLabel: freezed == areaLabel ? _self.areaLabel : areaLabel // ignore: cast_nullable_to_non_nullable
as String?,distanceBand: freezed == distanceBand ? _self.distanceBand : distanceBand // ignore: cast_nullable_to_non_nullable
as String?,timeWindowStart: freezed == timeWindowStart ? _self.timeWindowStart : timeWindowStart // ignore: cast_nullable_to_non_nullable
as String?,timeWindowEnd: freezed == timeWindowEnd ? _self.timeWindowEnd : timeWindowEnd // ignore: cast_nullable_to_non_nullable
as String?,sizeTarget: null == sizeTarget ? _self.sizeTarget : sizeTarget // ignore: cast_nullable_to_non_nullable
as int,slotsFilled: null == slotsFilled ? _self.slotsFilled : slotsFilled // ignore: cast_nullable_to_non_nullable
as int,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,hostName: freezed == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String?,joinMode: null == joinMode ? _self.joinMode : joinMode // ignore: cast_nullable_to_non_nullable
as String,reasonLabels: null == reasonLabels ? _self._reasonLabels : reasonLabels // ignore: cast_nullable_to_non_nullable
as List<String>,proposedStart: freezed == proposedStart ? _self.proposedStart : proposedStart // ignore: cast_nullable_to_non_nullable
as String?,proposedEnd: freezed == proposedEnd ? _self.proposedEnd : proposedEnd // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
