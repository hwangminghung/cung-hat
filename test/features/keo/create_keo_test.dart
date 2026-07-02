import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/keo/presentation/create_keo_screen.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/onboarding/application/reference_providers.dart';

class _MockRepo extends Mock implements KeoRepository {}

void main() {
  test('createKeo forwards all fields', () async {
    final repo = _MockRepo();
    when(
      () => repo.createKeo(
        title: any(named: 'title'),
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
        area: any(named: 'area'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        size: any(named: 'size'),
        intent: any(named: 'intent'),
        vibe: any(named: 'vibe'),
        genres: any(named: 'genres'),
      ),
    ).thenAnswer((_) async => 'k1');
    final c = ProviderContainer(
      overrides: [keoRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    final id = await c
        .read(keoRepositoryProvider)
        .createKeo(
          title: 'X',
          lat: 10.7,
          lng: 106.7,
          area: 'Q1',
          start: DateTime(2026, 6, 21, 19),
          end: DateTime(2026, 6, 21, 22),
          size: 4,
          intent: 'fun',
          vibe: 'chill',
          genres: const ['vpop'],
        );
    expect(id, 'k1');
  });

  testWidgets(
    'create screen explains venue selection happens after kèo creation',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [genresProvider.overrideWith((ref) async => [])],
          child: const MaterialApp(home: CreateKeoScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('create_keo_venue_hint')), findsOneWidget);
    },
  );
}
