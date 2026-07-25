import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/keo/domain/shared_keo.dart';
import 'package:cung_hat/features/keo/presentation/shared_keo_screen.dart';

class _MockRepo extends Mock implements KeoRepository {}

SharedKeo _sample({bool expired = false}) => SharedKeo(
  keoId: 'k1',
  title: 'Hát tối T7',
  areaLabel: 'Q1',
  timeWindowStart: '2026-07-10T19:00:00Z',
  sizeTarget: 4,
  slotsFilled: 2,
  genres: const ['vpop'],
  hostName: 'Mai',
  joinMode: 'open',
  status: 'open',
  expired: expired,
);

Future<void> _pump(
  WidgetTester tester, {
  required KeoRepository repo,
  bool signedIn = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keoRepositoryProvider.overrideWithValue(repo),
        isSignedInProvider.overrideWithValue(signedIn),
      ],
      child: const MaterialApp(home: SharedKeoScreen(token: 'tok')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('token not found shows the not-found empty state', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.resolveSharedKeo('tok')).thenAnswer((_) async => null);
    await _pump(tester, repo: repo);
    expect(find.text('Không tìm thấy kèo'), findsOneWidget);
  });

  testWidgets('expired token shows the expired empty state', (tester) async {
    final repo = _MockRepo();
    when(
      () => repo.resolveSharedKeo('tok'),
    ).thenAnswer((_) async => _sample(expired: true));
    await _pump(tester, repo: repo);
    expect(find.text('Liên kết đã hết hạn'), findsOneWidget);
  });

  testWidgets(
    'valid token renders keo details + login button when signed out',
    (tester) async {
      final repo = _MockRepo();
      when(
        () => repo.resolveSharedKeo('tok'),
      ).thenAnswer((_) async => _sample());
      await _pump(tester, repo: repo, signedIn: false);
      expect(find.text('Hát tối T7'), findsOneWidget);
      expect(find.textContaining('2/4'), findsOneWidget);
      expect(find.text('Mở · vào là tham gia'), findsOneWidget);
      expect(find.textContaining('Mai'), findsOneWidget);
      expect(find.byKey(const Key('shared_keo_login_btn')), findsOneWidget);
      expect(find.byKey(const Key('shared_keo_open_btn')), findsNothing);
    },
  );

  testWidgets('valid token shows the open button when signed in', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.resolveSharedKeo('tok')).thenAnswer((_) async => _sample());
    await _pump(tester, repo: repo, signedIn: true);
    expect(find.byKey(const Key('shared_keo_open_btn')), findsOneWidget);
    expect(find.byKey(const Key('shared_keo_login_btn')), findsNothing);
  });
}
