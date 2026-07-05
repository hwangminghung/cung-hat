import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/candidate_card.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';

const _cand = Candidate(
  id: 'u1',
  displayName: 'Linh',
  age: 24,
  distanceBand: '1-3',
  sharedGenres: ['ballad', 'kpop'],
  sharedBaitu: ['s1', 's2'],
  bio: 'Hát ballad về đêm',
);

Widget _host({List<String> urls = const ['u1.jpg', 'u2.jpg', 'u3.jpg']}) {
  return ProviderScope(
    overrides: [
      signedUrlsProvider('u1').overrideWith((ref) async => urls),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: CandidateCard(candidate: _cand, onOpenDetail: () {}),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'ảnh 1: chip khoảng cách + bài tủ; tap phải → ảnh 2: genres; tiếp → bio',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.textContaining('Cách 1-3 km'), findsOneWidget);
    expect(find.textContaining('cùng 2 bài tủ'), findsOneWidget);
    expect(find.text('#ballad'), findsNothing);

    final photoArea = find.byKey(const Key('card_photo_area'));
    final rect = tester.getRect(photoArea);
    await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('#ballad'), findsOneWidget);
    expect(find.textContaining('Cách 1-3 km'), findsNothing);

    await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Hát ballad về đêm'), findsOneWidget);

    await tester.tapAt(Offset(rect.left + 20, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('#ballad'), findsOneWidget);
  });

  testWidgets('nút ⓘ mở detail (callback)', (tester) async {
    var opened = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        signedUrlsProvider('u1').overrideWith((ref) async => ['u1.jpg']),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CandidateCard(
              candidate: _cand, onOpenDetail: () => opened = true),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('card_detail_btn')));
    expect(opened, isTrue);
  });

  testWidgets('<2 ảnh: chip gộp như cũ (distance + baitu + genres)',
      (tester) async {
    await tester.pumpWidget(_host(urls: ['u1.jpg']));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cách 1-3 km'), findsOneWidget);
    expect(find.text('#ballad'), findsOneWidget);
  });
}
