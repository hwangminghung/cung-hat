import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/onboarding/data/reference_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

class _MockBuilder extends Mock implements SupabaseQueryBuilder {}

class _MockFilter extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

class _MockTransform extends Mock
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {}

/// A stubbed [PostgrestTransformBuilder] that resolves to [value] when awaited.
///
/// `.order(...)` returns a `PostgrestTransformBuilder`, which implements
/// `Future` via its own `then` rather than being a plain `Future`. So
/// `thenAnswer((_) async => value)` is a static type error (the answer must
/// return the builder, not a Future). The working pattern is to return a
/// builder whose `then` is stubbed to resolve to [value].
PostgrestTransformBuilder<List<Map<String, dynamic>>> _resolves(
  List<Map<String, dynamic>> value,
) {
  final t = _MockTransform();
  when(() => t.then<dynamic>(any(), onError: any(named: 'onError')))
      .thenAnswer((invocation) {
    final onValue = invocation.positionalArguments[0]
        as dynamic Function(List<Map<String, dynamic>>);
    return Future<List<Map<String, dynamic>>>.value(value).then<dynamic>(onValue);
  });
  return t;
}

void main() {
  test('genres() selects from music_genres ordered by sort', () async {
    final client = _MockClient();
    final qb = _MockBuilder();
    final fb = _MockFilter();
    when(() => client.from('music_genres')).thenAnswer((_) => qb);
    when(() => qb.select()).thenAnswer((_) => fb);
    when(() => fb.order('sort')).thenAnswer((_) => _resolves([
      {'id': 'vpop', 'name_vi': 'V-Pop', 'name_en': 'V-Pop', 'sort': 1},
    ]));
    final repo = ReferenceRepository(client);
    final genres = await repo.genres();
    expect(genres.single.id, 'vpop');
    expect(genres.single.nameVi, 'V-Pop');
  });
}
