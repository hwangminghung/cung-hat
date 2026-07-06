import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/candidate_detail_sheet.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';

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
    // The sheet now embeds PhotoCarousel (ConsumerWidget) → signedUrlsProvider.
    // Override with an empty list so it renders the monogram fallback without
    // touching the uninitialized Supabase client.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        signedUrlsProvider('u1').overrideWith((ref) async => const <String>[]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CandidateDetailSheet(
              candidate: c,
              onPass: () => action = 'pass',
              onLike: () => action = 'like',
            ),
          ),
        ),
      ),
    ));
    expect(find.text('Mai, 24'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
    expect(find.text('#vpop'), findsOneWidget);
    expect(find.text('Nơi Này Có Anh'), findsOneWidget);
    // The 280px carousel now pushes the action row below the 600px test
    // viewport (in-app it lives in a scrollable sheet); scroll it in before tap.
    await tester.ensureVisible(find.byKey(const Key('detail_like_btn')));
    await tester.tap(find.byKey(const Key('detail_like_btn')));
    expect(action, 'like');
  });

  testWidgets('không có dữ liệu chung vẫn render (empty-safe)',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        signedUrlsProvider('u2').overrideWith((ref) async => const <String>[]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CandidateDetailSheet(
              candidate: const Candidate(id: 'u2'),
              onPass: () {},
              onLike: () {},
            ),
          ),
        ),
      ),
    ));
    expect(find.text('Bạn hát mới'), findsOneWidget);
    expect(find.text('Chưa có bài tủ chung — cơ hội khám phá!'),
        findsOneWidget);
  });

  testWidgets(
      'thẻ hỏi-đáp: hiện câu hỏi + câu trả lời cho prompt_id đã biết, bỏ qua prompt_id lạ',
      (tester) async {
    const c = Candidate(
      id: 'u3',
      displayName: 'Mai',
      age: 24,
      verified: false,
      prompts: [
        {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
        {'prompt_id': 'unknown_id', 'answer': 'khong hien'},
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        signedUrlsProvider('u3').overrideWith((ref) async => const <String>[]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CandidateDetailSheet(
              candidate: c,
              onPass: () {},
              onLike: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bài mình luôn giành mic là…'), findsOneWidget);
    expect(find.text('Em cua ngay hom qua'), findsOneWidget);
    expect(find.text('khong hien'), findsNothing);
  });

  testWidgets(
      'chế độ deck (onQuote null): KHÔNG render bất kỳ nút Trả lời nào',
      (tester) async {
    const c = Candidate(
      id: 'u4',
      displayName: 'Mai',
      age: 24,
      sharedBaitu: ['Nơi Này Có Anh'],
      prompts: [
        {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        signedUrlsProvider('u4').overrideWith((ref) async => const <String>[]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CandidateDetailSheet(
              candidate: c,
              onPass: () {},
              onLike: () {},
              // onQuote intentionally omitted (null) — deck mode.
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quote_photo')), findsNothing);
    expect(find.byKey(const Key('quote_baitu_0')), findsNothing);
    expect(find.byKey(const Key('quote_prompt_p1')), findsNothing);
    expect(find.text('Trả lời'), findsNothing);
    expect(find.text('Trả lời ảnh này'), findsNothing);
    // deck THÍCH/BỎ QUA buttons still present (unchanged).
    expect(find.byKey(const Key('detail_pass_btn')), findsOneWidget);
    expect(find.byKey(const Key('detail_like_btn')), findsOneWidget);
  });

  testWidgets(
      'chế độ icebreaker (onQuote khác null): ẩn nút THÍCH/BỎ QUA, hiện nút Trả lời',
      (tester) async {
    const c = Candidate(
      id: 'u5',
      displayName: 'Mai',
      age: 24,
      sharedBaitu: ['Nơi Này Có Anh'],
      prompts: [
        {'prompt_id': 'p1', 'answer': 'Em cua ngay hom qua'},
      ],
    );
    String? quoted;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        signedUrlsProvider('u5').overrideWith((ref) async => const <String>[]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CandidateDetailSheet(
              candidate: c,
              onQuote: (q) => quoted = q,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_pass_btn')), findsNothing);
    expect(find.byKey(const Key('detail_like_btn')), findsNothing);
    expect(find.byKey(const Key('quote_photo')), findsOneWidget);
    expect(find.byKey(const Key('quote_baitu_0')), findsOneWidget);
    expect(find.byKey(const Key('quote_prompt_p1')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('quote_baitu_0')));
    await tester.tap(find.byKey(const Key('quote_baitu_0')));
    expect(quoted, 'Về bài "Nơi Này Có Anh" của bạn: ');
  });
}
