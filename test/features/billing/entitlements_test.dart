import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';

void main() {
  test('pro is a superset: unlocks any feature, and isPro is true', () {
    final c = ProviderContainer(
      overrides: [
        entitlementsProvider.overrideWith((ref) async => {'pro'}),
      ],
    );
    addTearDown(c.dispose);
    // Resolve the async provider.
    return c.read(entitlementsProvider.future).then((_) {
      expect(c.read(isProProvider), isTrue);
      expect(c.read(hasEntitlementProvider('see_likes')), isTrue);
      expect(c.read(hasEntitlementProvider('boost')), isTrue);
    });
  });

  test('non-pro only unlocks owned features', () {
    final c = ProviderContainer(
      overrides: [
        entitlementsProvider.overrideWith((ref) async => {'see_likes'}),
      ],
    );
    addTearDown(c.dispose);
    return c.read(entitlementsProvider.future).then((_) {
      expect(c.read(isProProvider), isFalse);
      expect(c.read(hasEntitlementProvider('see_likes')), isTrue);
      expect(c.read(hasEntitlementProvider('boost')), isFalse);
    });
  });
}
