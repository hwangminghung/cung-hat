import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/keo/domain/keo_member.dart';
import 'package:cung_hat/features/keo/presentation/keo_detail_screen.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

class _MockRepo extends Mock implements KeoRepository {}

void main() {
  testWidgets('renders roster and Xin vào kèo button', (tester) async {
    final repo = _MockRepo();
    when(() => repo.roster('k1')).thenAnswer((_) async =>
        const [KeoMember(userId: 'u1', displayName: 'Mai', verified: true, role: 'host', joinStatus: 'approved')]);
    when(() => repo.requestJoin('k1')).thenAnswer((_) async {});
    await tester.pumpWidget(ProviderScope(
      overrides: [
        keoRepositoryProvider.overrideWithValue(repo),
        myProfileProvider.overrideWith((ref) => Future<Profile?>.value(null)),
      ],
      child: const MaterialApp(home: KeoDetailScreen(keoId: 'k1', title: 'Hát tối T7')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mai'), findsOneWidget);
    await tester.tap(find.byKey(const Key('request_join_btn')));
    await tester.pump();
    verify(() => repo.requestJoin('k1')).called(1);
  });

  testWidgets('free_join_limit error shows the upgrade dialog', (tester) async {
    final repo = _MockRepo();
    when(() => repo.roster('k1')).thenAnswer((_) async => const []);
    when(() => repo.requestJoin('k1')).thenThrow(
        'PostgrestException(message: free_join_limit, code: 23514)');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        keoRepositoryProvider.overrideWithValue(repo),
        myProfileProvider.overrideWith((ref) => Future<Profile?>.value(null)),
      ],
      child: const MaterialApp(home: KeoDetailScreen(keoId: 'k1', title: 'Hát tối T7')),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request_join_btn')));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Bạn đang tham gia 1 kèo. Rời kèo cũ hoặc nâng cấp Pro để tham gia thêm.'),
        findsOneWidget);
    expect(find.text('Nâng cấp Pro'), findsOneWidget);
  });
}
