import 'package:freezed_annotation/freezed_annotation.dart';
part 'keo_member.freezed.dart';
part 'keo_member.g.dart';

@freezed
abstract class KeoMember with _$KeoMember {
  const factory KeoMember({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') String? displayName,
    @Default(false) bool verified,
    @Default('member') String role,
    @JsonKey(name: 'join_status') @Default('requested') String joinStatus,
  }) = _KeoMember;
  factory KeoMember.fromJson(Map<String, dynamic> j) => _$KeoMemberFromJson(j);
}
