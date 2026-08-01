import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../profile/application/profile_providers.dart';
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
      // [AUDIT P1-2] MỘT lượt duy nhất: profile + consent + taste ghi trong
      // cùng transaction phía Postgres. Ba lượt rời nhau trước đây sinh được
      // tài khoản nửa vời (có profile, thiếu consent/taste) mà router lại coi
      // là onboarding đã xong. Cổng 18+ và cổng consent vẫn do server giữ.
      final iso =
          '${dob.year.toString().padLeft(4, '0')}-'
          '${dob.month.toString().padLeft(2, '0')}-'
          '${dob.day.toString().padLeft(2, '0')}';
      await ref
          .read(onboardingRepositoryProvider)
          .completeOnboarding(
            displayName: displayName,
            fullName: fullName,
            dob: iso,
            bio: bio,
            language: language,
            consents: consents,
            policyVersion: kPolicyVersion,
            genreIds: genreIds,
            artistIds: artistIds,
            songIds: songIds,
          );
      ref.invalidate(
        myProfileProvider,
      ); // router re-evaluates → leaves onboarding
    });
    if (!state.hasError) {
      // P0-3: sign_up = kích hoạt thật (profile đã tạo), fire-and-forget.
      unawaited(ref.read(analyticsProvider).logSignUp());
    }
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);
