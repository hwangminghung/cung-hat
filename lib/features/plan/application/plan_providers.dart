import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/plan_repository.dart';
import '../domain/venue_suggestion.dart';

final planRepositoryProvider =
    Provider((ref) => PlanRepository(ref.watch(supabaseClientProvider)));

final nearestVenuesProvider = FutureProvider.family<List<VenueSuggestion>, String>(
    (ref, keoId) => ref.watch(planRepositoryProvider).nearestVenues(keoId));
