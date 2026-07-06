import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:cung_hat/features/onboarding/presentation/onboarding_flow.dart';
import 'package:cung_hat/features/onboarding/application/reference_providers.dart';

Widget _app() => ProviderScope(
  overrides: [
    genresProvider.overrideWith((ref) async => []),
    artistsProvider.overrideWith((ref) async => []),
    songsProvider.overrideWith((ref) async => []),
  ],
  child: MaterialApp(
    restorationScopeId: 'app',
    theme: AppTheme.light(),
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const OnboardingFlow(),
  ),
);

void main() {
  testWidgets('OnboardingFlow renders step 1 content under AppTheme.light', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('pick_dob_btn')), findsOneWidget);
  });

  testWidgets('OnboardingFlow restores draft after activity recreation', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    tester
        .widget<FilledButton>(find.byKey(const Key('onb_continue_btn')).first)
        .onPressed
        ?.call();
    await tester.pump();
    tester
        .widget<FilledButton>(find.byKey(const Key('onb_continue_btn')).first)
        .onPressed
        ?.call();
    await tester.pump();
    await tester.enterText(find.byKey(const Key('onb_name')), 'TestPro');
    await tester.enterText(find.byKey(const Key('onb_bio')), 'QA draft');
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('onb_name')))
          .controller
          ?.text,
      'TestPro',
    );

    await tester.restartAndRestore();
    await tester.pump();

    expect(find.byKey(const Key('onb_name')), findsOneWidget);
    final nameField = tester.widget<TextField>(
      find.byKey(const Key('onb_name')),
    );
    final bioField = tester.widget<TextField>(find.byKey(const Key('onb_bio')));
    expect(nameField.controller?.text, 'TestPro');
    expect(bioField.controller?.text, 'QA draft');
  });
}
