import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/billing_repository.dart';

final billingRepositoryProvider = Provider(
  (ref) => BillingRepository(ref.watch(supabaseClientProvider)),
);

final entitlementsProvider = FutureProvider<Set<String>>((ref) async {
  final list = await ref.watch(billingRepositoryProvider).myEntitlements();
  return list.map((e) => e['feature'] as String).toSet();
});

/// Catalog san pham cua store (gia + id) theo platform hien tai.
final storeProductsProvider = FutureProvider<List<StoreProduct>>((ref) async {
  final platform = defaultTargetPlatform == TargetPlatform.iOS
      ? 'ios'
      : 'android';
  return ref.watch(billingRepositoryProvider).storeProducts(platform);
});

/// True when the user holds the Pro membership (a superset of all paid features).
final isProProvider = Provider<bool>(
  (ref) => ref
      .watch(entitlementsProvider)
      .maybeWhen(data: (s) => s.contains('pro'), orElse: () => false),
);

/// Feature gate. Pro is a superset, so any Pro user passes every check.
final hasEntitlementProvider = Provider.family<bool, String>(
  (ref, feature) => ref
      .watch(entitlementsProvider)
      .maybeWhen(
        data: (s) => s.contains('pro') || s.contains(feature),
        orElse: () => false,
      ),
);
