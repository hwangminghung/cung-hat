import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/discovery/presentation/match_celebration.dart';
import 'package:cung_hat/features/onboarding/application/reference_providers.dart';
import 'package:cung_hat/features/onboarding/domain/music_ref.dart';

/// sharedBaitu giữ SONG ID thô — MatchCelebration resolve tên qua
/// songsProvider (override ở đây); id lạ fallback raw id.
const _songs = [
  Song(id: 's5', title: 'Nơi Này Có Anh', artist: 'Sơn Tùng M-TP'),
];

void main() {
  testWidgets(
    'cream surface + 2 thẻ danh tính viền mực nghiêng, không bịa ảnh',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            songsProvider.overrideWith((ref) async => const <Song>[]),
          ],
          child: MaterialApp(
            home: MatchCelebration(
              otherName: 'Mai',
              myName: 'Minh',
              sharedBaitu: const [],
              onChat: () {},
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      final surface = tester.widget<Container>(
        find.byKey(const Key('match_cream_surface')),
      );
      expect(
        (surface.decoration! as BoxDecoration).color,
        AppColors.background,
      );

      for (final key in const ['match_identity_my', 'match_identity_other']) {
        final finder = find.byKey(Key(key));
        final card = tester.widget<Container>(finder);
        final decoration = card.decoration! as BoxDecoration;
        expect(decoration.color, AppColors.surface);
        expect(decoration.border!.top.color, AppColors.ink);
        expect(decoration.border!.top.width, 2);

        final transforms = tester.widgetList<Transform>(
          find.ancestor(of: finder, matching: find.byType(Transform)),
        );
        expect(
          transforms.any(
            (transform) => transform.transform.entry(0, 1).abs() > 0.01,
          ),
          isTrue,
        );
      }
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets(
    'hiện tên, bài tủ chung (TÊN bài + fallback raw id), 2 nút hành động',
    (tester) async {
      var chat = false;
      var continued = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [songsProvider.overrideWith((ref) async => _songs)],
          child: MaterialApp(
            home: MatchCelebration(
              otherName: 'Mai',
              myName: 'Minh',
              // s5 có trong bảng songs (→ tên), s9 không (→ raw id fallback).
              sharedBaitu: const ['s5', 's9'],
              onChat: () => chat = true,
              onContinue: () => continued = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500)); // hết entrance
      expect(find.textContaining('Mai'), findsWidgets);
      expect(find.textContaining('Nơi Này Có Anh'), findsOneWidget);
      expect(find.textContaining('s9'), findsOneWidget); // fallback raw id
      expect(find.textContaining('s5'), findsNothing); // id đã resolve → ẩn
      await tester.tap(find.byKey(const Key('match_chat_btn')));
      expect(chat, isTrue);
      await tester.tap(find.byKey(const Key('match_continue_btn')));
      expect(continued, isTrue);
    },
  );

  testWidgets(
    'reduced motion: nhảy thẳng tới trạng thái cuối, vẫn tương tác được',
    (tester) async {
      var chat = false;

      T closestAncestor<T extends Widget>(Finder finder) {
        T? result;
        tester.element(finder).visitAncestorElements((element) {
          if (element.widget case final T widget) {
            result = widget;
            return false;
          }
          return true;
        });
        return result!;
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            songsProvider.overrideWith((ref) async => const <Song>[]),
          ],
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: MatchCelebration(
                otherName: 'Linh',
                myName: 'An',
                sharedBaitu: const [],
                onChat: () => chat = true,
                onContinue: () {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('screen_09_match_celebration')),
        findsOneWidget,
      );
      for (final key in const [
        Key('match_identity_my'),
        Key('match_identity_other'),
      ]) {
        final card = find.byKey(key);
        expect(card, findsOneWidget);
        final transforms = tester.widgetList<Transform>(
          find.ancestor(of: card, matching: find.byType(Transform)),
        );
        expect(
          transforms.map((transform) => transform.transform.entry(0, 3)),
          everyElement(closeTo(0, 0.001)),
          reason: '$key must be at its final horizontal position',
        );
      }

      final title = find.text('Hợp cạ rồi!');
      final titleFade = closestAncestor<FadeTransition>(title);
      final titleScale = closestAncestor<ScaleTransition>(title);
      expect(titleFade.opacity.value, 1);
      expect(titleScale.scale.value, 1);

      expect(find.byKey(const Key('match_chat_btn')), findsOneWidget);
      expect(find.byKey(const Key('match_continue_btn')), findsOneWidget);
      expect(find.textContaining('Linh'), findsWidgets);
      await tester.tap(find.byKey(const Key('match_chat_btn')));
      expect(chat, isTrue);
    },
  );

  testWidgets(
    'hierarchy stays visible across required widths and text scales',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final width in const [360.0, 393.0, 430.0]) {
        for (final scale in const [1.0, 1.2, 1.4]) {
          await tester.binding.setSurfaceSize(Size(width, 844));
          final platform = width == 393 && scale == 1.4
              ? TargetPlatform.iOS
              : TargetPlatform.android;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                songsProvider.overrideWith((ref) async => const <Song>[]),
              ],
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 844),
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: MaterialApp(
                  theme: AppTheme.light().copyWith(platform: platform),
                  home: MatchCelebration(
                    otherName: 'Linh',
                    myName: 'Minh',
                    sharedBaitu: const ['s5'],
                    onChat: () {},
                    onContinue: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason: '${width}dp ×$scale on $platform',
          );
          expect(
            find.byKey(const Key('screen_09_match_celebration')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('match_chat_btn')), findsOneWidget);
          expect(find.byKey(const Key('match_continue_btn')), findsOneWidget);
        }
      }
    },
  );
}
