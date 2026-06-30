// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageAttachment {

 String get id;@JsonKey(name: 'message_id') String? get messageId;@JsonKey(name: 'media_type') String get mediaType;@JsonKey(name: 'bucket_id') String get bucketId;@JsonKey(name: 'object_path') String get objectPath;@JsonKey(name: 'thumbnail_bucket_id') String? get thumbnailBucketId;@JsonKey(name: 'thumbnail_path') String? get thumbnailPath;@JsonKey(name: 'mime_type') String get mimeType;@JsonKey(name: 'size_bytes') int get sizeBytes; int? get width; int? get height;@JsonKey(name: 'duration_ms') int? get durationMs; String get status;
/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageAttachmentCopyWith<MessageAttachment> get copyWith => _$MessageAttachmentCopyWithImpl<MessageAttachment>(this as MessageAttachment, _$identity);

  /// Serializes this MessageAttachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.bucketId, bucketId) || other.bucketId == bucketId)&&(identical(other.objectPath, objectPath) || other.objectPath == objectPath)&&(identical(other.thumbnailBucketId, thumbnailBucketId) || other.thumbnailBucketId == thumbnailBucketId)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,messageId,mediaType,bucketId,objectPath,thumbnailBucketId,thumbnailPath,mimeType,sizeBytes,width,height,durationMs,status);

@override
String toString() {
  return 'MessageAttachment(id: $id, messageId: $messageId, mediaType: $mediaType, bucketId: $bucketId, objectPath: $objectPath, thumbnailBucketId: $thumbnailBucketId, thumbnailPath: $thumbnailPath, mimeType: $mimeType, sizeBytes: $sizeBytes, width: $width, height: $height, durationMs: $durationMs, status: $status)';
}


}

/// @nodoc
abstract mixin class $MessageAttachmentCopyWith<$Res>  {
  factory $MessageAttachmentCopyWith(MessageAttachment value, $Res Function(MessageAttachment) _then) = _$MessageAttachmentCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'message_id') String? messageId,@JsonKey(name: 'media_type') String mediaType,@JsonKey(name: 'bucket_id') String bucketId,@JsonKey(name: 'object_path') String objectPath,@JsonKey(name: 'thumbnail_bucket_id') String? thumbnailBucketId,@JsonKey(name: 'thumbnail_path') String? thumbnailPath,@JsonKey(name: 'mime_type') String mimeType,@JsonKey(name: 'size_bytes') int sizeBytes, int? width, int? height,@JsonKey(name: 'duration_ms') int? durationMs, String status
});




}
/// @nodoc
class _$MessageAttachmentCopyWithImpl<$Res>
    implements $MessageAttachmentCopyWith<$Res> {
  _$MessageAttachmentCopyWithImpl(this._self, this._then);

  final MessageAttachment _self;
  final $Res Function(MessageAttachment) _then;

/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? messageId = freezed,Object? mediaType = null,Object? bucketId = null,Object? objectPath = null,Object? thumbnailBucketId = freezed,Object? thumbnailPath = freezed,Object? mimeType = null,Object? sizeBytes = null,Object? width = freezed,Object? height = freezed,Object? durationMs = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,messageId: freezed == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String?,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,bucketId: null == bucketId ? _self.bucketId : bucketId // ignore: cast_nullable_to_non_nullable
as String,objectPath: null == objectPath ? _self.objectPath : objectPath // ignore: cast_nullable_to_non_nullable
as String,thumbnailBucketId: freezed == thumbnailBucketId ? _self.thumbnailBucketId : thumbnailBucketId // ignore: cast_nullable_to_non_nullable
as String?,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageAttachment].
extension MessageAttachmentPatterns on MessageAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageAttachment value)  $default,){
final _that = this;
switch (_that) {
case _MessageAttachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'message_id')  String? messageId, @JsonKey(name: 'media_type')  String mediaType, @JsonKey(name: 'bucket_id')  String bucketId, @JsonKey(name: 'object_path')  String objectPath, @JsonKey(name: 'thumbnail_bucket_id')  String? thumbnailBucketId, @JsonKey(name: 'thumbnail_path')  String? thumbnailPath, @JsonKey(name: 'mime_type')  String mimeType, @JsonKey(name: 'size_bytes')  int sizeBytes,  int? width,  int? height, @JsonKey(name: 'duration_ms')  int? durationMs,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
return $default(_that.id,_that.messageId,_that.mediaType,_that.bucketId,_that.objectPath,_that.thumbnailBucketId,_that.thumbnailPath,_that.mimeType,_that.sizeBytes,_that.width,_that.height,_that.durationMs,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'message_id')  String? messageId, @JsonKey(name: 'media_type')  String mediaType, @JsonKey(name: 'bucket_id')  String bucketId, @JsonKey(name: 'object_path')  String objectPath, @JsonKey(name: 'thumbnail_bucket_id')  String? thumbnailBucketId, @JsonKey(name: 'thumbnail_path')  String? thumbnailPath, @JsonKey(name: 'mime_type')  String mimeType, @JsonKey(name: 'size_bytes')  int sizeBytes,  int? width,  int? height, @JsonKey(name: 'duration_ms')  int? durationMs,  String status)  $default,) {final _that = this;
switch (_that) {
case _MessageAttachment():
return $default(_that.id,_that.messageId,_that.mediaType,_that.bucketId,_that.objectPath,_that.thumbnailBucketId,_that.thumbnailPath,_that.mimeType,_that.sizeBytes,_that.width,_that.height,_that.durationMs,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'message_id')  String? messageId, @JsonKey(name: 'media_type')  String mediaType, @JsonKey(name: 'bucket_id')  String bucketId, @JsonKey(name: 'object_path')  String objectPath, @JsonKey(name: 'thumbnail_bucket_id')  String? thumbnailBucketId, @JsonKey(name: 'thumbnail_path')  String? thumbnailPath, @JsonKey(name: 'mime_type')  String mimeType, @JsonKey(name: 'size_bytes')  int sizeBytes,  int? width,  int? height, @JsonKey(name: 'duration_ms')  int? durationMs,  String status)?  $default,) {final _that = this;
switch (_that) {
case _MessageAttachment() when $default != null:
return $default(_that.id,_that.messageId,_that.mediaType,_that.bucketId,_that.objectPath,_that.thumbnailBucketId,_that.thumbnailPath,_that.mimeType,_that.sizeBytes,_that.width,_that.height,_that.durationMs,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageAttachment implements MessageAttachment {
  const _MessageAttachment({required this.id, @JsonKey(name: 'message_id') this.messageId, @JsonKey(name: 'media_type') required this.mediaType, @JsonKey(name: 'bucket_id') required this.bucketId, @JsonKey(name: 'object_path') required this.objectPath, @JsonKey(name: 'thumbnail_bucket_id') this.thumbnailBucketId, @JsonKey(name: 'thumbnail_path') this.thumbnailPath, @JsonKey(name: 'mime_type') required this.mimeType, @JsonKey(name: 'size_bytes') required this.sizeBytes, this.width, this.height, @JsonKey(name: 'duration_ms') this.durationMs, required this.status});
  factory _MessageAttachment.fromJson(Map<String, dynamic> json) => _$MessageAttachmentFromJson(json);

@override final  String id;
@override@JsonKey(name: 'message_id') final  String? messageId;
@override@JsonKey(name: 'media_type') final  String mediaType;
@override@JsonKey(name: 'bucket_id') final  String bucketId;
@override@JsonKey(name: 'object_path') final  String objectPath;
@override@JsonKey(name: 'thumbnail_bucket_id') final  String? thumbnailBucketId;
@override@JsonKey(name: 'thumbnail_path') final  String? thumbnailPath;
@override@JsonKey(name: 'mime_type') final  String mimeType;
@override@JsonKey(name: 'size_bytes') final  int sizeBytes;
@override final  int? width;
@override final  int? height;
@override@JsonKey(name: 'duration_ms') final  int? durationMs;
@override final  String status;

/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageAttachmentCopyWith<_MessageAttachment> get copyWith => __$MessageAttachmentCopyWithImpl<_MessageAttachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageAttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.bucketId, bucketId) || other.bucketId == bucketId)&&(identical(other.objectPath, objectPath) || other.objectPath == objectPath)&&(identical(other.thumbnailBucketId, thumbnailBucketId) || other.thumbnailBucketId == thumbnailBucketId)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,messageId,mediaType,bucketId,objectPath,thumbnailBucketId,thumbnailPath,mimeType,sizeBytes,width,height,durationMs,status);

@override
String toString() {
  return 'MessageAttachment(id: $id, messageId: $messageId, mediaType: $mediaType, bucketId: $bucketId, objectPath: $objectPath, thumbnailBucketId: $thumbnailBucketId, thumbnailPath: $thumbnailPath, mimeType: $mimeType, sizeBytes: $sizeBytes, width: $width, height: $height, durationMs: $durationMs, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MessageAttachmentCopyWith<$Res> implements $MessageAttachmentCopyWith<$Res> {
  factory _$MessageAttachmentCopyWith(_MessageAttachment value, $Res Function(_MessageAttachment) _then) = __$MessageAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'message_id') String? messageId,@JsonKey(name: 'media_type') String mediaType,@JsonKey(name: 'bucket_id') String bucketId,@JsonKey(name: 'object_path') String objectPath,@JsonKey(name: 'thumbnail_bucket_id') String? thumbnailBucketId,@JsonKey(name: 'thumbnail_path') String? thumbnailPath,@JsonKey(name: 'mime_type') String mimeType,@JsonKey(name: 'size_bytes') int sizeBytes, int? width, int? height,@JsonKey(name: 'duration_ms') int? durationMs, String status
});




}
/// @nodoc
class __$MessageAttachmentCopyWithImpl<$Res>
    implements _$MessageAttachmentCopyWith<$Res> {
  __$MessageAttachmentCopyWithImpl(this._self, this._then);

  final _MessageAttachment _self;
  final $Res Function(_MessageAttachment) _then;

/// Create a copy of MessageAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? messageId = freezed,Object? mediaType = null,Object? bucketId = null,Object? objectPath = null,Object? thumbnailBucketId = freezed,Object? thumbnailPath = freezed,Object? mimeType = null,Object? sizeBytes = null,Object? width = freezed,Object? height = freezed,Object? durationMs = freezed,Object? status = null,}) {
  return _then(_MessageAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,messageId: freezed == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String?,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,bucketId: null == bucketId ? _self.bucketId : bucketId // ignore: cast_nullable_to_non_nullable
as String,objectPath: null == objectPath ? _self.objectPath : objectPath // ignore: cast_nullable_to_non_nullable
as String,thumbnailBucketId: freezed == thumbnailBucketId ? _self.thumbnailBucketId : thumbnailBucketId // ignore: cast_nullable_to_non_nullable
as String?,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
