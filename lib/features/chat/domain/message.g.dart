// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: json['id'] as String,
  threadId: json['thread_id'] as String,
  senderId: json['sender_id'] as String,
  body: json['body'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'thread_id': instance.threadId,
  'sender_id': instance.senderId,
  'body': instance.body,
  'created_at': instance.createdAt,
};
