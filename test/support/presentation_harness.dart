import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const presentationWidths = <double>[360, 393, 430];
const presentationTextScales = <double>[1, 1.2, 1.4];
const presentationPlatforms = <TargetPlatform>[
  TargetPlatform.android,
  TargetPlatform.iOS,
];

Future<void> pumpPresentation(
  WidgetTester tester, {
  required Widget child,
  Size size = const Size(393, 852),
  double textScale = 1,
  TargetPlatform platform = TargetPlatform.android,
  bool disableAnimations = false,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light().copyWith(platform: platform),
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          viewInsets: viewInsets,
        ),
        child: appChild!,
      ),
      home: child,
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}
