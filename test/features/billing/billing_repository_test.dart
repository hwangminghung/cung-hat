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

  group('storeProductIds', () {
    test('map type -> store_product_id theo platform', () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('get_store_products', params: any(named: 'params')))
          .thenAnswer((_) => rpcOk([
                {'type': 'boost', 'store_product_id': 'com.cunghat.boost'},
                {'type': 'pro', 'store_product_id': 'com.cunghat.pro'},
              ]));
      final ids = await BillingRepository(client).storeProductIds('android');
      expect(ids, {'boost': 'com.cunghat.boost', 'pro': 'com.cunghat.pro'});
    });
  });
}
