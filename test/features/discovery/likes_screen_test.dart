import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/likes_screen.dart';

class _MockRepo extends Mock implements DiscoveryRepository {}

void main() {
  const linh = Candidate(id: 'u2', displayName: 'Linh');

  Widget host(_MockRepo repo, {List<Candidate> people = const [linh]}) {
    return ProviderScope(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(repo),
        whoLikedMeProvider.overrideWith((ref) async => people),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const LikesScreen()),
    );
  }

  // [MATCH-AUDIT #4b] Màn 99k trước đây CHỈ hiện tên — thấy người thích mình
  // xong phải ngồi chờ gặp lại họ trong deck. Người trong danh sách này đã
  // like mình nên "thích lại" phải tạo match ngay.
  testWidgets('mỗi người có nút Thích lại', (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('like_back_u2')), findsOneWidget);
    expect(find.text('Thích lại'), findsOneWidget);
  });

  testWidgets('bấm Thích lại → record_swipe like, match → snackbar ghép đôi', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(() => repo.recordSwipe('u2', 'like')).thenAnswer((_) async => true);
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('like_back_u2')));
    await tester.pumpAndSettle();

    verify(() => repo.recordSwipe('u2', 'like')).called(1);
    expect(find.textContaining('Đã ghép đôi với Linh'), findsOneWidget);
  });

  testWidgets('hết lượt thích → hiện đúng thông báo quota, không crash', (
    tester,
  ) async {
    final repo = _MockRepo();
    when(
      () => repo.recordSwipe('u2', 'like'),
    ).thenAnswer((_) async => throw Exception('like_limit'));
    await tester.pumpWidget(host(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('like_back_u2')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('hết lượt thích'), findsOneWidget);
  });
}
