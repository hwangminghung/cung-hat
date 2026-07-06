/// Sanitized read-only view of a kèo resolved from a share token
/// (public.resolve_share_keo — no coordinates, no member identities beyond
/// the host's display name). Plain class, not freezed — mirrors [Plan] in
/// lib/features/plan/data/plan_repository.dart.
class SharedKeo {
  SharedKeo({
    required this.keoId,
    required this.title,
    this.areaLabel,
    this.timeWindowStart,
    required this.sizeTarget,
    required this.slotsFilled,
    this.genres = const [],
    this.hostName,
    required this.joinMode,
    required this.status,
    required this.expired,
  });

  final String keoId;
  final String title;
  final String? areaLabel;
  final String? timeWindowStart;
  final int sizeTarget;
  final int slotsFilled;
  final List<String> genres;
  final String? hostName;
  final String joinMode;
  final String status;
  final bool expired;

  factory SharedKeo.fromJson(Map<String, dynamic> j) => SharedKeo(
    keoId: j['keo_id'] as String,
    title: (j['title'] ?? '') as String,
    areaLabel: j['area_label'] as String?,
    timeWindowStart: j['time_window_start'] as String?,
    sizeTarget: (j['size_target'] as num?)?.toInt() ?? 0,
    slotsFilled: (j['slots_filled'] as num?)?.toInt() ?? 0,
    genres: j['genres'] == null
        ? const []
        : List<String>.from(j['genres'] as List),
    hostName: j['host_name'] as String?,
    joinMode: (j['join_mode'] ?? 'approval') as String,
    status: (j['status'] ?? 'open') as String,
    expired: (j['expired'] ?? false) as bool,
  );
}
