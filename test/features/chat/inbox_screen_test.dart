import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/chat/application/inbox_providers.dart';
import 'package:cung_hat/features/chat/data/match_inbox.dart';
import 'package:cung_hat/features/chat/presentation/inbox_screen.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
import 'package:cung_hat/shared/widgets/hard_card.dart';
import 'package:cung_hat/shared/widgets/responsive_frame.dart';
import 'package:cung_hat/shared/widgets/skeleton.dart';
import 'package:cung_hat/shared/widgets/stamp_chip.dart';
import 'package:cung_hat/shared/widgets/wave_divider.dart';

void main() {
  testWidgets(
    'section Kèo của bạn hiện kèo với chip x/y và Chủ kèo khi mình host',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxProvider.overrideWith((ref) async => <MatchSummary>[]),
            myKeosProvider.overrideWith(
              (ref) async => const [
                Keo(
                  id: 'k-mine',
                  title: 'Kèo demo tối nay',
                  areaLabel: 'Hoàn Kiếm, Hà Nội',
                  status: 'planning',
                  sizeTarget: 4,
                  slotsFilled: 2,
                  isMine: true,
                ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: InboxScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('screen_15_inbox')), findsOneWidget);
      expect(find.byKey(const Key('inbox_keo_section')), findsOneWidget);
      expect(find.text('Kèo của bạn'), findsOneWidget);
      expect(find.text('Kèo demo tối nay'), findsOneWidget);
      expect(
        find.text('Đang lên kế hoạch · Hoàn Kiếm, Hà Nội'),
        findsOneWidget,
      );
      expect(find.text('2/4'), findsOneWidget);
      expect(find.widgetWithText(StampChip, 'Chủ kèo'), findsOneWidget);
      expect(find.byType(HardCard), findsOneWidget);
      // Có kèo → KHÔNG rơi vào EmptyState dù chưa có match nào.
      expect(find.byType(EmptyState), findsNothing);
    },
  );

  testWidgets(
    'member (không phải host) không thấy chip Chủ kèo; matches vẫn render đủ',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxProvider.overrideWith(
              (ref) async => [
                MatchSummary(
                  matchId: 'm1',
                  otherId: 'other-id',
                  otherName: 'Linh',
                  unread: 0,
                  lastSenderId: 'me',
                ),
              ],
            ),
            myProfileProvider.overrideWith(
              (ref) => Future.value(const Profile(id: 'me')),
            ),
            myKeosProvider.overrideWith(
              (ref) async => const [
                Keo(
                  id: 'k-joined',
                  title: 'Tối thứ 6 hát Ballad',
                  status: 'open',
                  sizeTarget: 3,
                  slotsFilled: 1,
                ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: InboxScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('screen_15_inbox')), findsOneWidget);
      expect(find.byKey(const Key('inbox_keo_section')), findsOneWidget);
      expect(find.byKey(const Key('inbox_match_section')), findsOneWidget);
      expect(find.text('Kèo của bạn'), findsOneWidget);
      expect(find.widgetWithText(StampChip, 'Chủ kèo'), findsNothing);
      expect(find.text('Tin nhắn đôi'), findsOneWidget);
      expect(find.text('Linh'), findsOneWidget);
      expect(find.byType(HardCard), findsNWidgets(2));
      // One header wave plus exactly one divider between the two sections.
      expect(find.byType(WaveDivider), findsNWidgets(2));
    },
  );

  testWidgets('không có kèo → không hiện label Kèo của bạn', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inboxProvider.overrideWith(
            (ref) async => [
              MatchSummary(
                matchId: 'm2',
                otherId: 'other-id',
                otherName: 'An',
                unread: 0,
                lastSenderId: 'me',
              ),
            ],
          ),
          myProfileProvider.overrideWith(
            (ref) => Future.value(const Profile(id: 'me')),
          ),
          myKeosProvider.overrideWith((ref) async => const <Keo>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: InboxScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Kèo của bạn'), findsNothing);
    expect(find.text('Tin nhắn đôi'), findsOneWidget);
  });

  testWidgets('empty inbox keeps the existing find-Kèo CTA callback', (
    tester,
  ) async {
    var findKeoCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inboxProvider.overrideWith((ref) async => <MatchSummary>[]),
          myKeosProvider.overrideWith((ref) async => const <Keo>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: InboxScreen(onFindKeo: () => findKeoCalls++)),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('screen_15_inbox')), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Chưa có cuộc trò chuyện'), findsOneWidget);
    expect(find.text('Tìm kèo'), findsOneWidget);

    await tester.tap(find.text('Tìm kèo'));
    expect(findKeoCalls, 1);
  });

  testWidgets('loading inbox reserves three list-row skeletons', (
    tester,
  ) async {
    final pending = Completer<List<MatchSummary>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inboxProvider.overrideWith((ref) => pending.future),
          myKeosProvider.overrideWith((ref) async => const <Keo>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: InboxScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('screen_15_inbox')), findsOneWidget);
    expect(find.byType(ResponsiveFrame), findsOneWidget);
    expect(find.byType(SkeletonTile), findsNWidgets(3));
    for (final skeleton in find.byType(SkeletonTile).evaluate()) {
      expect(
        tester.getSize(find.byWidget(skeleton.widget)).height,
        greaterThanOrEqualTo(68),
      );
    }
  });

  testWidgets('inbox hiện tiêu đề section Tin nhắn đôi khi có match', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inboxProvider.overrideWith(
            (ref) async => [
              MatchSummary(
                matchId: 't4',
                otherId: 'other-id',
                otherName: 'Linh',
                unread: 0,
                lastSenderId: 'me',
              ),
            ],
          ),
          myProfileProvider.overrideWith(
            (ref) => Future.value(const Profile(id: 'me')),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: InboxScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Tin nhắn đôi'), findsOneWidget);
  });

  testWidgets(
    'match rows use HardCards without WaveDividers between messages',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxProvider.overrideWith(
              (ref) async => [
                MatchSummary(
                  matchId: 't5',
                  otherId: 'other-id-1',
                  otherName: 'Linh',
                  unread: 1,
                  lastSenderId: 'other-id-1',
                ),
                MatchSummary(
                  matchId: 't6',
                  otherId: 'other-id-2',
                  otherName: 'An',
                  unread: 0,
                  lastSenderId: 'me',
                ),
              ],
            ),
            myProfileProvider.overrideWith(
              (ref) => Future.value(const Profile(id: 'me')),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: InboxScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(HardCard), findsNWidgets(2));
      // The only wave belongs to TabHeader; message rows do not add dividers.
      expect(find.byType(WaveDivider), findsOneWidget);
    },
  );

  testWidgets(
    'inbox remains overflow-free at required widths and text scales',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final width in const [360.0, 393.0, 430.0]) {
        for (final scale in const [1.0, 1.2, 1.4]) {
          await tester.binding.setSurfaceSize(Size(width, 800));
          final platform = width == 393 && scale == 1.4
              ? TargetPlatform.iOS
              : TargetPlatform.android;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                inboxProvider.overrideWith(
                  (ref) async => [
                    MatchSummary(
                      matchId: 'responsive-match',
                      otherId: 'other-id',
                      otherName: 'Linh với một tên hiển thị rất dài',
                      unread: 12,
                      lastSenderId: 'other-id',
                    ),
                  ],
                ),
                myProfileProvider.overrideWith(
                  (ref) => Future.value(const Profile(id: 'me')),
                ),
                myKeosProvider.overrideWith(
                  (ref) async => const [
                    Keo(
                      id: 'responsive-keo',
                      title: 'Kèo V-Pop tối nay với tiêu đề rất dài',
                      areaLabel: 'Thủ Đức, Thành phố Hồ Chí Minh',
                      status: 'planning',
                      sizeTarget: 5,
                      slotsFilled: 3,
                      isMine: true,
                    ),
                  ],
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.light().copyWith(platform: platform),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 800),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const Scaffold(body: InboxScreen()),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(find.byKey(const Key('screen_15_inbox')), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow at ${width.toInt()}dp ×$scale on $platform',
          );
        }
      }
    },
  );
}
