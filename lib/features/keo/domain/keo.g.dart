// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Keo _$KeoFromJson(Map<String, dynamic> json) => _Keo(
  id: json['id'] as String,
  title: json['title'] as String,
  areaLabel: json['area_label'] as String?,
  distanceBand: json['distance_band'] as String?,
  timeWindowStart: json['time_window_start'] as String?,
  timeWindowEnd: json['time_window_end'] as String?,
  sizeTarget: (json['size_target'] as num?)?.toInt() ?? 2,
  slotsFilled: (json['slots_filled'] as num?)?.toInt() ?? 0,
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  hostName: json['host_name'] as String?,
  status: json['status'] as String? ?? 'open',
);

Map<String, dynamic> _$KeoToJson(_Keo instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'area_label': instance.areaLabel,
  'distance_band': instance.distanceBand,
  'time_window_start': instance.timeWindowStart,
  'time_window_end': instance.timeWindowEnd,
  'size_target': instance.sizeTarget,
  'slots_filled': instance.slotsFilled,
  'genres': instance.genres,
  'host_name': instance.hostName,
  'status': instance.status,
};
