import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_attachment.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
abstract class Message with _$Message {
  const factory Message({
    required String id,
    @JsonKey(name: 'thread_id') required String threadId,
    @JsonKey(name: 'sender_id') required String senderId,
    String? body,
    @Default('text') String kind,
    @Default(false) bool hidden,
    MessageAttachment? attachment,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
