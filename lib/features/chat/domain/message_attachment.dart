import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_attachment.freezed.dart';
part 'message_attachment.g.dart';

@freezed
abstract class MessageAttachment with _$MessageAttachment {
  const factory MessageAttachment({
    required String id,
    @JsonKey(name: 'message_id') String? messageId,
    @JsonKey(name: 'media_type') required String mediaType,
    @JsonKey(name: 'bucket_id') required String bucketId,
    @JsonKey(name: 'object_path') required String objectPath,
    @JsonKey(name: 'thumbnail_bucket_id') String? thumbnailBucketId,
    @JsonKey(name: 'thumbnail_path') String? thumbnailPath,
    @JsonKey(name: 'mime_type') required String mimeType,
    @JsonKey(name: 'size_bytes') required int sizeBytes,
    int? width,
    int? height,
    @JsonKey(name: 'duration_ms') int? durationMs,
    required String status,
  }) = _MessageAttachment;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      _$MessageAttachmentFromJson(json);
}
