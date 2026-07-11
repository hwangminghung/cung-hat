import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:cung_hat/features/onboarding/presentation/onboarding_flow.dart';
import 'package:cung_hat/features/onboarding/application/reference_providers.dart';
import 'package:cung_hat/shared/widgets/wave_divider.dart';

Future<void> pumpFlow(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        genresProvider.overrideWith((ref) async => []),
        artistsProvider.overrideWith((ref) async => []),
        songsProvider.overrideWith((ref) async => []),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OnboardingFlow(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders one custom DOB step with waveform progress', (
    tester,
  ) async {
    await pumpFlow(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(Stepper), findsNothing);
    expect(find.byType(WaveDivider), findsNWidgets(4));
    expect(find.text('Bước 1/4'), findsOneWidget);
    expect(find.text('Ngày sinh'), findsOneWidget);
    expect(find.text('Bạn sinh ngày nào?'), findsOneWidget);
    expect(find.text('Chọn ngày sinh'), findsNothing);
    expect(find.byKey(const Key('pick_dob_btn')), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('continue control remains reachable on a compact screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpFlow(tester);

    expect(find.byKey(const Key('onb_continue')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
