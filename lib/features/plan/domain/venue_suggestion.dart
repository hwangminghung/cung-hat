import 'package:freezed_annotation/freezed_annotation.dart';
part 'venue_suggestion.freezed.dart';
part 'venue_suggestion.g.dart';

@freezed
abstract class VenueSuggestion with _$VenueSuggestion {
  const factory VenueSuggestion({
    required String id,
    required String name,
    required String address,
    @JsonKey(name: 'style_tag') @Default('k_style') String styleTag,
    @Default([]) List<String> photos,
    @JsonKey(name: 'distance_band') String? distanceBand,
  }) = _VenueSuggestion;
  factory VenueSuggestion.fromJson(Map<String, dynamic> j) =>
      _$VenueSuggestionFromJson(j);
}
