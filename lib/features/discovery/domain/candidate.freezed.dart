// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Candidate {

 String get id;@JsonKey(name: 'display_name') String? get displayName; int? get age;@JsonKey(name: 'distance_band') String? get distanceBand;@JsonKey(name: 'shared_genres') List<String> get sharedGenres;@JsonKey(name: 'shared_baitu') List<String> get sharedBaitu; bool get verified;@JsonKey(name: 'active_today') bool get activeToday; String? get bio;
/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CandidateCopyWith<Candidate> get copyWith => _$CandidateCopyWithImpl<Candidate>(this as Candidate, _$identity);

  /// Serializes this Candidate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Candidate&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.age, age) || other.age == age)&&(identical(other.distanceBand, distanceBand) || other.distanceBand == distanceBand)&&const DeepCollectionEquality().equals(other.sharedGenres, sharedGenres)&&const DeepCollectionEquality().equals(other.sharedBaitu, sharedBaitu)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.activeToday, activeToday) || other.activeToday == activeToday)&&(identical(other.bio, bio) || other.bio == bio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,age,distanceBand,const DeepCollectionEquality().hash(sharedGenres),const DeepCollectionEquality().hash(sharedBaitu),verified,activeToday,bio);

@override
String toString() {
  return 'Candidate(id: $id, displayName: $displayName, age: $age, distanceBand: $distanceBand, sharedGenres: $sharedGenres, sharedBaitu: $sharedBaitu, verified: $verified, activeToday: $activeToday, bio: $bio)';
}


}

/// @nodoc
abstract mixin class $CandidateCopyWith<$Res>  {
  factory $CandidateCopyWith(Candidate value, $Res Function(Candidate) _then) = _$CandidateCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'display_name') String? displayName, int? age,@JsonKey(name: 'distance_band') String? distanceBand,@JsonKey(name: 'shared_genres') List<String> sharedGenres,@JsonKey(name: 'shared_baitu') List<String> sharedBaitu, bool verified,@JsonKey(name: 'active_today') bool activeToday, String? bio
});




}
/// @nodoc
class _$CandidateCopyWithImpl<$Res>
    implements $CandidateCopyWith<$Res> {
  _$CandidateCopyWithImpl(this._self, this._then);

  final Candidate _self;
  final $Res Function(Candidate) _then;

/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = freezed,Object? age = freezed,Object? distanceBand = freezed,Object? sharedGenres = null,Object? sharedBaitu = null,Object? verified = null,Object? activeToday = null,Object? bio = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,distanceBand: freezed == distanceBand ? _self.distanceBand : distanceBand // ignore: cast_nullable_to_non_nullable
as String?,sharedGenres: null == sharedGenres ? _self.sharedGenres : sharedGenres // ignore: cast_nullable_to_non_nullable
as List<String>,sharedBaitu: null == sharedBaitu ? _self.sharedBaitu : sharedBaitu // ignore: cast_nullable_to_non_nullable
as List<String>,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,activeToday: null == activeToday ? _self.activeToday : activeToday // ignore: cast_nullable_to_non_nullable
as bool,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Candidate].
extension CandidatePatterns on Candidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Candidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Candidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Candidate value)  $default,){
final _that = this;
switch (_that) {
case _Candidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Candidate value)?  $default,){
final _that = this;
switch (_that) {
case _Candidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'display_name')  String? displayName,  int? age, @JsonKey(name: 'distance_band')  String? distanceBand, @JsonKey(name: 'shared_genres')  List<String> sharedGenres, @JsonKey(name: 'shared_baitu')  List<String> sharedBaitu,  bool verified, @JsonKey(name: 'active_today')  bool activeToday,  String? bio)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Candidate() when $default != null:
return $default(_that.id,_that.displayName,_that.age,_that.distanceBand,_that.sharedGenres,_that.sharedBaitu,_that.verified,_that.activeToday,_that.bio);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'display_name')  String? displayName,  int? age, @JsonKey(name: 'distance_band')  String? distanceBand, @JsonKey(name: 'shared_genres')  List<String> sharedGenres, @JsonKey(name: 'shared_baitu')  List<String> sharedBaitu,  bool verified, @JsonKey(name: 'active_today')  bool activeToday,  String? bio)  $default,) {final _that = this;
switch (_that) {
case _Candidate():
return $default(_that.id,_that.displayName,_that.age,_that.distanceBand,_that.sharedGenres,_that.sharedBaitu,_that.verified,_that.activeToday,_that.bio);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'display_name')  String? displayName,  int? age, @JsonKey(name: 'distance_band')  String? distanceBand, @JsonKey(name: 'shared_genres')  List<String> sharedGenres, @JsonKey(name: 'shared_baitu')  List<String> sharedBaitu,  bool verified, @JsonKey(name: 'active_today')  bool activeToday,  String? bio)?  $default,) {final _that = this;
switch (_that) {
case _Candidate() when $default != null:
return $default(_that.id,_that.displayName,_that.age,_that.distanceBand,_that.sharedGenres,_that.sharedBaitu,_that.verified,_that.activeToday,_that.bio);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Candidate implements Candidate {
  const _Candidate({required this.id, @JsonKey(name: 'display_name') this.displayName, this.age, @JsonKey(name: 'distance_band') this.distanceBand, @JsonKey(name: 'shared_genres') final  List<String> sharedGenres = const [], @JsonKey(name: 'shared_baitu') final  List<String> sharedBaitu = const [], this.verified = false, @JsonKey(name: 'active_today') this.activeToday = false, this.bio}): _sharedGenres = sharedGenres,_sharedBaitu = sharedBaitu;
  factory _Candidate.fromJson(Map<String, dynamic> json) => _$CandidateFromJson(json);

@override final  String id;
@override@JsonKey(name: 'display_name') final  String? displayName;
@override final  int? age;
@override@JsonKey(name: 'distance_band') final  String? distanceBand;
 final  List<String> _sharedGenres;
@override@JsonKey(name: 'shared_genres') List<String> get sharedGenres {
  if (_sharedGenres is EqualUnmodifiableListView) return _sharedGenres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sharedGenres);
}

 final  List<String> _sharedBaitu;
@override@JsonKey(name: 'shared_baitu') List<String> get sharedBaitu {
  if (_sharedBaitu is EqualUnmodifiableListView) return _sharedBaitu;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sharedBaitu);
}

@override@JsonKey() final  bool verified;
@override@JsonKey(name: 'active_today') final  bool activeToday;
@override final  String? bio;

/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CandidateCopyWith<_Candidate> get copyWith => __$CandidateCopyWithImpl<_Candidate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CandidateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Candidate&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.age, age) || other.age == age)&&(identical(other.distanceBand, distanceBand) || other.distanceBand == distanceBand)&&const DeepCollectionEquality().equals(other._sharedGenres, _sharedGenres)&&const DeepCollectionEquality().equals(other._sharedBaitu, _sharedBaitu)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.activeToday, activeToday) || other.activeToday == activeToday)&&(identical(other.bio, bio) || other.bio == bio));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,age,distanceBand,const DeepCollectionEquality().hash(_sharedGenres),const DeepCollectionEquality().hash(_sharedBaitu),verified,activeToday,bio);

@override
String toString() {
  return 'Candidate(id: $id, displayName: $displayName, age: $age, distanceBand: $distanceBand, sharedGenres: $sharedGenres, sharedBaitu: $sharedBaitu, verified: $verified, activeToday: $activeToday, bio: $bio)';
}


}

/// @nodoc
abstract mixin class _$CandidateCopyWith<$Res> implements $CandidateCopyWith<$Res> {
  factory _$CandidateCopyWith(_Candidate value, $Res Function(_Candidate) _then) = __$CandidateCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'display_name') String? displayName, int? age,@JsonKey(name: 'distance_band') String? distanceBand,@JsonKey(name: 'shared_genres') List<String> sharedGenres,@JsonKey(name: 'shared_baitu') List<String> sharedBaitu, bool verified,@JsonKey(name: 'active_today') bool activeToday, String? bio
});




}
/// @nodoc
class __$CandidateCopyWithImpl<$Res>
    implements _$CandidateCopyWith<$Res> {
  __$CandidateCopyWithImpl(this._self, this._then);

  final _Candidate _self;
  final $Res Function(_Candidate) _then;

/// Create a copy of Candidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = freezed,Object? age = freezed,Object? distanceBand = freezed,Object? sharedGenres = null,Object? sharedBaitu = null,Object? verified = null,Object? activeToday = null,Object? bio = freezed,}) {
  return _then(_Candidate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,distanceBand: freezed == distanceBand ? _self.distanceBand : distanceBand // ignore: cast_nullable_to_non_nullable
as String?,sharedGenres: null == sharedGenres ? _self._sharedGenres : sharedGenres // ignore: cast_nullable_to_non_nullable
as List<String>,sharedBaitu: null == sharedBaitu ? _self._sharedBaitu : sharedBaitu // ignore: cast_nullable_to_non_nullable
as List<String>,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,activeToday: null == activeToday ? _self.activeToday : activeToday // ignore: cast_nullable_to_non_nullable
as bool,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
