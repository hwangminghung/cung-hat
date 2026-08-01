import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/core/analytics/analytics_service.dart';
import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/chat/domain/song_share.dart';
import 'package:cung_hat/features/chat/presentation/chat_screen.dart';
import 'package:cung_hat/features/chat/presentation/chat_widgets.dart';

import '../../support/analytics_fakes.dart';

class _MockRepo extends Mock implements ChatRepository {}

void main() {
  testWidgets(
    'chat 1-1 keeps timeline and composer visible above a compact keyboard',
    (tester) async {
      const viewport = Size(360, 640);
      const keyboardHeight = 260.0;
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _MockRepo();
      when(() => repo.history(any())).thenAnswer((_) async => <Message>[]);
      when(
        () => repo.subscribe(any()),
      ).thenAnswer((_) => const Stream<Message>.empty());
      when(() => repo.markRead(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [chatRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const MediaQuery(
              data: MediaQueryData(
                size: viewport,
                viewInsets: EdgeInsets.only(bottom: keyboardHeight),
              ),
              child: ChatScreen(matchId: 't1', otherName: 'Linh'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final screen = find.byKey(const Key('screen_16_chat_1to1'));
      final timeline = find.byKey(const Key('chat_timeline'));
      final composer = find.byKey(const Key('chat_composer'));
      expect(screen, findsOneWidget);
      expect(timeline, findsOneWidget);
      expect(composer, findsOneWidget);

      final screenRect = tester.getRect(screen);
      final timelineRect = tester.getRect(timeline);
      final composerRect = tester.getRect(composer);
      expect(timelineRect.top, screenRect.top);
      expect(timelineRect.height, greaterThan(0));
      expect(timelineRect.bottom, composerRect.top);
      expect(
        composerRect.bottom,
        lessThanOrEqualTo(viewport.height - keyboardHeight),
      );
      expect(composerRect.bottom, screenRect.bottom);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('message bubbles keep normal ink text on tinted surfaces', (
    tester,
  ) async {
    const message = Message(
      id: 'm1',
      threadId: 't1',
      senderId: 'me',
      body: 'Chốt 20:00 nhé?',
      createdAt: '2026-07-20T10:00:00Z',
    );
    final songMessage = Message(
      id: 'm2',
      threadId: 't1',
      senderId: 'me',
      body: encodeSongShare('Ước Gì', 'Mỹ Tâm'),
      createdAt: '2026-07-20T10:01:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              const MessageBubble(
                key: Key('mine_bubble'),
                message: message,
                mine: true,
              ),
              const MessageBubble(
                key: Key('other_bubble'),
                message: message,
                mine: false,
              ),
              MessageBubble(
                key: const Key('mine_song_bubble'),
                message: songMessage,
                mine: true,
              ),
            ],
          ),
        ),
      ),
    );

    BoxDecoration decorationFor(Key key) {
      final container = tester.widget<Container>(
        find.descendant(of: find.byKey(key), matching: find.byType(Container)),
      );
      return container.decoration! as BoxDecoration;
    }

    expect(
      decorationFor(const Key('mine_bubble')).color,
      AppColors.primaryTint,
    );
    expect(decorationFor(const Key('other_bubble')).color, AppColors.surface);
    for (final text in tester.widgetList<Text>(find.text('Chốt 20:00 nhé?'))) {
      expect(text.style?.color, AppColors.ink);
    }
    expect(
      tester.widget<Text>(find.text('Ước Gì · Mỹ Tâm')).style?.color,
      AppColors.ink,
    );
  });

  testWidgets(
    'chat 1-1 remains overflow-free at required widths and text scales',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _MockRepo();
      when(() => repo.history(any())).thenAnswer((_) async => <Message>[]);
      when(
        () => repo.subscribe(any()),
      ).thenAnswer((_) => const Stream<Message>.empty());
      when(() => repo.markRead(any())).thenAnswer((_) async {});

      for (final width in const [360.0, 393.0, 430.0]) {
        for (final scale in const [1.0, 1.2, 1.4]) {
          await tester.binding.setSurfaceSize(Size(width, 800));
          final platform = width == 393 && scale == 1.4
              ? TargetPlatform.iOS
              : TargetPlatform.android;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [chatRepositoryProvider.overrideWithValue(repo)],
              child: MaterialApp(
                theme: AppTheme.light().copyWith(platform: platform),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 800),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const ChatScreen(
                    matchId: 'responsive-match',
                    otherName: 'Linh với tên hiển thị rất dài',
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(find.byKey(const Key('screen_16_chat_1to1')), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'overflow at ${width.toInt()}dp ×$scale on $platform',
          );
        }
      }
    },
  );

  testWidgets(
    'gửi tin 1-1 thành công → log chat_sent thread_type=match (P0-3)',
    (tester) async {
      final repo = _MockRepo();
      final analytics = RecordingAnalytics();
      when(() => repo.history(any())).thenAnswer((_) async => <Message>[]);
      when(
        () => repo.subscribe(any()),
      ).thenAnswer((_) => const Stream<Message>.empty());
      when(() => repo.markRead(any())).thenAnswer((_) async {});
      when(() => repo.sendMessage(any(), any())).thenAnswer((_) async => 'm1');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatRepositoryProvider.overrideWithValue(repo),
            analyticsProvider.overrideWithValue(analytics),
          ],
          child: const MaterialApp(
            home: ChatScreen(matchId: 't1', otherName: 'Linh'),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'đi hát nhé');
      // Nút gửi enable theo ValueListenableBuilder — cần frame sau khi gõ.
      await tester.pump();
      await tester.tap(find.byKey(const Key('send_btn')));
      await tester.pump();
      expect(analytics.events, ['chat_sent']);
      expect(analytics.params.single, {'thread_type': 'match'});
    },
  );
  testWidgets('typing a safe message and sending calls sendMessage', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.history(any())).thenAnswer((_) async => <Message>[]);
    when(
      () => repo.subscribe(any()),
    ).thenAnswer((_) => const Stream<Message>.empty());
    when(() => repo.markRead(any())).thenAnswer((_) async {});
    when(() => repo.sendMessage(any(), any())).thenAnswer((_) async => 'm1');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: ChatScreen(matchId: 't1', otherName: 'Linh'),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'đi hát nhé');
    // Nút gửi enable theo ValueListenableBuilder — cần frame sau khi gõ.
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_btn')));
    await tester.pump();
    verify(() => repo.sendMessage('t1', 'đi hát nhé')).called(1);
  });

  testWidgets('chat 1-1 chèn divider ngày + giờ HH:mm trên bubble', (
    tester,
  ) async {
    final repo = _MockRepo();
    const isoA = '2026-07-05T10:00:00Z';
    const isoB = '2026-07-06T11:30:00Z';
    when(() => repo.history(any())).thenAnswer(
      (_) async => const [
        Message(
          id: 'm1',
          threadId: 't1',
          senderId: 'u2',
          body: 'hom qua',
          createdAt: isoA,
        ),
        Message(
          id: 'm2',
          threadId: 't1',
          senderId: 'u2',
          body: 'hom nay',
          createdAt: isoB,
        ),
      ],
    );
    when(
      () => repo.subscribe(any()),
    ).thenAnswer((_) => const Stream<Message>.empty());
    when(() => repo.markRead(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: ChatScreen(matchId: 't1', otherName: 'Linh'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    String two(int v) => v.toString().padLeft(2, '0');
    final a = DateTime.parse(isoA).toLocal();
    final b = DateTime.parse(isoB).toLocal();
    expect(find.text('${a.day}/${a.month}'), findsOneWidget);
    expect(find.text('${b.day}/${b.month}'), findsOneWidget);
    expect(find.text('${two(a.hour)}:${two(a.minute)}'), findsOneWidget);
    expect(find.text('${two(b.hour)}:${two(b.minute)}'), findsOneWidget);
  });

  // [AUDIT] BANGIAO canh bao AppBar 4 action o 360dp x 1.4 "con du ~30dp".
  // Thuc te tren may: khong he co RenderFlex overflow (nen ca suite van xanh)
  // nhung Flutter am tham cat tieu de con "M…" — user khong biet dang nhan voi
  // ai. Phuong an da chot san trong BANGIAO: day "Lap keo" vao overflow menu.
  testWidgets('ten doi phuong khong bi cat o 360dp x textScale 1.4', (
    tester,
  ) async {
    const viewport = Size(360, 640);
    // Ten rieng VN dien hinh. Ten dai tuy y thi AppBar 360dp o 1.4 khong the
    // chua het — cat bot la dung; thu phai chan la tieu de bi bop con mot chu.
    const otherName = 'Linh';
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = _MockRepo();
    when(() => repo.history(any())).thenAnswer((_) async => <Message>[]);
    when(
      () => repo.subscribe(any()),
    ).thenAnswer((_) => const Stream<Message>.empty());
    when(() => repo.markRead(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: viewport,
              textScaler: TextScaler.linear(1.4),
            ),
            child: ChatScreen(matchId: 't1', otherName: otherName),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Nut chu rong khong duoc chiem cho cua tieu de.
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Lập kèo')),
      findsNothing,
      reason: 'Lập kèo phải nằm trong overflow menu, không phải action AppBar',
    );

    // Tieu de phai duoc ve DU be ngang tu nhien cua no — day moi la thu bat
    // duoc ellipsis, vi cat chu khong sinh ra exception nao ca.
    final title = tester.renderObject<RenderParagraph>(find.text(otherName));
    final natural = TextPainter(
      text: title.text,
      textDirection: TextDirection.ltr,
      textScaler: title.textScaler,
    )..layout();
    expect(
      title.size.width,
      greaterThanOrEqualTo(natural.width - 0.5),
      reason: 'tiêu đề bị cắt: vẽ ${title.size.width} < cần ${natural.width}',
    );
    // Va phai giu duoc phan lon be ngang AppBar. Truoc khi day "Lập kèo"
    // xuong overflow, cho nay chi con ~64dp (hien "M…") du khong he co
    // exception nao — nen day la chot chan chinh cho lan sau.
    expect(title.constraints.maxWidth, greaterThanOrEqualTo(160));

    // Van phai vao duoc Lap keo, chi la doi cho.
    await tester.tap(find.byKey(const Key('chat_menu_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Lập kèo'), findsOneWidget);
    expect(find.byKey(const Key('unmatch_btn')), findsOneWidget);
  });
}
