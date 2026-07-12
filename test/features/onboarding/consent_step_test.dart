import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/onboarding/presentation/consent_step.dart';
import 'package:cung_hat/l10n/app_localizations.dart';

const _allOff = {
  'location': false,
  'photos': false,
  'matching': false,
  'marketing': false,
  'cross_border': false,
};

Future<void> pumpConsentStep(
  WidgetTester tester, {
  required void Function(String, bool) onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ConsentStep(values: _allOff, onChanged: onChanged),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('marketing switch reports its new value', (tester) async {
    final changes = <String, bool>{};
    await pumpConsentStep(
      tester,
      onChanged: (key, value) => changes[key] = value,
    );

    await tester.tap(find.byKey(const Key('consent_marketing')));
    await tester.pump();

    expect(changes, equals(<String, bool>{'marketing': true}));
  });

  testWidgets('renders four required info rows and one optional switch', (
    tester,
  ) async {
    await pumpConsentStep(tester, onChanged: (_, _) {});

    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('consent_marketing')))
          .value,
      isFalse,
    );
    expect(find.text('Bắt buộc'), findsNWidgets(4));

    const requiredKeys = [
      Key('consent_location'),
      Key('consent_photos'),
      Key('consent_matching'),
      Key('consent_cross_border'),
    ];
    for (final key in requiredKeys) {
      expect(find.byKey(key), findsOneWidget);
    }

    final rowTops = [
      for (final key in requiredKeys) tester.getTopLeft(find.byKey(key)).dy,
    ];
    expect(rowTops, orderedEquals([...rowTops]..sort()));

    for (final purpose in consentPurposes) {
      expect(find.byKey(Key('consent_$purpose')), findsOneWidget);
    }
  });
}
