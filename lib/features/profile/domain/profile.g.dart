// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  displayName: json['display_name'] as String?,
  fullName: json['full_name'] as String?,
  dob: json['dob'] as String?,
  ageVerified: json['age_verified'] as bool? ?? false,
  bio: json['bio'] as String?,
  language: json['language'] as String? ?? 'vi',
  photoPaths:
      (json['photo_paths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  prompts:
      (json['prompts'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const <Map<String, dynamic>>[],
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'display_name': instance.displayName,
  'full_name': instance.fullName,
  'dob': instance.dob,
  'age_verified': instance.ageVerified,
  'bio': instance.bio,
  'language': instance.language,
  'photo_paths': instance.photoPaths,
  'prompts': instance.prompts,
};
