import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/onboarding/application/onboarding_controller.dart';
import 'package:cung_hat/features/onboarding/application/onboarding_providers.dart';
import 'package:cung_hat/features/onboarding/data/onboarding_repository.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/data/profile_repository.dart';
import 'package:cung_hat/core/analytics/analytics_service.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

import '../../support/analytics_fakes.dart';

class _MockOnb extends Mock implements OnboardingRepository {}

class _MockProf extends Mock implements ProfileRepository {}

void _stubOk(_MockOnb onb) {
  when(
    () => onb.completeOnboarding(
      displayName: any(named: 'displayName'),
      fullName: any(named: 'fullName'),
      dob: any(named: 'dob'),
      bio: any(named: 'bio'),
      language: any(named: 'language'),
      consents: any(named: 'consents'),
      policyVersion: any(named: 'policyVersion'),
      genreIds: any(named: 'genreIds'),
      artistIds: any(named: 'artistIds'),
      songIds: any(named: 'songIds'),
    ),
  ).thenAnswer((_) async {});
}

void main() {
  setUpAll(() => registerFallbackValue(const Profile(id: '')));

  // [AUDIT P1-2] Trước đây submit chạy 3 lượt mạng rời nhau: profile →
  // n× consent → taste. Rớt mạng ở giữa để lại row profiles nhưng thiếu
  // consent/taste, và router coi như onboarding đã xong. Nay đúng MỘT lượt.
  test(
    'submit gọi đúng một RPC nguyên tử, không còn ghi profile rời',
    () async {
      final onb = _MockOnb();
      final prof = _MockProf();
      _stubOk(onb);

      final c = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(onb),
          profileRepositoryProvider.overrideWithValue(prof),
        ],
      );
      addTearDown(c.dispose);

      await c
          .read(onboardingControllerProvider.notifier)
          .submit(
            displayName: 'Mai',
            fullName: 'Tran Mai',
            dob: DateTime(2000, 1, 1),
            bio: 'hi',
            consents: const {'matching': true, 'cross_border': true},
            genreIds: const ['vpop'],
            artistIds: const ['my_tam'],
            songIds: const ['s2'],
          );

      verify(
        () => onb.completeOnboarding(
          displayName: 'Mai',
          fullName: 'Tran Mai',
          dob: '2000-01-01',
          bio: 'hi',
          language: 'vi',
          consents: const {'matching': true, 'cross_border': true},
          policyVersion: kPolicyVersion,
          genreIds: const ['vpop'],
          artistIds: const ['my_tam'],
          songIds: const ['s2'],
        ),
      ).called(1);
      // Ghi profile rời = đúng cái tạo ra trạng thái nửa vời.
      verifyNever(() => prof.upsertMyProfile(any()));
    },
  );

  test('dob được gửi dạng ISO yyyy-MM-dd có đệm số 0', () async {
    final onb = _MockOnb();
    _stubOk(onb);
    final c = ProviderContainer(
      overrides: [onboardingRepositoryProvider.overrideWithValue(onb)],
    );
    addTearDown(c.dispose);

    await c
        .read(onboardingControllerProvider.notifier)
        .submit(
          displayName: 'Mai',
          fullName: 'Tran Mai',
          dob: DateTime(2000, 3, 7),
          bio: '',
          consents: const {'matching': true},
          genreIds: const [],
          artistIds: const [],
          songIds: const [],
        );

    verify(
      () => onb.completeOnboarding(
        displayName: any(named: 'displayName'),
        fullName: any(named: 'fullName'),
        dob: '2000-03-07',
        bio: any(named: 'bio'),
        language: any(named: 'language'),
        consents: any(named: 'consents'),
        policyVersion: any(named: 'policyVersion'),
        genreIds: any(named: 'genreIds'),
        artistIds: any(named: 'artistIds'),
        songIds: any(named: 'songIds'),
      ),
    ).called(1);
  });

  test(
    'submit thành công → log sign_up; submit lỗi → không log (P0-3)',
    () async {
      final onb = _MockOnb();
      _stubOk(onb);

      final analytics = RecordingAnalytics();
      final c = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(onb),
          analyticsProvider.overrideWithValue(analytics),
        ],
      );
      addTearDown(c.dispose);

      final ctrl = c.read(onboardingControllerProvider.notifier);
      await ctrl.submit(
        displayName: 'Mai',
        fullName: 'Tran Mai',
        dob: DateTime(2000, 1, 1),
        bio: 'hi',
        consents: const {'matching': true, 'cross_border': true},
        genreIds: const ['vpop'],
        artistIds: const [],
        songIds: const [],
      );
      expect(analytics.events, ['sign_up']);

      // Lần submit lỗi (server 18+ gate chẳng hạn) → không log thêm.
      when(
        () => onb.completeOnboarding(
          displayName: any(named: 'displayName'),
          fullName: any(named: 'fullName'),
          dob: any(named: 'dob'),
          bio: any(named: 'bio'),
          language: any(named: 'language'),
          consents: any(named: 'consents'),
          policyVersion: any(named: 'policyVersion'),
          genreIds: any(named: 'genreIds'),
          artistIds: any(named: 'artistIds'),
          songIds: any(named: 'songIds'),
        ),
      ).thenThrow(Exception('check_violation'));
      await ctrl.submit(
        displayName: 'Mai',
        fullName: 'Tran Mai',
        dob: DateTime(2020, 1, 1),
        bio: 'hi',
        consents: const {'matching': true, 'cross_border': true},
        genreIds: const [],
        artistIds: const [],
        songIds: const [],
      );
      expect(analytics.events, ['sign_up']);
    },
  );
}
