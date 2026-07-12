import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/keo/presentation/create_keo_screen.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/onboarding/application/reference_providers.dart';
import 'package:cung_hat/features/onboarding/domain/music_ref.dart';
import 'package:cung_hat/shared/widgets/gradient_button.dart';
import 'package:cung_hat/shared/widgets/wave_divider.dart';

class _MockRepo extends Mock implements KeoRepository {}

void main() {
  test('createKeo forwards all fields', () async {
    final repo = _MockRepo();
    when(
      () => repo.createKeo(
        title: any(named: 'title'),
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
        area: any(named: 'area'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        size: any(named: 'size'),
        intent: any(named: 'intent'),
        vibe: any(named: 'vibe'),
        genres: any(named: 'genres'),
      ),
    ).thenAnswer((_) async => 'k1');
    final c = ProviderContainer(
      overrides: [keoRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    final id = await c
        .read(keoRepositoryProvider)
        .createKeo(
          title: 'X',
          lat: 10.7,
          lng: 106.7,
          area: 'Q1',
          start: DateTime(2026, 6, 21, 19),
          end: DateTime(2026, 6, 21, 22),
          size: 4,
          intent: 'fun',
          vibe: 'chill',
          genres: const ['vpop'],
        );
    expect(id, 'k1');
  });

  testWidgets(
    'create screen keeps editable title and preserved retro control keys',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            genresProvider.overrideWith(
              (ref) async => const [
                Genre(id: 'vpop', nameVi: 'V-Pop', nameEn: 'V-Pop'),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const CreateKeoScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleField = find.byKey(const Key('create_keo_title_field'));
      expect(titleField, findsOneWidget);
      expect(titleField.evaluate().single.widget, isA<TextField>());
      await tester.enterText(titleField, 'V-Pop tối nay');
      expect(
        tester.widget<TextField>(titleField).controller?.text,
        'V-Pop tối nay',
      );

      expect(find.byKey(const Key('create_keo_venue_hint')), findsOneWidget);
      expect(find.byKey(const Key('create_keo_genre_grid')), findsOneWidget);
      expect(find.byKey(const Key('keo_genre_vpop')), findsOneWidget);
      final approvalChoice = find.byKey(const Key('create_keo_join_approval'));
      final openChoice = find.byKey(const Key('create_keo_join_open'));
      expect(approvalChoice, findsOneWidget);
      expect(openChoice, findsOneWidget);
      expect(
        tester.widget<Semantics>(approvalChoice).properties.selected,
        isTrue,
      );
      expect(tester.widget<Semantics>(openChoice).properties.selected, isFalse);
      expect(find.byType(SegmentedButton<String>), findsNothing);
      expect(find.byType(WaveDivider), findsWidgets);
      expect(find.widgetWithText(GradientButton, 'Tạo kèo'), findsOneWidget);
      expect(find.byKey(const Key('create_keo_btn')), findsOneWidget);
    },
  );

  testWidgets('create form remains scrollable at 320px with large text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [genresProvider.overrideWith((ref) async => [])],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(2),
            ),
            child: CreateKeoScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byKey(const Key('create_keo_btn')), findsOneWidget);
  });
}
