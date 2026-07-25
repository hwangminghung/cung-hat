import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('exportMyData calls export_my_data', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('export_my_data'),
    ).thenAnswer((_) => rpcOk({'profile': <String, dynamic>{}}));
    final data = await SettingsRepository(client).exportMyData();
    expect(data.containsKey('profile'), isTrue);
  });

  test('withdrawConsent calls record_consent with granted=false', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('record_consent', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk(null));
    await SettingsRepository(client).withdrawConsent('marketing');
    verify(
      () => client.rpc(
        'record_consent',
        params: {
          'p_purpose': 'marketing',
          'p_granted': false,
          'p_policy_version': 'v1',
        },
      ),
    ).called(1);
  });

  test('deleteAccount calls request_account_deletion', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('request_account_deletion'),
    ).thenAnswer((_) => rpcOk(null));
    await SettingsRepository(client).deleteAccount();
    verify(() => client.rpc('request_account_deletion')).called(1);
  });
}
