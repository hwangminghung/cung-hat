import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('nearestVenues maps suggestions', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('nearest_venues_for_keo', params: any(named: 'params')),
    ).thenAnswer(
      (_) => rpcOk([
        {
          'id': 'v1',
          'name': 'Kingdom',
          'address': 'Q1',
          'style_tag': 'k_style',
          'photos': <String>[],
          'distance_band': '1-3',
          'lat': 10.776,
          'lng': 106.7,
        },
      ]),
    );
    final list = await PlanRepository(client).nearestVenues('k1');
    expect(list.single.name, 'Kingdom');
    expect(list.single.distanceBand, '1-3');
    expect(list.single.lat, 10.776);
    expect(list.single.lng, 106.7);
  });

  test('proposePlan calls propose_keo_plan', () async {
    final client = MockSupabaseClient();
    when(
      () => client.rpc('propose_keo_plan', params: any(named: 'params')),
    ).thenAnswer((_) => rpcOk('p1'));
    final id = await PlanRepository(
      client,
    ).proposePlan('k1', 'v1', DateTime.utc(2026, 6, 21, 19));
    expect(id, 'p1');
  });

  group('getKeoMidpoint', () {
    test('tra MapPoint khi RPC co dong', () async {
      final client = MockSupabaseClient();
      when(
        () => client.rpc('get_keo_midpoint', params: any(named: 'params')),
      ).thenAnswer(
        (_) => rpcOk([
          {'lat': 21.028, 'lng': 105.854},
        ]),
      );
      final mid = await PlanRepository(client).getKeoMidpoint('k1');
      expect(mid, isNotNull);
      expect(mid!.lat, 21.028);
      expect(mid.lng, 105.854);
    });

    test('tra null khi RPC rong (chua ai co vi tri)', () async {
      final client = MockSupabaseClient();
      when(
        () => client.rpc('get_keo_midpoint', params: any(named: 'params')),
      ).thenAnswer((_) => rpcOk(<dynamic>[]));
      expect(await PlanRepository(client).getKeoMidpoint('k1'), isNull);
    });
  });
}
