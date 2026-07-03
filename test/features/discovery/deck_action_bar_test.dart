import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/presentation/deck_action_bar.dart';

void main() {
  testWidgets('4 nút gọi đúng callback', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeckActionBar(
          rewindEnabled: true,
          onRewind: () => calls.add('rewind'),
          onPass: () => calls.add('pass'),
          onSuperLike: () => calls.add('super'),
          onLike: () => calls.add('like'),
        ),
      ),
    ));
    for (final k in ['rewind', 'pass', 'super', 'like']) {
      await tester.tap(find.byKey(Key('deck_${k}_btn')));
    }
    expect(calls, ['rewind', 'pass', 'super', 'like']);
  });

  testWidgets('rewindEnabled=false vẫn bấm được (để hiện upsell) nhưng mờ',
      (tester) async {
    var rewound = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeckActionBar(
          rewindEnabled: false,
          onRewind: () => rewound = true,
          onPass: () {},
          onSuperLike: () {},
          onLike: () {},
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('deck_rewind_btn')));
    expect(rewound, isTrue);
    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.byKey(const Key('deck_rewind_btn')),
        matching: find.byType(Opacity),
      ).first,
    );
    expect(opacity.opacity, lessThan(1));
  });
}
