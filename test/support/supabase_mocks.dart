import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock Supabase client for repository tests.
class MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockFilterBuilder extends Mock
    implements PostgrestFilterBuilder<dynamic> {}

/// A stubbed [PostgrestFilterBuilder] that resolves to [value] when awaited.
///
/// supabase's `client.rpc(...)` and query builders return a
/// `PostgrestFilterBuilder` — which implements `Future` via its own `then`,
/// NOT a plain `Future`. So in tests you can use neither
/// `thenAnswer((_) async => value)` (static type error: the answer must return a
/// builder, not a Future) nor `thenReturn(future)` (mocktail rejects returning a
/// Future). The working pattern is to return a builder whose `then` is stubbed:
///
/// ```dart
/// when(() => client.rpc('my_fn', params: any(named: 'params')))
///     .thenAnswer((_) => rpcOk(<String, dynamic>{'id': 'u1'}));
/// ```
///
/// [value] may be a Map, a List, null, or any value the awaited builder should
/// resolve to (mirroring what PostgREST returns for the RPC).
PostgrestFilterBuilder<dynamic> rpcOk(dynamic value) {
  final builder = _MockFilterBuilder();
  when(
    () => builder.then<dynamic>(any(), onError: any(named: 'onError')),
  ).thenAnswer((invocation) {
    final onValue =
        invocation.positionalArguments[0] as dynamic Function(dynamic);
    return Future<dynamic>.value(value).then<dynamic>(onValue);
  });
  return builder;
}
