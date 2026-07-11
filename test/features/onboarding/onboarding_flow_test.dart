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

  testWidgets('consent CTA keeps marketing off and advances', (tester) async {
    await pumpFlow(tester);

    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();

    expect(find.text('Bước 2/4'), findsOneWidget);
    expect(find.text('Quyền riêng tư'), findsOneWidget);
    expect(find.text('Đồng ý & tiếp tục'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('consent_marketing')))
          .value,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();

    expect(find.text('Bước 3/4'), findsOneWidget);
    expect(find.text('Thiết lập hồ sơ'), findsNWidgets(2));
    expect(find.text('Quyền riêng tư'), findsNothing);
  });

  testWidgets('profile step shows branded preview and preserves field values', (
    tester,
  ) async {
    await pumpFlow(tester);

    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();

    expect(find.text('Bước 3/4'), findsOneWidget);
    expect(find.text('Thiết lập hồ sơ'), findsNWidgets(2));
    expect(find.text('Bạn muốn mọi người gọi mình là gì?'), findsOneWidget);
    expect(find.byKey(const Key('onb_profile_preview')), findsOneWidget);
    expect(find.text('Cùng Hát'), findsOneWidget);
    expect(find.text('Mixtape Sáng'), findsNothing);
    expect(find.byKey(const Key('onb_name')), findsOneWidget);
    expect(find.byKey(const Key('onb_bio')), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(const Key('onb_bio'))).maxLines,
      greaterThan(1),
    );

    await tester.enterText(find.byKey(const Key('onb_name')), 'Minh');
    await tester.enterText(find.byKey(const Key('onb_bio')), 'Mê V-Pop.');

    await tester.tap(find.byKey(const Key('onb_back')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('onb_name')))
          .controller
          ?.text,
      'Minh',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('onb_bio')))
          .controller
          ?.text,
      'Mê V-Pop.',
    );
  });

  testWidgets('taste step shows hierarchy and preserved finish control', (
    tester,
  ) async {
    await pumpFlow(tester);

    for (var step = 0; step < 3; step++) {
      await tester.tap(find.byKey(const Key('onb_continue')));
      await tester.pump();
    }

    expect(find.text('Bước 4/4'), findsOneWidget);
    expect(find.text('Gu nhạc'), findsOneWidget);
    expect(find.text('Chọn vài thứ bạn hay nghe'), findsOneWidget);
    expect(find.text('Thể loại'), findsOneWidget);
    expect(find.text('Nghệ sĩ'), findsOneWidget);
    expect(find.text('Bài tủ'), findsOneWidget);
    expect(find.byKey(const Key('onb_finish')), findsOneWidget);
    expect(find.text('Hoàn tất'), findsOneWidget);
  });
}
