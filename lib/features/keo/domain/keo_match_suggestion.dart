import 'package:freezed_annotation/freezed_annotation.dart';

part 'keo_match_suggestion.freezed.dart';
part 'keo_match_suggestion.g.dart';

@freezed
abstract class KeoMatchSuggestion with _$KeoMatchSuggestion {
  const factory KeoMatchSuggestion({
    @JsonKey(name: 'suggestion_type') required String suggestionType,
    @JsonKey(name: 'keo_id') String? keoId,
    required String title,
    @JsonKey(name: 'area_label') String? areaLabel,
    @JsonKey(name: 'distance_band') String? distanceBand,
    @JsonKey(name: 'time_window_start') String? timeWindowStart,
    @JsonKey(name: 'time_window_end') String? timeWindowEnd,
    @JsonKey(name: 'size_target') @Default(4) int sizeTarget,
    @JsonKey(name: 'slots_filled') @Default(0) int slotsFilled,
    @Default([]) List<String> genres,
    @JsonKey(name: 'host_name') String? hostName,
    @JsonKey(name: 'join_mode') @Default('open') String joinMode,
    @JsonKey(name: 'reason_labels') @Default([]) List<String> reasonLabels,
    @JsonKey(name: 'proposed_start') String? proposedStart,
    @JsonKey(name: 'proposed_end') String? proposedEnd,
  }) = _KeoMatchSuggestion;

  factory KeoMatchSuggestion.fromJson(Map<String, dynamic> json) =>
      _$KeoMatchSuggestionFromJson(json);
}
