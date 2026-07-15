import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'billing_providers.dart';

/// Features sold as consumables (re-buyable); everything else is non-consumable.
const _consumables = <String>{'boost'};

class IapController {
  IapController(this.ref, {InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  final Ref ref;
  final InAppPurchase _iap;
  Map<String, String>? _catalog;
  bool _initialized = false;

  /// Call from app startup (NOT from the constructor) — touches platform
  /// channels. [AUDIT C1] Không gọi init thì purchaseStream không có listener:
  /// user trả tiền nhưng validate-iap không bao giờ chạy, entitlement không
  /// được cấp. Idempotent: purchaseStream là single-subscription, listen 2
  /// lần sẽ throw. Nuốt lỗi platform channel để dev/test không crash.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      if (!await _iap.isAvailable()) return;
      _iap.purchaseStream.listen(_onPurchases);
    } catch (e) {
      debugPrint('IAP init skipped: $e');
    }
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

  /// Kick-off mua hàng. Trả false khi không mở được flow store (catalog lỗi,
  /// product không tồn tại, store throw) để UI báo user thay vì im lặng.
  Future<bool> buy(String feature) async {
    final productId = await _productIdFor(feature);
    if (productId == null) return false;
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return false;
      final product = response.productDetails.first;
      final param = PurchaseParam(productDetails: product);
      if (_consumables.contains(feature)) {
        await _iap.buyConsumable(purchaseParam: param);
      } else {
        await _iap.buyNonConsumable(purchaseParam: param);
      }
      return true;
    } catch (e) {
      debugPrint('IAP buy failed for $feature: $e');
      return false;
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
