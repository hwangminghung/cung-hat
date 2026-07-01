import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/boost_credit_summary.dart';
import '../domain/store_product.dart';

class BillingRepository {
  BillingRepository(this._client);
  final SupabaseClient _client;

  Future<void> deliverPurchase({
    required String platform,
    required String storeProductId,
    required String storeTxnId,
    required String receipt,
  }) async {
    final res = await _client.functions.invoke('validate-iap', body: {
      'platform': platform,
      'store_product_id': storeProductId,
      'store_txn_id': storeTxnId,
      'receipt': receipt,
    });
    if (res.status >= 400) {
      throw Exception('validate-iap failed (${res.status}): ${res.data}');
    }
  }

  Future<List<Map<String, dynamic>>> myEntitlements() async {
    final rows = await _client.rpc('get_my_entitlements');
    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<StoreProduct>> storeProducts(String platform) async {
    final rows = await _client.rpc(
      'get_store_products',
      params: {'p_platform': platform},
    );
    return (rows as List)
        .map((e) => StoreProduct.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<BoostCreditSummary> boostCreditSummary() async {
    final row = await _client.rpc('get_my_boost_credits');
    if (row is List && row.isNotEmpty) {
      return BoostCreditSummary.fromJson(
        Map<String, dynamic>.from(row.first as Map),
      );
    }
    return BoostCreditSummary.fromJson(Map<String, dynamic>.from(row as Map));
  }
}
