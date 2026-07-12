import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_colors.dart';
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
      await tester.pump();

      expect(find.textContaining('Linh'), findsWidgets);
      await tester.tap(find.byKey(const Key('match_chat_btn')));
      expect(chat, isTrue);
    },
  );
}
