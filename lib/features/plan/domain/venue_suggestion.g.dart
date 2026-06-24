// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VenueSuggestion _$VenueSuggestionFromJson(Map<String, dynamic> json) =>
    _VenueSuggestion(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      styleTag: json['style_tag'] as String? ?? 'k_style',
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      distanceBand: json['distance_band'] as String?,
    );

Map<String, dynamic> _$VenueSuggestionToJson(_VenueSuggestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'style_tag': instance.styleTag,
      'photos': instance.photos,
      'distance_band': instance.distanceBand,
    };
