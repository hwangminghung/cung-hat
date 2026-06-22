import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/profile.dart';
import 'onboarding_providers.dart';

const kPolicyVersion = 'v1';

class OnboardingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String displayName,
    required String fullName,
    required DateTime dob,
    required String bio,
    required Map<String, bool> consents,
    required List<String> genreIds,
    required List<String> artistIds,
    required List<String> songIds,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final onb = ref.read(onboardingRepositoryProvider);
      for (final e in consents.entries) {
        await onb.recordConsent(purpose: e.key, granted: e.value, policyVersion: kPolicyVersion);
      }
      final iso = '${dob.year.toString().padLeft(4, '0')}-'
          '${dob.month.toString().padLeft(2, '0')}-'
          '${dob.day.toString().padLeft(2, '0')}';
      await ref.read(profileRepositoryProvider).upsertMyProfile(
            Profile(id: '', displayName: displayName, fullName: fullName, dob: iso, bio: bio, language: 'vi'),
          );
      await onb.saveTaste(genreIds: genreIds, artistIds: artistIds, songIds: songIds);
      ref.invalidate(myProfileProvider); // router re-evaluates → leaves onboarding
    });
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);
