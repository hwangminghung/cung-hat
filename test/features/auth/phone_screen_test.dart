import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthApiException;
import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';
import 'package:cung_hat/features/auth/presentation/phone_screen.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  testWidgets('renders the approved retro music-box login hierarchy', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: PhoneScreen()),
      ),
    );

    expect(find.text('Cùng Hát'), findsOneWidget);
    expect(find.text('Kết bạn qua những bài hát'), findsOneWidget);
    expect(find.byKey(const Key('login_music_box_hero')), findsOneWidget);
    expect(find.byIcon(Icons.music_note_rounded), findsWidgets);

    final inputFrame = tester.widget<Container>(
      find.byKey(const Key('phone_input_frame')),
    );
    final decoration = inputFrame.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.color, AppColors.ink);
    expect(border.top.width, 2);
    expect(decoration.boxShadow?.single.offset, const Offset(3, 3));
  });

  testWidgets('entering a number and tapping send calls sendOtp', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const PhoneScreen()),
        GoRoute(
          path: '/otp',
          builder: (context, state) => const Scaffold(body: Text('otp stub')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    expect(find.text('Kết bạn qua những bài hát'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '900000001');
    await tester.ensureVisible(find.byKey(const Key('send_otp_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send_otp_btn')));
    await tester.pump();
    verify(() => repo.sendOtp('+84900000001')).called(1);
  });

  testWidgets('gửi OTP lỗi → KHÔNG lộ raw exception, chỉ message VI (vòng cuối)', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenThrow(
      AuthApiException(
        'Error sending confirmation OTP to provider: see '
        'https://www.twilio.com/docs/errors/60203',
        statusCode: '422',
        code: 'sms_send_failed',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: PhoneScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField), '900000001');
    // Nút có thể bị đẩy dưới viewport khi bàn phím test mở — cuộn vào tầm.
    await tester.ensureVisible(find.byKey(const Key('send_otp_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send_otp_btn')));
    await tester.pumpAndSettle();

    // Không một mảnh kỹ thuật nào được render.
    expect(find.textContaining('AuthApiException'), findsNothing);
    expect(find.textContaining('twilio.com'), findsNothing);
    expect(find.textContaining('statusCode'), findsNothing);
    expect(find.textContaining('sms_send_failed'), findsNothing);
    expect(find.textContaining('422'), findsNothing);
    // Message thân thiện đã localization.
    expect(
      find.text('Không thể gửi mã OTP. Vui lòng kiểm tra số điện thoại và thử lại.'),
      findsOneWidget,
    );
  });
}
