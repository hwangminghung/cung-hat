import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/candidate_card.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';

void main() {
  testWidgets('card shows name, distance band, and a monogram when no photo', (tester) async {
    // CandidateCard now embeds PhotoCarousel (a ConsumerWidget) which watches
    // signedUrlsProvider(candidate.id) → photoRepositoryProvider → Supabase.
    // Override the family instance with an empty list so it degrades to the
    // monogram fallback without touching the uninitialized Supabase client.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        signedUrlsProvider('u2').overrideWith((ref) async => const <String>[]),
      ],
      child: const MaterialApp(home: Scaffold(body: CandidateCard(
        candidate: Candidate(id: 'u2', displayName: 'Linh', age: 24,
          distanceBand: '1-3', sharedBaitu: ['s2'], verified: true),
      ))),
    ));
    expect(find.text('Linh, 24'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
    expect(find.text('L'), findsOneWidget); // monogram fallback (no photo)
  });
}
