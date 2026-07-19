import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/presentation/deck_action_bar.dart';

double _scaleOf(WidgetTester tester, Key key) {
  // _RoundButton(key: ...) builds Transform.scale(child: Material(...)) —
  // Transform is a DESCENDANT of the keyed widget, not an ancestor.
  final transform = tester.widget<Transform>(
    find
        .descendant(of: find.byKey(key), matching: find.byType(Transform))
        .first,
  );
  return transform.transform.getMaxScaleOnAxis();
}

void main() {
  testWidgets('4 nút quyết định đạt 44×44 và gọi được không cần vuốt', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeckActionBar(
            rewindEnabled: true,
            onRewind: () => calls.add('rewind'),
            onPass: () => calls.add('pass'),
            onSuperLike: () => calls.add('super'),
            onLike: () => calls.add('like'),
          ),
        ),
      ),
    );

    for (final action in ['rewind', 'pass', 'super', 'like']) {
      final button = find.byKey(Key('deck_${action}_btn'));
      expect(button, findsOneWidget);
      expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
      await tester.tap(button);
    }
    expect(calls, ['rewind', 'pass', 'super', 'like']);
  });

  testWidgets('hiện 4 nhãn hành động tiếng Việt bên dưới đúng thứ tự', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeckActionBar(
            rewindEnabled: true,
            onRewind: () {},
            onPass: () {},
            onSuperLike: () {},
            onLike: () {},
          ),
        ),
      ),
    );

    const labels = ['Quay lại', 'Bỏ qua', 'Siêu thích', 'Thích'];
    for (var index = 0; index < labels.length; index++) {
      final label = find.text(labels[index]);
      final button = find.byKey(
        Key('deck_${['rewind', 'pass', 'super', 'like'][index]}_btn'),
      );

      expect(label, findsOneWidget);
      expect(
        tester.getCenter(label).dy,
        greaterThan(tester.getCenter(button).dy),
      );
      if (index > 0) {
        expect(
          tester.getCenter(label).dx,
          greaterThan(tester.getCenter(find.text(labels[index - 1])).dx),
        );
      }
    }
  });

  testWidgets('4 nút gọi đúng callback', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeckActionBar(
            rewindEnabled: true,
            onRewind: () => calls.add('rewind'),
            onPass: () => calls.add('pass'),
            onSuperLike: () => calls.add('super'),
            onLike: () => calls.add('like'),
          ),
        ),
      ),
    );
    for (final k in ['rewind', 'pass', 'super', 'like']) {
      await tester.tap(find.byKey(Key('deck_${k}_btn')));
    }
    expect(calls, ['rewind', 'pass', 'super', 'like']);
  });

  testWidgets('rewindEnabled=false vẫn bấm được (để hiện upsell) nhưng mờ', (
    tester,
  ) async {
    var rewound = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeckActionBar(
            rewindEnabled: false,
            onRewind: () => rewound = true,
            onPass: () {},
            onSuperLike: () {},
            onLike: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('deck_rewind_btn')));
    expect(rewound, isTrue);
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const Key('deck_rewind_btn')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, lessThan(1));
  });

  testWidgets('hProgress dương → nút like phóng to, nút pass không đổi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeckActionBar(
            rewindEnabled: true,
            hProgress: 0.8,
            onRewind: () {},
            onPass: () {},
            onSuperLike: () {},
            onLike: () {},
          ),
        ),
      ),
    );

    expect(_scaleOf(tester, const Key('deck_like_btn')), greaterThan(1.1));
    expect(_scaleOf(tester, const Key('deck_pass_btn')), 1.0);
  });

  testWidgets('hProgress âm → nút pass phóng to, nút like không đổi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeckActionBar(
            rewindEnabled: true,
            hProgress: -0.8,
            onRewind: () {},
            onPass: () {},
            onSuperLike: () {},
            onLike: () {},
          ),
        ),
      ),
    );

    expect(_scaleOf(tester, const Key('deck_pass_btn')), greaterThan(1.1));
    expect(_scaleOf(tester, const Key('deck_like_btn')), 1.0);
  });

  testWidgets('vProgress âm → nút super phóng to', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeckActionBar(
            rewindEnabled: true,
            vProgress: -0.8,
            onRewind: () {},
            onPass: () {},
            onSuperLike: () {},
            onLike: () {},
          ),
        ),
      ),
    );

    expect(_scaleOf(tester, const Key('deck_super_btn')), greaterThan(1.1));
  });

  testWidgets('progress = 0 (mặc định) → mọi nút scale = 1.0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeckActionBar(
            rewindEnabled: true,
            onRewind: () {},
            onPass: () {},
            onSuperLike: () {},
            onLike: () {},
          ),
        ),
      ),
    );

    for (final k in ['rewind', 'pass', 'super', 'like']) {
      expect(_scaleOf(tester, Key('deck_${k}_btn')), 1.0);
    }
  });
}
