// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_suggestion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VenueSuggestion {

 String get id; String get name; String get address;@JsonKey(name: 'style_tag') String get styleTag; List<String> get photos;@JsonKey(name: 'distance_band') String? get distanceBand;
/// Create a copy of VenueSuggestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueSuggestionCopyWith<VenueSuggestion> get copyWith => _$VenueSuggestionCopyWithImpl<VenueSuggestion>(this as VenueSuggestion, _$identity);

  /// Serializes this VenueSuggestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VenueSuggestion&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.styleTag, styleTag) || other.styleTag == styleTag)&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.distanceBand, distanceBand) || other.distanceBand == distanceBand));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,styleTag,const DeepCollectionEquality().hash(photos),distanceBand);

@override
String toString() {
  return 'VenueSuggestion(id: $id, name: $name, address: $address, styleTag: $styleTag, photos: $photos, distanceBand: $distanceBand)';
}


}

/// @nodoc
abstract mixin class $VenueSuggestionCopyWith<$Res>  {
  factory $VenueSuggestionCopyWith(VenueSuggestion value, $Res Function(VenueSuggestion) _then) = _$VenueSuggestionCopyWithImpl;
@useResult
$Res call({
 String id, String name, String address,@JsonKey(name: 'style_tag') String styleTag, List<String> photos,@JsonKey(name: 'distance_band') String? distanceBand
});




}
/// @nodoc
class _$VenueSuggestionCopyWithImpl<$Res>
    implements $VenueSuggestionCopyWith<$Res> {
  _$VenueSuggestionCopyWithImpl(this._self, this._then);

  final VenueSuggestion _self;
  final $Res Function(VenueSuggestion) _then;

/// Create a copy of VenueSuggestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? address = null,Object? styleTag = null,Object? photos = null,Object? distanceBand = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,styleTag: null == styleTag ? _self.styleTag : styleTag // ignore: cast_nullable_to_non_nullable
as String,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,distanceBand: freezed == distanceBand ? _self.distanceBand : distanceBand // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VenueSuggestion].
extension VenueSuggestionPatterns on VenueSuggestion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VenueSuggestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VenueSuggestion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VenueSuggestion value)  $default,){
final _that = this;
switch (_that) {
case _VenueSuggestion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VenueSuggestion value)?  $default,){
final _that = this;
switch (_that) {
case _VenueSuggestion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String address, @JsonKey(name: 'style_tag')  String styleTag,  List<String> photos, @JsonKey(name: 'distance_band')  String? distanceBand)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VenueSuggestion() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.styleTag,_that.photos,_that.distanceBand);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String address, @JsonKey(name: 'style_tag')  String styleTag,  List<String> photos, @JsonKey(name: 'distance_band')  String? distanceBand)  $default,) {final _that = this;
switch (_that) {
case _VenueSuggestion():
return $default(_that.id,_that.name,_that.address,_that.styleTag,_that.photos,_that.distanceBand);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String address, @JsonKey(name: 'style_tag')  String styleTag,  List<String> photos, @JsonKey(name: 'distance_band')  String? distanceBand)?  $default,) {final _that = this;
switch (_that) {
case _VenueSuggestion() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.styleTag,_that.photos,_that.distanceBand);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VenueSuggestion implements VenueSuggestion {
  const _VenueSuggestion({required this.id, required this.name, required this.address, @JsonKey(name: 'style_tag') this.styleTag = 'k_style', final  List<String> photos = const [], @JsonKey(name: 'distance_band') this.distanceBand}): _photos = photos;
  factory _VenueSuggestion.fromJson(Map<String, dynamic> json) => _$VenueSuggestionFromJson(json);

@override final  String id;
@override final  String name;
@override final  String address;
@override@JsonKey(name: 'style_tag') final  String styleTag;
 final  List<String> _photos;
@override@JsonKey() List<String> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override@JsonKey(name: 'distance_band') final  String? distanceBand;

/// Create a copy of VenueSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueSuggestionCopyWith<_VenueSuggestion> get copyWith => __$VenueSuggestionCopyWithImpl<_VenueSuggestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VenueSuggestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VenueSuggestion&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.styleTag, styleTag) || other.styleTag == styleTag)&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.distanceBand, distanceBand) || other.distanceBand == distanceBand));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,styleTag,const DeepCollectionEquality().hash(_photos),distanceBand);

@override
String toString() {
  return 'VenueSuggestion(id: $id, name: $name, address: $address, styleTag: $styleTag, photos: $photos, distanceBand: $distanceBand)';
}


}

/// @nodoc
abstract mixin class _$VenueSuggestionCopyWith<$Res> implements $VenueSuggestionCopyWith<$Res> {
  factory _$VenueSuggestionCopyWith(_VenueSuggestion value, $Res Function(_VenueSuggestion) _then) = __$VenueSuggestionCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String address,@JsonKey(name: 'style_tag') String styleTag, List<String> photos,@JsonKey(name: 'distance_band') String? distanceBand
});




}
/// @nodoc
class __$VenueSuggestionCopyWithImpl<$Res>
    implements _$VenueSuggestionCopyWith<$Res> {
  __$VenueSuggestionCopyWithImpl(this._self, this._then);

  final _VenueSuggestion _self;
  final $Res Function(_VenueSuggestion) _then;

/// Create a copy of VenueSuggestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? address = null,Object? styleTag = null,Object? photos = null,Object? distanceBand = freezed,}) {
  return _then(_VenueSuggestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,styleTag: null == styleTag ? _self.styleTag : styleTag // ignore: cast_nullable_to_non_nullable
as String,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<String>,distanceBand: freezed == distanceBand ? _self.distanceBand : distanceBand // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
