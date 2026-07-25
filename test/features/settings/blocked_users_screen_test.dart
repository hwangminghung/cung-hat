import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import 'package:cung_hat/features/settings/presentation/blocked_users_screen.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

Widget _wrap(_MockSettingsRepository repo) => ProviderScope(
  overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(theme: AppTheme.light(), home: const BlockedUsersScreen()),
);

void main() {
  testWidgets('danh sach rong -> EmptyState "Chưa chặn ai"', (tester) async {
    final repo = _MockSettingsRepository();
    when(() => repo.myBlocks()).thenAnswer((_) async => const []);
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Chưa chặn ai'), findsOneWidget);
  });

  testWidgets('co nguoi bi chan -> hien ten + nut Bỏ chặn hoat dong', (
    tester,
  ) async {
    final repo = _MockSettingsRepository();
    var blocks = const [
      BlockedUser(
        userId: 'u9',
        displayName: 'Người Bị Chặn',
        createdAt: '2026-07-26T00:00:00Z',
      ),
    ];
    when(() => repo.myBlocks()).thenAnswer((_) async => blocks);
    when(() => repo.unblock('u9')).thenAnswer((_) async {
      blocks = const [];
    });

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    expect(find.text('Người Bị Chặn'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unblock_u9')));
    await tester.pumpAndSettle();

    verify(() => repo.unblock('u9')).called(1);
    // Sau khi bo chan, provider invalidate -> fetch lai -> danh sach rong.
    expect(find.text('Người Bị Chặn'), findsNothing);
    expect(find.text('Chưa chặn ai'), findsOneWidget);
  });

  testWidgets('unblock loi -> SnackBar, danh sach giu nguyen', (tester) async {
    final repo = _MockSettingsRepository();
    when(() => repo.myBlocks()).thenAnswer(
      (_) async => const [
        BlockedUser(
          userId: 'u9',
          displayName: 'Người Bị Chặn',
          createdAt: '2026-07-26T00:00:00Z',
        ),
      ],
    );
    when(() => repo.unblock('u9')).thenThrow(Exception('offline'));

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unblock_u9')));
    await tester.pumpAndSettle();

    expect(find.text('Không bỏ chặn được. Thử lại nhé.'), findsOneWidget);
    expect(find.text('Người Bị Chặn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tai danh sach loi -> error state co Thử lại', (tester) async {
    final repo = _MockSettingsRepository();
    var calls = 0;
    when(() => repo.myBlocks()).thenAnswer((_) async {
      calls++;
      // StateError (Error) bo qua auto-retry backoff cua Riverpod 3 — neu nem
      // Exception, provider tu retry va test khong bao gio thay error state.
      if (calls == 1) throw StateError('offline');
      return const [];
    });

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    expect(find.text('Không tải được danh sách. Thử lại nhé.'), findsOneWidget);

    // CTA cua EmptyState khong phai TextButton — tim theo chu.
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Chưa chặn ai'), findsOneWidget);
  });
}
