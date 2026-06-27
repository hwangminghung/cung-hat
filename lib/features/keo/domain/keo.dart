import 'package:freezed_annotation/freezed_annotation.dart';
part 'keo.freezed.dart';
part 'keo.g.dart';

@freezed
abstract class Keo with _$Keo {
  const factory Keo({
    required String id,
    required String title,
    @JsonKey(name: 'area_label') String? areaLabel,
    @JsonKey(name: 'distance_band') String? distanceBand,
    @JsonKey(name: 'time_window_start') String? timeWindowStart,
    @JsonKey(name: 'time_window_end') String? timeWindowEnd,
    @JsonKey(name: 'size_target') @Default(2) int sizeTarget,
    @JsonKey(name: 'slots_filled') @Default(0) int slotsFilled,
    @Default([]) List<String> genres,
    @JsonKey(name: 'host_name') String? hostName,
    @Default('open') String status,
    @JsonKey(name: 'join_mode') @Default('approval') String joinMode,
  }) = _Keo;
  factory Keo.fromJson(Map<String, dynamic> j) => _$KeoFromJson(j);
}
