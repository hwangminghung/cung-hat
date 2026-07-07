import 'package:supabase_flutter/supabase_flutter.dart';

class BillingRepository {
  BillingRepository(this._client);
  final SupabaseClient _client;

  /// Called after the store confirms a purchase; server validates + grants the entitlement.
  Future<void> deliverPurchase({
    required String platform, required String storeProductId,
    required String storeTxnId, required String receipt,
  }) async {
    final res = await _client.functions.invoke('validate-iap', body: {
      'platform': platform, 'store_product_id': storeProductId,
      'store_txn_id': storeTxnId, 'receipt': receipt,
    });
    if (res.status >= 400) {
      throw Exception('validate-iap failed (${res.status}): ${res.data}');
    }
  }

  Future<List<Map<String, dynamic>>> myEntitlements() async {
    final rows = await _client.rpc('get_my_entitlements');
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Catalog product-id theo platform tu bang products (het hardcode client).
  Future<Map<String, String>> storeProductIds(String platform) async {
    final rows = await _client
        .rpc('get_store_products', params: {'p_platform': platform}) as List<dynamic>;
    return {
      for (final r in rows.cast<Map<String, dynamic>>())
        r['type'] as String: r['store_product_id'] as String,
    };
  }
}
