import 'package:supabase_flutter/supabase_flutter.dart';

class MatchSummary {
  MatchSummary({
    required this.matchId,
    required this.otherId,
    required this.otherName,
    required this.unread,
  });
  final String matchId;
  final String otherId;
  final String otherName;
  final int unread;
  factory MatchSummary.fromJson(Map<String, dynamic> j) => MatchSummary(
        matchId: j['match_id'] as String,
        otherId: j['other_id'] as String,
        otherName: (j['other_name'] ?? '') as String,
        unread: (j['unread'] ?? 0) as int,
      );
}

class MatchInbox {
  MatchInbox(this._client);
  final SupabaseClient _client;
  Future<List<MatchSummary>> myMatches() async {
    final rows = await _client.rpc('get_my_matches');
    return (rows as List)
        .map((e) => MatchSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
