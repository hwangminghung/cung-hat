import 'package:freezed_annotation/freezed_annotation.dart';
part 'candidate.freezed.dart';
part 'candidate.g.dart';

@freezed
abstract class Candidate with _$Candidate {
  const factory Candidate({
    required String id,
    @JsonKey(name: 'display_name') String? displayName,
    int? age,
    @JsonKey(name: 'distance_band') String? distanceBand,
    @JsonKey(name: 'shared_genres') @Default([]) List<String> sharedGenres,
    @JsonKey(name: 'shared_baitu') @Default([]) List<String> sharedBaitu,
    @Default(false) bool verified,
    @JsonKey(name: 'active_today') @Default(false) bool activeToday,
  }) = _Candidate;
  factory Candidate.fromJson(Map<String, dynamic> j) => _$CandidateFromJson(j);
}
