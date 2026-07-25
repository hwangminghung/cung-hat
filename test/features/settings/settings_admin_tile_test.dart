import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import 'package:cung_hat/features/settings/presentation/settings_screen.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

Widget _wrap(_MockSettingsRepository repo, {required bool isAdmin}) =>
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
        myConsentsProvider.overrideWith((ref) async => <String, bool>{}),
        isAdminProvider.overrideWith((ref) async => isAdmin),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const SettingsScreen()),
    );

void main() {
  // [DEBT] /admin tung la route mo coi — khong loi vao nao tren UI.
  // ListView cua Settings KHONG lazy (children list) nen chi can assert
  // ton tai, khong can keo vao vung nhin thay.
  testWidgets('admin -> thay tile Khu quản trị', (tester) async {
    await tester.pumpWidget(_wrap(_MockSettingsRepository(), isAdmin: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_admin_tile')), findsOneWidget);
  });

  testWidgets('user thuong -> KHONG co tile Khu quản trị', (tester) async {
    await tester.pumpWidget(_wrap(_MockSettingsRepository(), isAdmin: false));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_admin_tile')), findsNothing);
  });

  testWidgets('tile Đã chặn luon hien voi moi user', (tester) async {
    await tester.pumpWidget(_wrap(_MockSettingsRepository(), isAdmin: false));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_blocked_tile')), findsOneWidget);
  });
}
