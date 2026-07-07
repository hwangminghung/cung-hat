import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'billing_providers.dart';

/// Features sold as consumables (re-buyable); everything else is non-consumable.
const _consumables = <String>{'boost'};

class IapController {
  IapController(this.ref);

  final Ref ref;
  final InAppPurchase _iap = InAppPurchase.instance;
  Map<String, String>? _catalog;

  /// Call from app startup (NOT from the constructor) — touches platform channels.
  Future<void> init() async {
    if (!await _iap.isAvailable()) return;
    _iap.purchaseStream.listen(_onPurchases);
  }

  Future<String?> _productIdFor(String feature) async {
    try {
      _catalog ??= await ref.read(billingRepositoryProvider).storeProductIds(
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    } catch (e) {
      debugPrint('IAP catalog load failed: $e');
      return null;
    }
    return _catalog![feature];
  }

  /// Best-effort purchase kick-off. Real product wiring is TODO(prod).
  Future<void> buy(String feature) async {
    final productId = await _productIdFor(feature);
    if (productId == null) return;
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return;
      final product = response.productDetails.first;
      final param = PurchaseParam(productDetails: product);
      if (_consumables.contains(feature)) {
        await _iap.buyConsumable(purchaseParam: param);
      } else {
        await _iap.buyNonConsumable(purchaseParam: param);
      }
    } catch (e) {
      // TODO(prod): surface store errors to the user.
      debugPrint('IAP buy failed for $feature: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    for (final pd in purchases) {
      if (pd.status == PurchaseStatus.purchased || pd.status == PurchaseStatus.restored) {
        try {
          await ref.read(billingRepositoryProvider).deliverPurchase(
                platform: platform,
                storeProductId: pd.productID,
                storeTxnId: pd.purchaseID ?? '',
                receipt: pd.verificationData.serverVerificationData,
              );
          if (pd.pendingCompletePurchase) await _iap.completePurchase(pd);
          ref.invalidate(entitlementsProvider);
        } catch (e) {
          // Do NOT complete the purchase — let the store retry on next launch.
          // TODO(prod): record/report this delivery failure.
          debugPrint('deliverPurchase failed for ${pd.productID}: $e');
        }
      }
    }
  }
}

final iapControllerProvider = Provider((ref) => IapController(ref));
