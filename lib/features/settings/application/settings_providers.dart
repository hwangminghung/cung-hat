import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(supabaseClientProvider)),
);
final myConsentsProvider = FutureProvider<Map<String, bool>>(
  (ref) => ref.watch(settingsRepositoryProvider).myConsents(),
);
