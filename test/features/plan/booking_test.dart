import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import '../../support/supabase_mocks.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

void main() {
  test(
    'startVenuePayment goi create-venue-payment KHONG gui amount (server quyet)',
    () async {
      final client = MockSupabaseClient();
      final fns = _MockFunctions();
      when(() => client.functions).thenReturn(fns);
      Map<String, dynamic>? sentBody;
      when(
        () => fns.invoke('create-venue-payment', body: any(named: 'body')),
      ).thenAnswer((inv) async {
        sentBody = inv.namedArguments[#body] as Map<String, dynamic>;
        return FunctionResponse(
          data: {'pay_url': 'https://pay/x'},
          status: 200,
        );
      });
      final url = await PlanRepository(
        client,
      ).startVenuePayment(planId: 'p1', venueId: 'v1', gateway: 'zalopay');
      expect(url, 'https://pay/x');
      expect(sentBody, {
        'plan_id': 'p1',
        'venue_id': 'v1',
        'gateway': 'zalopay',
      });
      expect(sentBody!.containsKey('amount_minor'), isFalse);
    },
  );
}
