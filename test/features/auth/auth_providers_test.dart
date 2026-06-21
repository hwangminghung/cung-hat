import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/core/providers/supabase_providers.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';

class _MockClient extends Mock implements SupabaseClient {}
class _MockAuth extends Mock implements GoTrueClient {}

void main() {
  test('isSignedInProvider is false when no session', () {
    final client = _MockClient();
    final auth = _MockAuth();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentSession).thenReturn(null);
    when(() => auth.onAuthStateChange).thenAnswer((_) => const Stream.empty());
    final container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(client),
    ]);
    addTearDown(container.dispose);
    expect(container.read(isSignedInProvider), isFalse);
  });
}
