import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/domain/keo_member.dart';
import 'package:cung_hat/features/keo/presentation/keo_detail_screen.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements KeoRepository {}

void main() {
  testWidgets('renders roster and request join button', (tester) async {
    final repo = _MockRepo();
    when(() => repo.getKeoDetail('k1')).thenAnswer(
      (_) async => const Keo(id: 'k1', title: 'Hat toi T7'),
    );
    when(() => repo.roster('k1')).thenAnswer(
      (_) async => const [
        KeoMember(
          userId: 'u1',
          displayName: 'Mai',
          verified: true,
          role: 'host',
          joinStatus: 'approved',
        )
      ],
    );
    when(() => repo.requestJoin('k1')).thenAnswer((_) async {});

    await tester.pumpWidget(ProviderScope(
      overrides: [
        keoRepositoryProvider.overrideWithValue(repo),
        myProfileProvider.overrideWith((ref) => Future<Profile?>.value(null)),
      ],
      child:
          const MaterialApp(home: KeoDetailScreen(keoId: 'k1', title: 'Hat')),
    ));

    await tester.pumpAndSettle();
    expect(find.text('Mai'), findsOneWidget);
    await tester.tap(find.byKey(const Key('request_join_btn')));
    await tester.pump();
    verify(() => repo.requestJoin('k1')).called(1);
  });

  testWidgets('free_join_limit error shows the upgrade dialog',
      (tester) async {
    final repo = _MockRepo();
    when(() => repo.getKeoDetail('k1')).thenAnswer(
      (_) async => const Keo(id: 'k1', title: 'Hat toi T7'),
    );
    when(() => repo.roster('k1')).thenAnswer((_) async => const []);
    when(() => repo.requestJoin('k1')).thenThrow(
      'PostgrestException(message: free_join_limit, code: 23514)',
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        keoRepositoryProvider.overrideWithValue(repo),
        myProfileProvider.overrideWith((ref) => Future<Profile?>.value(null)),
      ],
      child:
          const MaterialApp(home: KeoDetailScreen(keoId: 'k1', title: 'Hat')),
    ));

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request_join_btn')));
    await tester.pumpAndSettle();
    expect(find.textContaining('tham gia 1'), findsOneWidget);
  });

  testWidgets('host sees boost CTA and can apply boost', (tester) async {
    final repo = _MockRepo();
    when(() => repo.getKeoDetail('k1')).thenAnswer(
      (_) async => const Keo(
        id: 'k1',
        title: 'Hat toi T7',
        status: 'open',
        isBoosted: false,
      ),
    );
    when(() => repo.roster('k1')).thenAnswer(
      (_) async => const [
        KeoMember(
          userId: 'me',
          displayName: 'Host',
          verified: true,
          role: 'host',
          joinStatus: 'approved',
        ),
      ],
    );
    when(() => repo.applyBoost('k1')).thenAnswer((_) async {});

    await tester.pumpWidget(ProviderScope(
      overrides: [
        keoRepositoryProvider.overrideWithValue(repo),
        myProfileProvider.overrideWith(
          (ref) => Future<Profile?>.value(const Profile(
            id: 'me',
            displayName: 'Host',
            dob: '1990-01-01',
          )),
        ),
      ],
      child: const MaterialApp(
        home: KeoDetailScreen(keoId: 'k1', title: 'Hat toi T7'),
      ),
    ));

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('boost_keo_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_boost_keo_btn')));
    await tester.pumpAndSettle();

    verify(() => repo.applyBoost('k1')).called(1);
  });

  testWidgets('active boost disables boost CTA', (tester) async {
    final repo = _MockRepo();
    when(() => repo.getKeoDetail('k1')).thenAnswer(
      (_) async => const Keo(
        id: 'k1',
        title: 'Hat toi T7',
        status: 'open',
        isBoosted: true,
        boostEndsAt: '2026-07-02T12:00:00Z',
      ),
    );
    when(() => repo.roster('k1')).thenAnswer(
      (_) async => const [
        KeoMember(
          userId: 'me',
          displayName: 'Host',
          verified: true,
          role: 'host',
          joinStatus: 'approved',
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        keoRepositoryProvider.overrideWithValue(repo),
        myProfileProvider.overrideWith(
          (ref) => Future<Profile?>.value(const Profile(
            id: 'me',
            displayName: 'Host',
            dob: '1990-01-01',
          )),
        ),
      ],
      child: const MaterialApp(
        home: KeoDetailScreen(keoId: 'k1', title: 'Hat toi T7'),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('boost_keo_btn')), findsNothing);
    expect(find.text('Keo dang duoc day'), findsOneWidget);
  });
}
