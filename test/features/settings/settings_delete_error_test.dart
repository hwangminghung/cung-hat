import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import 'package:cung_hat/features/settings/presentation/settings_screen.dart';

class _MockSettingsRepo extends Mock implements SettingsRepository {}

/// Cùng helper với settings_toggle_error_test.dart: lọc DUY NHẤT assertion
/// ink-splash có sẵn (các SwitchListTile consent nằm trong Container màu của
/// _Section) — mọi exception khác, kể cả lỗi delete không được bắt (bug M1
/// đang test), vẫn làm test fail.
Future<void> _expectNoUnexpectedErrors(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final unexpected = <Object>[];
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains(
      'ListTile background color or ink splashes',
    )) {
      return;
    }
    unexpected.add(details.exception);
  };
  try {
    await body();
  } finally {
    FlutterError.onError = originalOnError;
  }
  expect(unexpected, isEmpty, reason: 'unexpected Flutter errors: $unexpected');
}

void main() {
  // [AUDIT M1] Trước đây _deleteAccount không try/catch: offline bấm Xóa →
  // unhandled exception, user không biết đã xoá hay chưa.
  testWidgets('xoá tài khoản lỗi mạng → SnackBar, không unhandled exception', (
    tester,
  ) async {
    final repo = _MockSettingsRepo();
    when(() => repo.myConsents()).thenAnswer((_) async => {});
    when(() => repo.deleteAccount()).thenThrow(StateError('net'));

    await _expectNoUnexpectedErrors(tester, () async {
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
    });

    expect(find.text('Không xoá được tài khoản, thử lại.'), findsOneWidget);
  });
}
