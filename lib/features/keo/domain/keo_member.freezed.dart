// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'keo_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KeoMember {

@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'display_name') String? get displayName; bool get verified; String get role;@JsonKey(name: 'join_status') String get joinStatus;
/// Create a copy of KeoMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeoMemberCopyWith<KeoMember> get copyWith => _$KeoMemberCopyWithImpl<KeoMember>(this as KeoMember, _$identity);

  /// Serializes this KeoMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeoMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinStatus, joinStatus) || other.joinStatus == joinStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,verified,role,joinStatus);

@override
String toString() {
  return 'KeoMember(userId: $userId, displayName: $displayName, verified: $verified, role: $role, joinStatus: $joinStatus)';
}


}

/// @nodoc
abstract mixin class $KeoMemberCopyWith<$Res>  {
  factory $KeoMemberCopyWith(KeoMember value, $Res Function(KeoMember) _then) = _$KeoMemberCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'display_name') String? displayName, bool verified, String role,@JsonKey(name: 'join_status') String joinStatus
});




}
/// @nodoc
class _$KeoMemberCopyWithImpl<$Res>
    implements $KeoMemberCopyWith<$Res> {
  _$KeoMemberCopyWithImpl(this._self, this._then);

  final KeoMember _self;
  final $Res Function(KeoMember) _then;

/// Create a copy of KeoMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = freezed,Object? verified = null,Object? role = null,Object? joinStatus = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinStatus: null == joinStatus ? _self.joinStatus : joinStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [KeoMember].
extension KeoMemberPatterns on KeoMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KeoMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KeoMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KeoMember value)  $default,){
final _that = this;
switch (_that) {
case _KeoMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KeoMember value)?  $default,){
final _that = this;
switch (_that) {
case _KeoMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'display_name')  String? displayName,  bool verified,  String role, @JsonKey(name: 'join_status')  String joinStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KeoMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.verified,_that.role,_that.joinStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'display_name')  String? displayName,  bool verified,  String role, @JsonKey(name: 'join_status')  String joinStatus)  $default,) {final _that = this;
switch (_that) {
case _KeoMember():
return $default(_that.userId,_that.displayName,_that.verified,_that.role,_that.joinStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'display_name')  String? displayName,  bool verified,  String role, @JsonKey(name: 'join_status')  String joinStatus)?  $default,) {final _that = this;
switch (_that) {
case _KeoMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.verified,_that.role,_that.joinStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KeoMember implements KeoMember {
  const _KeoMember({@JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'display_name') this.displayName, this.verified = false, this.role = 'member', @JsonKey(name: 'join_status') this.joinStatus = 'requested'});
  factory _KeoMember.fromJson(Map<String, dynamic> json) => _$KeoMemberFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'display_name') final  String? displayName;
@override@JsonKey() final  bool verified;
@override@JsonKey() final  String role;
@override@JsonKey(name: 'join_status') final  String joinStatus;

/// Create a copy of KeoMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KeoMemberCopyWith<_KeoMember> get copyWith => __$KeoMemberCopyWithImpl<_KeoMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KeoMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KeoMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinStatus, joinStatus) || other.joinStatus == joinStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,verified,role,joinStatus);

@override
String toString() {
  return 'KeoMember(userId: $userId, displayName: $displayName, verified: $verified, role: $role, joinStatus: $joinStatus)';
}


}

/// @nodoc
abstract mixin class _$KeoMemberCopyWith<$Res> implements $KeoMemberCopyWith<$Res> {
  factory _$KeoMemberCopyWith(_KeoMember value, $Res Function(_KeoMember) _then) = __$KeoMemberCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'display_name') String? displayName, bool verified, String role,@JsonKey(name: 'join_status') String joinStatus
});




}
/// @nodoc
class __$KeoMemberCopyWithImpl<$Res>
    implements _$KeoMemberCopyWith<$Res> {
  __$KeoMemberCopyWithImpl(this._self, this._then);

  final _KeoMember _self;
  final $Res Function(_KeoMember) _then;

/// Create a copy of KeoMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = freezed,Object? verified = null,Object? role = null,Object? joinStatus = null,}) {
  return _then(_KeoMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinStatus: null == joinStatus ? _self.joinStatus : joinStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
