import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import 'package:cung_hat/features/settings/presentation/settings_screen.dart';

class _MockSettingsRepo extends Mock implements SettingsRepository {}

void main() {
  // [AUDIT M1] Trước đây _deleteAccount không try/catch: offline bấm Xóa →
  // unhandled exception, user không biết đã xoá hay chưa.
  testWidgets('xoá tài khoản lỗi mạng → SnackBar, không unhandled exception', (
    tester,
  ) async {
    final repo = _MockSettingsRepo();
    when(() => repo.myConsents()).thenAnswer((_) async => {});
    when(() => repo.deleteAccount()).thenThrow(StateError('net'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Xóa tài khoản'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa')); // nút confirm trong dialog
    await tester.pumpAndSettle();

    expect(find.text('Không xoá được tài khoản, thử lại.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
