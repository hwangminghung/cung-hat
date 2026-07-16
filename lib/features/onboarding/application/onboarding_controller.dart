import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/analytics_service.dart';
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
    String language = 'vi',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Profile upsert first: enforces the server-side 18+ gate (raises check_violation)
      // before any consent/taste side-effect is persisted (fail-fast).
      final iso = '${dob.year.toString().padLeft(4, '0')}-'
          '${dob.month.toString().padLeft(2, '0')}-'
          '${dob.day.toString().padLeft(2, '0')}';
      await ref.read(profileRepositoryProvider).upsertMyProfile(
            Profile(id: '', displayName: displayName, fullName: fullName, dob: iso, bio: bio, language: language),
          );
      final onb = ref.read(onboardingRepositoryProvider);
      for (final e in consents.entries) {
        await onb.recordConsent(purpose: e.key, granted: e.value, policyVersion: kPolicyVersion);
      }
      await onb.saveTaste(genreIds: genreIds, artistIds: artistIds, songIds: songIds);
      ref.invalidate(myProfileProvider); // router re-evaluates → leaves onboarding
    });
    if (!state.hasError) {
      // P0-3: sign_up = kích hoạt thật (profile đã tạo), fire-and-forget.
      unawaited(ref.read(analyticsProvider).logSignUp());
    }
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);
