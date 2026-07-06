import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';
import 'package:cung_hat/features/auth/presentation/phone_screen.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  testWidgets('entering a number and tapping send calls sendOtp', (tester) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const PhoneScreen()),
        GoRoute(
            path: '/otp',
            builder: (context, state) =>
                const Scaffold(body: Text('otp stub'))),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: router),
    ));
    expect(find.text('Kết bạn qua những bài hát'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '900000001');
    await tester.tap(find.byKey(const Key('send_otp_btn')));
    await tester.pump();
    verify(() => repo.sendOtp('+84900000001')).called(1);
  });
}
