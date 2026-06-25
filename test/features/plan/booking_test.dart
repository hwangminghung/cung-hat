import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import '../../support/supabase_mocks.dart';

class _MockFunctions extends Mock implements FunctionsClient {}

void main() {
  test('startVenuePayment invokes create-venue-payment and returns pay url', () async {
    final client = MockSupabaseClient();
    final fns = _MockFunctions();
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('create-venue-payment', body: any(named: 'body')))
        .thenAnswer((_) async => FunctionResponse(data: {'pay_url': 'https://pay/x'}, status: 200));
    final url = await PlanRepository(client).startVenuePayment(
      planId: 'p1', venueId: 'v1', amountMinor: 200000, gateway: 'momo');
    expect(url, 'https://pay/x');
  });
}
