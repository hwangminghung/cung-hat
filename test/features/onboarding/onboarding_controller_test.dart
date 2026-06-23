import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/onboarding/application/onboarding_controller.dart';
import 'package:cung_hat/features/onboarding/application/onboarding_providers.dart';
import 'package:cung_hat/features/onboarding/data/onboarding_repository.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/data/profile_repository.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

class _MockOnb extends Mock implements OnboardingRepository {}
class _MockProf extends Mock implements ProfileRepository {}

void main() {
  setUpAll(() => registerFallbackValue(const Profile(id: '')));

  test('submit records consents, saves profile, saves taste', () async {
    final onb = _MockOnb();
    final prof = _MockProf();
    when(() => onb.recordConsent(purpose: any(named: 'purpose'), granted: any(named: 'granted'), policyVersion: any(named: 'policyVersion'))).thenAnswer((_) async {});
    when(() => onb.saveTaste(genreIds: any(named: 'genreIds'), artistIds: any(named: 'artistIds'), songIds: any(named: 'songIds'))).thenAnswer((_) async {});
    when(() => prof.upsertMyProfile(any())).thenAnswer((_) async =>
        const Profile(id: 'u1', displayName: 'Mai', ageVerified: true, language: 'vi'));

    final c = ProviderContainer(overrides: [
      onboardingRepositoryProvider.overrideWithValue(onb),
      profileRepositoryProvider.overrideWithValue(prof),
    ]);
    addTearDown(c.dispose);

    final ctrl = c.read(onboardingControllerProvider.notifier);
    await ctrl.submit(
      displayName: 'Mai', fullName: 'Tran Mai', dob: DateTime(2000, 1, 1), bio: 'hi',
      consents: const {'location': true, 'matching': true},
      genreIds: const ['vpop'], artistIds: const ['my_tam'], songIds: const ['s2'],
    );

    verify(() => prof.upsertMyProfile(any())).called(1);
    verify(() => onb.saveTaste(genreIds: ['vpop'], artistIds: ['my_tam'], songIds: ['s2'])).called(1);
    verify(() => onb.recordConsent(purpose: 'location', granted: true, policyVersion: any(named: 'policyVersion'))).called(1);
  });
}
