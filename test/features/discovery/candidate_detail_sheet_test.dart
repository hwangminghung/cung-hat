import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/candidate_detail_sheet.dart';

void main() {
  const c = Candidate(
    id: 'u1',
    displayName: 'Mai',
    age: 24,
    distanceBand: '1-3',
    sharedGenres: ['vpop', 'ballad'],
    sharedBaitu: ['Nơi Này Có Anh', 'Lạc Trôi'],
    verified: true,
    activeToday: true,
  );

  testWidgets('hiện đủ tên tuổi, khoảng cách, gu chung, bài tủ chung',
      (tester) async {
    String? action;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CandidateDetailSheet(
            candidate: c,
            onPass: () => action = 'pass',
            onLike: () => action = 'like',
          ),
        ),
      ),
    ));
    expect(find.text('Mai, 24'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
    expect(find.text('#vpop'), findsOneWidget);
    expect(find.text('Nơi Này Có Anh'), findsOneWidget);
    await tester.tap(find.byKey(const Key('detail_like_btn')));
    expect(action, 'like');
  });

  testWidgets('không có dữ liệu chung vẫn render (empty-safe)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CandidateDetailSheet(
            candidate: const Candidate(id: 'u2'),
            onPass: () {},
            onLike: () {},
          ),
        ),
      ),
    ));
    expect(find.text('Bạn hát mới'), findsOneWidget);
    expect(find.text('Chưa có bài tủ chung — cơ hội khám phá!'),
        findsOneWidget);
  });
}
