import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  group('createKeoShareLink', () {
    test('calls create_keo_share_link with p_keo and returns the token', () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('create_keo_share_link', params: any(named: 'params')))
          .thenAnswer((_) => rpcOk('abc123'));
      final token = await KeoRepository(client).createKeoShareLink('k1');
      expect(token, 'abc123');
      verify(() => client.rpc('create_keo_share_link', params: {'p_keo': 'k1'}))
          .called(1);
    });
  });

  group('resolveSharedKeo', () {
    test('maps a valid composite row into a SharedKeo', () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('resolve_share_keo', params: any(named: 'params')))
          .thenAnswer((_) => rpcOk({
                'keo_id': 'k1',
                'title': 'Hát tối T7',
                'area_label': 'Q1',
                'time_window_start': '2026-07-10T19:00:00Z',
                'size_target': 4,
                'slots_filled': 2,
                'genres': ['vpop'],
                'host_name': 'Mai',
                'join_mode': 'open',
                'status': 'open',
                'expired': false,
              }));
      final result = await KeoRepository(client).resolveSharedKeo('tok');
      expect(result, isNotNull);
      expect(result!.keoId, 'k1');
      expect(result.title, 'Hát tối T7');
      expect(result.areaLabel, 'Q1');
      expect(result.sizeTarget, 4);
      expect(result.slotsFilled, 2);
      expect(result.genres, ['vpop']);
      expect(result.hostName, 'Mai');
      expect(result.joinMode, 'open');
      expect(result.status, 'open');
      expect(result.expired, false);
      verify(() => client.rpc('resolve_share_keo', params: {'p_token': 'tok'}))
          .called(1);
    });

    test('returns null when the RPC result is null (defensive)', () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('resolve_share_keo', params: any(named: 'params')))
          .thenAnswer((_) => rpcOk(null));
      final result = await KeoRepository(client).resolveSharedKeo('tok');
      expect(result, isNull);
    });

    test('returns null when the composite row is empty (bogus token)', () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('resolve_share_keo', params: any(named: 'params')))
          .thenAnswer((_) => rpcOk({
                'keo_id': null,
                'title': null,
                'area_label': null,
                'time_window_start': null,
                'size_target': null,
                'slots_filled': null,
                'genres': null,
                'host_name': null,
                'join_mode': null,
                'status': null,
                'expired': null,
              }));
      final result = await KeoRepository(client).resolveSharedKeo('tok');
      expect(result, isNull);
    });

    test('unwraps a List-shaped result (defensive against setof-style response)',
        () async {
      final client = MockSupabaseClient();
      when(() => client.rpc('resolve_share_keo', params: any(named: 'params')))
          .thenAnswer((_) => rpcOk([
                {
                  'keo_id': 'k1',
                  'title': 'Hát tối T7',
                  'area_label': 'Q1',
                  'time_window_start': '2026-07-10T19:00:00Z',
                  'size_target': 4,
                  'slots_filled': 2,
                  'genres': ['vpop'],
                  'host_name': 'Mai',
                  'join_mode': 'open',
                  'status': 'open',
                  'expired': false,
                },
              ]));
      final result = await KeoRepository(client).resolveSharedKeo('tok');
      expect(result, isNotNull);
      expect(result!.keoId, 'k1');
    });
  });
}
