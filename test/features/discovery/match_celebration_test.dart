import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/presentation/match_celebration.dart';

void main() {
  testWidgets('hiện tên, bài tủ chung, 2 nút hành động', (tester) async {
    var chat = false;
    var continued = false;
    await tester.pumpWidget(MaterialApp(
      home: MatchCelebration(
        otherName: 'Mai',
        myName: 'Minh',
        sharedBaitu: const ['Lạc Trôi'],
        onChat: () => chat = true,
        onContinue: () => continued = true,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 1500)); // hết entrance
    expect(find.textContaining('Mai'), findsWidgets);
    expect(find.textContaining('Lạc Trôi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('match_chat_btn')));
    expect(chat, isTrue);
    await tester.tap(find.byKey(const Key('match_continue_btn')));
    expect(continued, isTrue);
  });

  testWidgets(
      'reduced motion: nhảy thẳng tới trạng thái cuối, vẫn tương tác được',
      (tester) async {
    var chat = false;
    await tester.pumpWidget(MediaQuery(
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
    ));
    await tester.pump();

    expect(find.textContaining('Linh'), findsWidgets);
    await tester.tap(find.byKey(const Key('match_chat_btn')));
    expect(chat, isTrue);
  });
}
