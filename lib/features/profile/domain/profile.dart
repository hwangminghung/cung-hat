import 'package:freezed_annotation/freezed_annotation.dart';
part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'full_name') String? fullName,
    String? dob,
    @JsonKey(name: 'age_verified') @Default(false) bool ageVerified,
    String? bio,
    @Default('vi') String language,
    @JsonKey(name: 'photo_paths') @Default(<String>[]) List<String> photoPaths,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
