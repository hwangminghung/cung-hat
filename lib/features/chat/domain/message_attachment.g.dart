// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageAttachment _$MessageAttachmentFromJson(Map<String, dynamic> json) =>
    _MessageAttachment(
      id: json['id'] as String,
      messageId: json['message_id'] as String?,
      mediaType: json['media_type'] as String,
      bucketId: json['bucket_id'] as String,
      objectPath: json['object_path'] as String,
      thumbnailBucketId: json['thumbnail_bucket_id'] as String?,
      thumbnailPath: json['thumbnail_path'] as String?,
      mimeType: json['mime_type'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      durationMs: (json['duration_ms'] as num?)?.toInt(),
      status: json['status'] as String,
    );

Map<String, dynamic> _$MessageAttachmentToJson(_MessageAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message_id': instance.messageId,
      'media_type': instance.mediaType,
      'bucket_id': instance.bucketId,
      'object_path': instance.objectPath,
      'thumbnail_bucket_id': instance.thumbnailBucketId,
      'thumbnail_path': instance.thumbnailPath,
      'mime_type': instance.mimeType,
      'size_bytes': instance.sizeBytes,
      'width': instance.width,
      'height': instance.height,
      'duration_ms': instance.durationMs,
      'status': instance.status,
    };
