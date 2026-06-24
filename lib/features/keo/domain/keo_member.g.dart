// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keo_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KeoMember _$KeoMemberFromJson(Map<String, dynamic> json) => _KeoMember(
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String?,
  verified: json['verified'] as bool? ?? false,
  role: json['role'] as String? ?? 'member',
  joinStatus: json['join_status'] as String? ?? 'requested',
);

Map<String, dynamic> _$KeoMemberToJson(_KeoMember instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'verified': instance.verified,
      'role': instance.role,
      'join_status': instance.joinStatus,
    };
