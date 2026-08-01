import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cung_hat/core/push/push_primer.dart';
import 'package:cung_hat/core/push/push_registrar.dart';

class _MockRegistrar extends Mock implements PushRegistrar {}

/// [PRIMER — đợt 4] Sheet giải thích trước khi xin quyền: "Bật thông báo" là
/// thứ DUY NHẤT kích hoạt hộp thoại quyền OS; "Để sau" chỉ ghi pref.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_MockRegistrar> pumpSheet(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final registrar = _MockRegistrar();
    when(() => registrar.registerForSignedInUser()).thenAnswer((_) async {});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pushRegistrarProvider.overrideWithValue(registrar)],
        child: const MaterialApp(home: Scaffold(body: PushPrimerSheet())),
      ),
    );
    await tester.pump();
    return registrar;
  }

  testWidgets('"Bật thông báo" → pref on + gọi registerForSignedInUser', (
    tester,
  ) async {
    final registrar = await pumpSheet(tester);

    await tester.tap(find.byKey(const Key('push_primer_accept')));
    await tester.pumpAndSettle();

    verify(() => registrar.registerForSignedInUser()).called(1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kPushPrimerPrefKey), 'on');
  });

  testWidgets('"Để sau" → pref later, KHÔNG xin quyền', (tester) async {
    final registrar = await pumpSheet(tester);

    await tester.tap(find.byKey(const Key('push_primer_later')));
    await tester.pumpAndSettle();

    verifyNever(() => registrar.registerForSignedInUser());
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kPushPrimerPrefKey), 'later');
  });
}
