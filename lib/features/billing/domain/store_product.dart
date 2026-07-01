class StoreProduct {
  const StoreProduct({
    required this.sku,
    required this.type,
    required this.platform,
    required this.storeProductId,
    required this.priceMinor,
    required this.billingPeriod,
    required this.boostCredits,
    required this.sortOrder,
    this.entitlementDays,
    this.badge,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) => StoreProduct(
        sku: json['sku'] as String,
        type: json['type'] as String,
        platform: json['platform'] as String,
        storeProductId: json['store_product_id'] as String,
        priceMinor: json['price_minor'] as int,
        billingPeriod: json['billing_period'] as String,
        entitlementDays: json['entitlement_days'] as int?,
        boostCredits: json['boost_credits'] as int? ?? 0,
        badge: json['badge'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  final String sku;
  final String type;
  final String platform;
  final String storeProductId;
  final int priceMinor;
  final String billingPeriod;
  final int? entitlementDays;
  final int boostCredits;
  final String? badge;
  final int sortOrder;

  bool get isPro => type == 'pro';
  bool get isBoost => type == 'boost';
  bool get isConsumable => billingPeriod == 'consumable' || boostCredits > 0;

  String get priceLabel {
    final raw = priceMinor.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer}d';
  }
}
