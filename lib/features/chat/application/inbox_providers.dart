import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/match_inbox.dart';

final matchInboxProvider =
    Provider((ref) => MatchInbox(ref.watch(supabaseClientProvider)));

final inboxProvider = FutureProvider<List<MatchSummary>>(
    (ref) => ref.watch(matchInboxProvider).myMatches());
