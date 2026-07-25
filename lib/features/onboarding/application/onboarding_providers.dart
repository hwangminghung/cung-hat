import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider(
  (ref) => OnboardingRepository(ref.watch(supabaseClientProvider)),
);
