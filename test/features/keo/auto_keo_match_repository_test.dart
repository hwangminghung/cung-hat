import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/features/keo/data/keo_errors.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';

import '../../support/supabase_mocks.dart';

void main() {
  test('suggestMatch maps sanitized suggestion rows', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('suggest_keo_match', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk([
              {
                'suggestion_type': 'existing_keo',
                'keo_id': '00000000-0000-0000-0000-000000000001',
                'title': 'V-Pop toi nay',
                'area_label': 'Q1',
                'distance_band': '1-3',
                'time_window_start': '2026-06-30T12:00:00Z',
                'time_window_end': '2026-06-30T15:00:00Z',
                'size_target': 4,
                'slots_filled': 2,
                'genres': ['vpop'],
                'host_name': 'Mai',
                'join_mode': 'open',
                'reason_labels': ['shared_genres', 'near_you'],
                'proposed_start': null,
                'proposed_end': null,
              },
            ]));

    final suggestions = await KeoRepository(client).suggestMatch(limit: 2);

    expect(suggestions.single.suggestionType, 'existing_keo');
    expect(suggestions.single.keoId, '00000000-0000-0000-0000-000000000001');
    expect(suggestions.single.reasonLabels, ['shared_genres', 'near_you']);
    verify(() => client.rpc('suggest_keo_match', params: {'p_limit': 2}))
        .called(1);
  });

  test('createAutoMatchedKeo sends proposal fields to RPC', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('create_auto_matched_keo',
        params: any(named: 'params'))).thenAnswer((_) => rpcOk('k-new'));

    final id = await KeoRepository(client).createAutoMatchedKeo(
      title: 'Keo goi y toi nay',
      start: DateTime.utc(2026, 6, 30, 12),
      end: DateTime.utc(2026, 6, 30, 15),
      size: 4,
      genres: const ['vpop'],
      joinMode: 'open',
    );

    expect(id, 'k-new');
    verify(
      () => client.rpc(
        'create_auto_matched_keo',
        params: {
          'p_title': 'Keo goi y toi nay',
          'p_start': '2026-06-30T12:00:00.000Z',
          'p_end': '2026-06-30T15:00:00.000Z',
          'p_size': 4,
          'p_genres': ['vpop'],
          'p_join_mode': 'open',
        },
      ),
    ).called(1);
  });

  test('keoErrorMessage maps auto-match errors', () {
    expect(
      keoErrorMessage('PostgrestException(message: location_required)'),
      'Can bat vi tri de ghep keo. Hay bat Location roi thu lai.',
    );
    expect(
      keoErrorMessage('PostgrestException(message: age_not_verified)'),
      'Can xac minh tuoi truoc khi ghep keo.',
    );
  });
}
