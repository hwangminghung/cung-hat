import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:cung_hat/features/onboarding/presentation/onboarding_flow.dart';
import 'package:cung_hat/core/analytics/analytics_service.dart';
import 'package:cung_hat/features/onboarding/application/reference_providers.dart';
import 'package:cung_hat/shared/widgets/wave_divider.dart';

import '../../support/analytics_fakes.dart';

Future<void> pumpFlow(
  WidgetTester tester, {
  TextScaler textScaler = TextScaler.noScaling,
  AnalyticsService? analytics,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        genresProvider.overrideWith((ref) async => []),
        artistsProvider.overrideWith((ref) async => []),
        songsProvider.overrideWith((ref) async => []),
        if (analytics != null) analyticsProvider.overrideWithValue(analytics),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
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
    expect(find.byKey(const Key('screen_03_onboarding_dob')), findsOneWidget);
    expect(find.text('Bước 1/4'), findsOneWidget);
    expect(find.text('Ngày sinh'), findsOneWidget);
    expect(find.text('Bạn sinh ngày nào?'), findsOneWidget);
    expect(find.text('Chọn ngày sinh'), findsNothing);
    expect(find.byKey(const Key('pick_dob_btn')), findsOneWidget);
    expect(find.byKey(const Key('dob_day')), findsOneWidget);
    expect(find.byKey(const Key('dob_month')), findsOneWidget);
    expect(find.byKey(const Key('dob_year')), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets(
    'DOB and consent remain overflow-free and actionable at 360dp and 1.4x text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpFlow(tester, textScaler: const TextScaler.linear(1.4));

      expect(
        find.byKey(const Key('onb_continue')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('onb_continue')));
      await tester.pump();

      expect(
        find.byKey(const Key('screen_04_onboarding_consent')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onb_continue')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('continue control remains reachable on a compact screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpFlow(tester);

    expect(find.byKey(const Key('onb_continue')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress announces the current step when content changes', (
    tester,
  ) async {
    await pumpFlow(tester);

    Semantics progress() => tester.widget<Semantics>(
      find.byKey(const Key('onb_progress_semantics')),
    );

    expect(progress().properties.liveRegion, isTrue);
    expect(progress().properties.label, 'Bước 1/4');

    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();

    expect(progress().properties.liveRegion, isTrue);
    expect(progress().properties.label, 'Bước 2/4');
  });

  testWidgets('back and primary controls stack at 200 percent text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpFlow(tester, textScaler: const TextScaler.linear(2));

    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();

    final backTop = tester.getTopLeft(find.byKey(const Key('onb_back')));
    final primaryTop = tester.getTopLeft(find.byKey(const Key('onb_continue')));
    expect(backTop.dy, lessThan(primaryTop.dy));
    expect(find.byKey(const Key('onb_back')).hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('onb_continue')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('step changes reset a compact viewport to the top', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpFlow(tester);

    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('onboarding_scroll')),
      const Offset(0, -500),
    );
    await tester.pump();

    ScrollPosition position() => tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const Key('onboarding_scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;

    expect(position().pixels, greaterThan(0));
    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();
    expect(position().pixels, 0);
    expect(
      find.byKey(const Key('onb_profile_preview')).hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('onboarding_scroll')),
      const Offset(0, -500),
    );
    await tester.pump();
    expect(position().pixels, greaterThan(0));

    await tester.tap(find.byKey(const Key('onb_back')));
    await tester.pump();
    expect(position().pixels, 0);
    expect(
      find.byKey(const Key('onb_profile_preview')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('consent CTA keeps marketing off and advances', (tester) async {
    await pumpFlow(tester);

    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();

    expect(
      find.byKey(const Key('screen_04_onboarding_consent')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('consent_all_btn')), findsOneWidget);
    expect(find.text('Bắt buộc'), findsNWidgets(4));
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

  testWidgets('log onboarding_step_x khi vào bước, chỉ đếm CHIỀU TIẾN (P0-3)', (
    tester,
  ) async {
    final analytics = RecordingAnalytics();
    await pumpFlow(tester, analytics: analytics);

    // Mount = vào bước 1.
    expect(analytics.events, ['onboarding_step_1']);

    await tester.tap(find.byKey(const Key('onb_continue')));
    await tester.pump();
    expect(analytics.events, ['onboarding_step_1', 'onboarding_step_2']);

    // Quay lại rồi tiến lại: back không log, re-enter bước 2 log lần nữa
    // vẫn hợp lệ cho funnel (max step) — nhưng CHỈ log khi đi tới.
    await tester.tap(find.byKey(const Key('onb_back')));
    await tester.pump();
    expect(analytics.events, ['onboarding_step_1', 'onboarding_step_2']);
  });
}
