import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:cung_hat/features/onboarding/presentation/onboarding_flow.dart';
import 'package:cung_hat/features/onboarding/application/reference_providers.dart';

/// Regression: the redesigned theme set FilledButton minimumSize to
/// Size.fromHeight (infinite width), which crashed the Stepper's controlsBuilder
/// Row (unbounded width) and rendered the whole onboarding body blank. This
/// pumps the real OnboardingFlow under AppTheme.light and asserts step 1 content
/// renders — it must not throw an "infinite width" layout assertion.
void main() {
  testWidgets('OnboardingFlow renders step 1 content under AppTheme.light',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
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
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Chọn ngày sinh'), findsOneWidget);
    // The vertical Stepper builds controlsBuilder for every step, so several
    // "Tiếp tục" buttons exist; the point is the body rendered (≥1), not blank.
    expect(find.text('Tiếp tục'), findsWidgets);
  });
}
