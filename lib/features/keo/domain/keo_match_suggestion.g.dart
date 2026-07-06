// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keo_match_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KeoMatchSuggestion _$KeoMatchSuggestionFromJson(Map<String, dynamic> json) =>
    _KeoMatchSuggestion(
      suggestionType: json['suggestion_type'] as String,
      keoId: json['keo_id'] as String?,
      title: json['title'] as String,
      areaLabel: json['area_label'] as String?,
      distanceBand: json['distance_band'] as String?,
      timeWindowStart: json['time_window_start'] as String?,
      timeWindowEnd: json['time_window_end'] as String?,
      sizeTarget: (json['size_target'] as num?)?.toInt() ?? 4,
      slotsFilled: (json['slots_filled'] as num?)?.toInt() ?? 0,
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      hostName: json['host_name'] as String?,
      joinMode: json['join_mode'] as String? ?? 'open',
      reasonLabels:
          (json['reason_labels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      proposedStart: json['proposed_start'] as String?,
      proposedEnd: json['proposed_end'] as String?,
    );

Map<String, dynamic> _$KeoMatchSuggestionToJson(_KeoMatchSuggestion instance) =>
    <String, dynamic>{
      'suggestion_type': instance.suggestionType,
      'keo_id': instance.keoId,
      'title': instance.title,
      'area_label': instance.areaLabel,
      'distance_band': instance.distanceBand,
      'time_window_start': instance.timeWindowStart,
      'time_window_end': instance.timeWindowEnd,
      'size_target': instance.sizeTarget,
      'slots_filled': instance.slotsFilled,
      'genres': instance.genres,
      'host_name': instance.hostName,
      'join_mode': instance.joinMode,
      'reason_labels': instance.reasonLabels,
      'proposed_start': instance.proposedStart,
      'proposed_end': instance.proposedEnd,
    };
