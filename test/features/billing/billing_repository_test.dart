import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/billing/data/billing_repository.dart';
import '../../support/supabase_mocks.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

void main() {
  test('deliverPurchase invokes validate-iap with the receipt fields', () async {
    final client = MockSupabaseClient();
    final fns = _MockFunctions();
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('validate-iap', body: any(named: 'body')))
        .thenAnswer((_) async => FunctionResponse(data: {'ok': true}, status: 200));
    await BillingRepository(client).deliverPurchase(
      platform: 'ios', storeProductId: 'com.cunghat.boost', storeTxnId: 't1', receipt: 'r');
    verify(() => fns.invoke('validate-iap', body: {
      'platform': 'ios', 'store_product_id': 'com.cunghat.boost',
      'store_txn_id': 't1', 'receipt': 'r',
    })).called(1);
  });

  test('deliverPurchase throws when validate-iap returns >=400', () async {
    final client = MockSupabaseClient();
    final fns = _MockFunctions();
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('validate-iap', body: any(named: 'body')))
        .thenAnswer((_) async => FunctionResponse(data: {'error': 'invalid_receipt'}, status: 400));
    expect(
      () => BillingRepository(client).deliverPurchase(
          platform: 'ios', storeProductId: 'x', storeTxnId: 't2', receipt: 'bad'),
      throwsA(isA<Exception>()),
    );
  });

  test('myEntitlements calls get_my_entitlements', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_my_entitlements')).thenAnswer((_) => rpcOk([
      {'user_id': 'u1', 'feature': 'see_likes', 'source': 'ios_iap', 'active_until': null},
    ]));
    final e = await BillingRepository(client).myEntitlements();
    expect(e.single['feature'], 'see_likes');
  });

  test('storeProducts calls get_store_products and maps rows', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_store_products', params: {'p_platform': 'ios'}))
        .thenAnswer((_) => rpcOk([
              {
                'sku': 'pro_monthly_ios',
                'type': 'pro',
                'platform': 'ios',
                'store_product_id': 'com.cunghat.pro.monthly',
                'price_minor': 79000,
                'billing_period': 'monthly',
                'entitlement_days': 31,
                'boost_credits': 0,
                'badge': null,
                'sort_order': 10,
              },
            ]));

    final products = await BillingRepository(client).storeProducts('ios');

    expect(products.single.sku, 'pro_monthly_ios');
    expect(products.single.priceMinor, 79000);
  });

  test('boostCreditSummary calls get_my_boost_credits', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_my_boost_credits')).thenAnswer(
      (_) => rpcOk({'available_count': 2, 'next_expiring_at': null}),
    );

    final summary = await BillingRepository(client).boostCreditSummary();

    expect(summary.availableCount, 2);
  });
}
