import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import '../../support/supabase_mocks.dart';

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class _MockFilterBuilder extends Mock
    implements PostgrestFilterBuilder<dynamic> {}

void main() {
  test('isAdmin true khi RPC is_admin_self tra true', () async {
    final client = MockSupabaseClient();
    // rpcOk dung TRUOC when: goi rpcOk ben trong thenAnswer la goi when()
    // trong stub response — mocktail cam va con lam hong cac test sau.
    final ok = rpcOk(true);
    when(() => client.rpc('is_admin_self')).thenAnswer((_) => ok);
    expect(await SettingsRepository(client).isAdmin(), isTrue);
  });

  test(
    'isAdmin false khi RPC loi (mang/khong ton tai) — khong throw',
    () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('is_admin_self')).thenThrow(Exception('offline'));
      expect(await SettingsRepository(client).isAdmin(), isFalse);
    },
  );

  test('myBlocks map rows tu get_my_blocks', () async {
    final client = MockSupabaseClient();
    final ok = rpcOk([
      {
        'blocked_id': 'u9',
        'display_name': 'Người Bị Chặn',
        'created_at': '2026-07-26T00:00:00Z',
      },
      {
        'blocked_id': 'u8',
        'display_name': null,
        'created_at': '2026-07-25T00:00:00Z',
      },
    ]);
    when(() => client.rpc('get_my_blocks')).thenAnswer((_) => ok);
    final blocks = await SettingsRepository(client).myBlocks();
    expect(blocks, hasLength(2));
    expect(blocks.first.userId, 'u9');
    expect(blocks.first.displayName, 'Người Bị Chặn');
    // Profile xoa mem -> ten null, UI se rot ve 'Ẩn danh'.
    expect(blocks.last.displayName, isNull);
  });

  test('unblock xoa dung row blocks cua minh', () async {
    final client = MockSupabaseClient();
    final qb = _MockQueryBuilder();
    final del = _MockFilterBuilder();
    final ok = rpcOk(null);
    // Moi builder cua supabase deu implements Future -> mocktail cam
    // thenReturn, phai thenAnswer het.
    when(() => client.from('blocks')).thenAnswer((_) => qb);
    when(() => qb.delete()).thenAnswer((_) => del);
    when(() => del.eq('blocked_id', 'u9')).thenAnswer((_) => ok);

    await SettingsRepository(client).unblock('u9');

    verify(() => del.eq('blocked_id', 'u9')).called(1);
  });

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
