import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/billing_repository.dart';

final billingRepositoryProvider =
    Provider((ref) => BillingRepository(ref.watch(supabaseClientProvider)));

final entitlementsProvider = FutureProvider<Set<String>>((ref) async {
  final list = await ref.watch(billingRepositoryProvider).myEntitlements();
  return list.map((e) => e['feature'] as String).toSet();
});

/// Convenience gate used by features (e.g. see-who-liked).
final hasEntitlementProvider = Provider.family<bool, String>((ref, feature) =>
    ref.watch(entitlementsProvider).maybeWhen(data: (s) => s.contains(feature), orElse: () => false));
