import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

/// Emits on every auth change; the router listens to this to re-evaluate redirect.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).onAuthStateChange,
);

final isSignedInProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentSession != null;
});
