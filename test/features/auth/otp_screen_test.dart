import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/auth/application/auth_controller.dart';
import 'package:cung_hat/features/auth/application/auth_providers.dart';
import 'package:cung_hat/features/auth/data/auth_repository.dart';
import 'package:cung_hat/features/auth/presentation/otp_screen.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:cung_hat/shared/widgets/gradient_button.dart';

class _MockRepo extends Mock implements AuthRepository {}

Widget _localizedOtp(ProviderContainer container, {double textScale = 1}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const OtpScreen(),
      ),
    ),
  );
}

Future<ProviderContainer> _pumpOtpScreen(
  WidgetTester tester,
  _MockRepo repo, {
  String phone = '+84900000001',
}) async {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.notifier).sendOtp(phone);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: OtpScreen()),
    ),
  );
  return container;
}

void main() {
  testWidgets('renders the approved outlined OTP ticket hierarchy', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OtpScreen()),
      ),
    );

    expect(find.byKey(const Key('otp_brand_header')), findsOneWidget);
    expect(find.text('Cùng Hát'), findsOneWidget);
    expect(find.text('Nhập mã OTP'), findsOneWidget);

    final ticket = tester.widget<Container>(
      find.byKey(const Key('otp_ticket_hero')),
    );
    final decoration = ticket.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.color, AppColors.ink);
    expect(border.top.width, 2);
    expect(decoration.boxShadow?.single.offset, const Offset(3, 3));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resend countdown starts at 60 and ticks once per second', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OtpScreen()),
      ),
    );

    expect(find.text('Gửi lại mã sau 60s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Gửi lại mã sau 59s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Gửi lại mã sau 58s'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resend action reuses the phone and resets the countdown', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');
    clearInteractions(repo);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OtpScreen()),
      ),
    );

    await tester.pump(const Duration(seconds: 60));
    expect(find.text('Gửi lại mã'), findsOneWidget);

    await tester.tap(find.byKey(const Key('resend_otp_btn')));
    await tester.pump();

    verify(() => repo.sendOtp('+84900000001')).called(1);
    expect(find.text('Gửi lại mã sau 60s'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('OTP layout handles 320px width at 200 percent text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');

    await tester.pumpWidget(_localizedOtp(container, textScale: 2));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('+84 900 000 001', findRichText: true),
      findsOneWidget,
    );
    expect(tester.getSize(find.byKey(const Key('resend_slot'))).height, 52);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('formatted phone uses accessible ink on a teal accent', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    await _pumpOtpScreen(tester, repo);

    final phoneText = tester.widget<Text>(
      find.byKey(const Key('otp_phone_text')),
    );
    final rootSpan = phoneText.textSpan! as TextSpan;
    final phoneSpan = rootSpan.children!.last as TextSpan;

    expect(phoneSpan.style?.color, AppColors.ink);
    expect(phoneSpan.style?.backgroundColor, AppColors.teal);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rapid resend taps start only one repository request', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    await _pumpOtpScreen(tester, repo);
    clearInteractions(repo);

    final resendCompleter = Completer<void>();
    var resendCalls = 0;
    when(() => repo.sendOtp(any())).thenAnswer((_) {
      resendCalls += 1;
      return resendCompleter.future;
    });

    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.byKey(const Key('resend_otp_btn')));
    await tester.tap(find.byKey(const Key('resend_otp_btn')));
    resendCompleter.complete();
    await tester.pump();

    expect(resendCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resend in flight disables and blocks OTP verification', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    await _pumpOtpScreen(tester, repo);

    final resendCompleter = Completer<void>();
    when(() => repo.sendOtp(any())).thenAnswer((_) => resendCompleter.future);
    var verifyCalls = 0;
    when(() => repo.verifyOtp(any(), any())).thenAnswer((_) async {
      verifyCalls += 1;
      return AuthResponse(session: null, user: null);
    });

    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.byKey(const Key('resend_otp_btn')));
    await tester.pump();
    final verifyWasDisabled =
        tester
            .widget<GradientButton>(find.byKey(const Key('verify_otp_btn')))
            .onPressed ==
        null;

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.byKey(const Key('verify_otp_btn')));
    resendCompleter.complete();
    await tester.pump();

    expect(verifyCalls, 0);
    expect(verifyWasDisabled, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('verification in flight blocks resend and rapid verify taps', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    await _pumpOtpScreen(tester, repo);
    clearInteractions(repo);

    var resendCalls = 0;
    when(() => repo.sendOtp(any())).thenAnswer((_) async {
      resendCalls += 1;
    });
    final verifyCompleter = Completer<AuthResponse>();
    var verifyCalls = 0;
    when(() => repo.verifyOtp(any(), any())).thenAnswer((_) {
      verifyCalls += 1;
      return verifyCompleter.future;
    });

    await tester.pump(const Duration(seconds: 60));
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    final resendWasDisabled =
        tester
            .widget<TextButton>(find.byKey(const Key('resend_otp_btn')))
            .onPressed ==
        null;

    await tester.tap(find.byKey(const Key('resend_otp_btn')));
    await tester.tap(find.byKey(const Key('verify_otp_btn')));
    await tester.tap(find.byKey(const Key('verify_otp_btn')));
    verifyCompleter.complete(AuthResponse(session: null, user: null));
    await tester.pump();

    expect(verifyCalls, 1);
    expect(resendCalls, 0);
    expect(resendWasDisabled, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('throwing resend keeps phone, error, and full cooldown', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final container = await _pumpOtpScreen(tester, repo);

    final resendCompleter = Completer<void>();
    when(() => repo.sendOtp(any())).thenAnswer((_) => resendCompleter.future);
    var verifyCalls = 0;
    when(() => repo.verifyOtp(any(), any())).thenAnswer((_) async {
      verifyCalls += 1;
      return AuthResponse(session: null, user: null);
    });

    await tester.pump(const Duration(seconds: 60));
    await tester.tap(find.byKey(const Key('resend_otp_btn')));
    await tester.pump();
    final verifyWasDisabled =
        tester
            .widget<GradientButton>(find.byKey(const Key('verify_otp_btn')))
            .onPressed ==
        null;

    resendCompleter.completeError(Exception('resend failed'));
    await tester.pump();

    final state = container.read(authControllerProvider);
    expect(state.phone, '+84900000001');
    expect(state.phase, AuthPhase.error);
    // Vòng cuối UI review: raw exception KHÔNG được render — banner chỉ hiện
    // message thân thiện đã map từ AuthErrorKind (Exception lạ → generic).
    expect(find.textContaining('resend failed'), findsNothing);
    expect(find.text('Đã có lỗi xảy ra. Vui lòng thử lại.'), findsOneWidget);
    expect(find.text('Gửi lại mã sau 60s'), findsOneWidget);
    expect(find.byKey(const Key('resend_otp_btn')), findsNothing);
    expect(verifyCalls, 0);
    expect(verifyWasDisabled, isTrue);

    await tester.pump(const Duration(seconds: 60));
    expect(find.byKey(const Key('resend_otp_btn')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resend countdown timer is cancelled when screen is disposed', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OtpScreen()),
      ),
    );

    expect(find.text('Gửi lại mã sau 60s'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 61));

    expect(tester.takeException(), isNull);
  });

  testWidgets('entering code and tapping verify calls verifyOtp', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    when(
      () => repo.verifyOtp(any(), any()),
    ).thenAnswer((_) async => AuthResponse(session: null, user: null));
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OtpScreen()),
      ),
    );
    // The 6-box OtpInput auto-submits on completion; tapping the verify button
    // afterwards must NOT fire a second verify for the same code (guarded by
    // _submitted) — verifyOtp runs exactly once with the entered code.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.byKey(const Key('verify_otp_btn')));
    await tester.pump();
    verify(() => repo.verifyOtp('+84900000001', '123456')).called(1);
  });

  testWidgets('verify button retries after auto-submit fails', (tester) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    var attempts = 0;
    when(() => repo.verifyOtp(any(), any())).thenAnswer((_) async {
      attempts += 1;
      if (attempts == 1) throw Exception('bad otp');
      return AuthResponse(session: null, user: null);
    });
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+84900000001');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OtpScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(container.read(authControllerProvider).phase, AuthPhase.error);

    await tester.tap(find.byKey(const Key('verify_otp_btn')));
    await tester.pump();

    expect(attempts, 2);
  });

  testWidgets('OTP sai → message VI thân thiện, không lộ raw (vòng cuối)', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.sendOtp(any())).thenAnswer((_) async {});
    when(() => repo.verifyOtp(any(), any())).thenThrow(
      AuthApiException(
        'Token has expired or is invalid',
        statusCode: '403',
        code: 'otp_expired',
      ),
    );

    await _pumpOtpScreen(tester, repo);
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();

    expect(find.textContaining('AuthApiException'), findsNothing);
    expect(find.textContaining('otp_expired'), findsNothing);
    expect(find.textContaining('403'), findsNothing);
    expect(
      find.text('Mã OTP không đúng hoặc đã hết hạn. Vui lòng thử lại.'),
      findsOneWidget,
    );
  });
}
