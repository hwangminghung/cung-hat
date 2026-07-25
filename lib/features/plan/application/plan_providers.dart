import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/plan_repository.dart';
import '../domain/venue_suggestion.dart';

final planRepositoryProvider = Provider(
  (ref) => PlanRepository(ref.watch(supabaseClientProvider)),
);

final nearestVenuesProvider =
    FutureProvider.family<List<VenueSuggestion>, String>(
      (ref, keoId) => ref.watch(planRepositoryProvider).nearestVenues(keoId),
    );

final currentPlanProvider = FutureProvider.family<Plan?, String>(
  (ref, keoId) => ref.watch(planRepositoryProvider).currentPlan(keoId),
);

final keoMidpointProvider = FutureProvider.family<MapPoint?, String>(
  (ref, keoId) => ref.watch(planRepositoryProvider).getKeoMidpoint(keoId),
);

final resolveShareProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
      (ref, token) => ref.watch(planRepositoryProvider).resolveShare(token),
    );

/// Ai da xac nhan plan nay. autoDispose: mo lai man phai thay so moi —
/// nguoi khac vua bam "Dong y" trong luc minh roi man.
final planConfirmationsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>(
      (ref, planId) =>
          ref.watch(planRepositoryProvider).planConfirmations(planId),
    );
