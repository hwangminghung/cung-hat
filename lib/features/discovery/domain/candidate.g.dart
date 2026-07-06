// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Candidate _$CandidateFromJson(Map<String, dynamic> json) => _Candidate(
  id: json['id'] as String,
  displayName: json['display_name'] as String?,
  age: (json['age'] as num?)?.toInt(),
  distanceBand: json['distance_band'] as String?,
  sharedGenres:
      (json['shared_genres'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  sharedBaitu:
      (json['shared_baitu'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  verified: json['verified'] as bool? ?? false,
  activeToday: json['active_today'] as bool? ?? false,
  bio: json['bio'] as String?,
  prompts:
      (json['prompts'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const <Map<String, dynamic>>[],
);

Map<String, dynamic> _$CandidateToJson(_Candidate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'age': instance.age,
      'distance_band': instance.distanceBand,
      'shared_genres': instance.sharedGenres,
      'shared_baitu': instance.sharedBaitu,
      'verified': instance.verified,
      'active_today': instance.activeToday,
      'bio': instance.bio,
      'prompts': instance.prompts,
    };
