import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/moderation_repository.dart';

final moderationRepositoryProvider = Provider(
  (ref) => ModerationRepository(ref.watch(supabaseClientProvider)),
);

final openReportsProvider = FutureProvider<List<Report>>(
  (ref) => ref.watch(moderationRepositoryProvider).listReports(),
);
