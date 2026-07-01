import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../domain/store_product.dart';
import 'billing_providers.dart';

enum PurchaseMode { consumable, nonConsumable }

PurchaseMode purchaseModeFor(StoreProduct product) =>
    product.isConsumable ? PurchaseMode.consumable : PurchaseMode.nonConsumable;

class IapController {
  IapController(this.ref, {InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  final Ref ref;
  final InAppPurchase _iap;

  Future<void> init() async {
    if (!await _iap.isAvailable()) return;
    _iap.purchaseStream.listen(_onPurchases);
  }

  Future<void> buy(String feature) async {
    try {
      final products = await ref.read(storeProductsProvider.future);
      final product = products.firstWhere((p) => p.type == feature);
      await buyProduct(product);
    } catch (e) {
      debugPrint('IAP buy failed for $feature: $e');
    }
  }

  Future<void> buyProduct(StoreProduct product) async {
    try {
      final response = await _iap.queryProductDetails({product.storeProductId});
      if (response.productDetails.isEmpty) return;
      final details = response.productDetails.first;
      final param = PurchaseParam(productDetails: details);
      if (purchaseModeFor(product) == PurchaseMode.consumable) {
        await _iap.buyConsumable(purchaseParam: param);
      } else {
        await _iap.buyNonConsumable(purchaseParam: param);
      }
    } catch (e) {
      debugPrint('IAP buy failed for ${product.sku}: $e');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    for (final pd in purchases) {
      if (pd.status == PurchaseStatus.purchased ||
          pd.status == PurchaseStatus.restored) {
        try {
          await ref.read(billingRepositoryProvider).deliverPurchase(
                platform: platform,
                storeProductId: pd.productID,
                storeTxnId: pd.purchaseID ?? '',
                receipt: pd.verificationData.serverVerificationData,
              );
          if (pd.pendingCompletePurchase) await _iap.completePurchase(pd);
          ref.invalidate(entitlementsProvider);
          ref.invalidate(boostCreditSummaryProvider);
          ref.invalidate(storeProductsProvider);
        } catch (e) {
          debugPrint('deliverPurchase failed for ${pd.productID}: $e');
        }
      }
    }
  }
}

final iapControllerProvider = Provider((ref) => IapController(ref));
