import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/app/home_shell.dart';
import 'package:cung_hat/core/theme/app_spacing.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile_completion.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';
import 'package:cung_hat/shared/widgets/hard_card.dart';

class _FakeLocationService extends Mock implements LocationService {}

Future<void> _pumpProfileTab(
  WidgetTester tester, {
  required Profile profile,
  required TasteCounts taste,
}) async {
  final fakeLoc = _FakeLocationService();
  when(
    () => fakeLoc.captureAndPush(),
  ).thenAnswer((_) async => LocationCaptureStatus.success);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        candidatesProvider(
          null,
        ).overrideWith((ref) => Future.value(<Candidate>[])),
        locationServiceProvider.overrideWithValue(fakeLoc),
        openKeosProvider.overrideWith((ref) => Future.value(<Keo>[])),
        myProfileProvider.overrideWith((ref) => Future.value(profile)),
        myTasteCountsProvider.overrideWith((ref) => Future.value(taste)),
      ],
      child: const MaterialApp(home: HomeShell()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Hồ sơ'));
  await tester.pumpAndSettle();
}

void main() {
  const empty = Profile(id: 'u');
  test('hồ sơ trống = 0%, đủ = 100%', () {
    expect(profileCompletion(empty, const TasteCounts(0, 0, 0)).percent, 0);
    final full = empty.copyWith(
      bio: 'x',
      photoPaths: ['a', 'b', 'c'],
      prompts: [
        {'prompt_id': 'p1', 'answer': 'a'},
        {'prompt_id': 'p2', 'answer': 'b'},
      ],
    );
    expect(profileCompletion(full, const TasteCounts(3, 1, 3)).percent, 100);
  });
  test('1 ảnh + bio = 35%', () {
    final p = empty.copyWith(bio: 'x', photoPaths: ['a']);
    expect(profileCompletion(p, const TasteCounts(0, 0, 0)).percent, 35);
  });
  test('gợi ý kế tiếp: thiếu ảnh đứng đầu', () {
    final r = profileCompletion(empty, const TasteCounts(0, 0, 0));
    expect(r.nextSteps.first, contains('ảnh'));
    expect(r.nextSteps.length, lessThanOrEqualTo(2));
  });

  testWidgets('thẻ hiển thị % và tối đa 2 gợi ý khi hồ sơ chưa đầy', (
    tester,
  ) async {
    final partial = empty.copyWith(bio: 'x', photoPaths: ['a']);
    await _pumpProfileTab(
      tester,
      profile: partial,
      taste: const TasteCounts(0, 0, 0),
    );
    expect(find.byKey(const Key('completion_card')), findsOneWidget);
    expect(find.text('Hồ sơ hoàn thiện 35%'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('completion_card')),
        matching: find.byIcon(Icons.arrow_circle_up_rounded),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('thẻ ẩn khi hồ sơ đã 100% without leaving a double gap', (
    tester,
  ) async {
    final full = empty.copyWith(
      bio: 'x',
      photoPaths: ['a', 'b', 'c'],
      prompts: [
        {'prompt_id': 'p1', 'answer': 'a'},
        {'prompt_id': 'p2', 'answer': 'b'},
      ],
    );
    await _pumpProfileTab(
      tester,
      profile: full,
      taste: const TasteCounts(3, 1, 3),
    );
    expect(find.byKey(const Key('completion_card')), findsNothing);

    final cards = find.descendant(
      of: find.byKey(const Key('screen_18_profile')),
      matching: find.byType(HardCard),
    );
    final identityBottom = tester.getBottomLeft(cards.at(0)).dy;
    final firstActionTop = tester.getTopLeft(cards.at(1)).dy;
    expect(firstActionTop - identityBottom, AppSpacing.lg);
  });
}
