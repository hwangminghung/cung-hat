import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import 'package:cung_hat/features/settings/presentation/settings_screen.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  group('SettingsScreen — consent toggle lỗi RPC', () {
    testWidgets(
      'grantConsent lỗi → SnackBar báo lỗi, không crash, switch giữ nguyên',
      (tester) async {
        final repo = _MockSettingsRepository();
        when(
          () => repo.grantConsent(any()),
        ).thenAnswer((_) async => throw Exception('offline'));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(repo),
              myConsentsProvider.overrideWith(
                (ref) async => <String, bool>{'marketing': false},
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('consent_marketing')));
        await tester.pumpAndSettle();

        expect(find.text('Không lưu được cài đặt, thử lại.'), findsOneWidget);

        final switchTile = tester.widget<SwitchListTile>(
          find.byKey(const Key('consent_marketing')),
        );
        expect(switchTile.value, isFalse);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'withdrawConsent lỗi → SnackBar báo lỗi, không crash, switch giữ nguyên',
      (tester) async {
        final repo = _MockSettingsRepository();
        when(
          () => repo.withdrawConsent(any()),
        ).thenAnswer((_) async => throw Exception('offline'));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(repo),
              myConsentsProvider.overrideWith(
                (ref) async => <String, bool>{'marketing': true},
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('consent_marketing')));
        await tester.pumpAndSettle();

        expect(find.text('Không lưu được cài đặt, thử lại.'), findsOneWidget);

        final switchTile = tester.widget<SwitchListTile>(
          find.byKey(const Key('consent_marketing')),
        );
        expect(switchTile.value, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'grantConsent thành công → không SnackBar lỗi, gọi repository đúng purpose',
      (tester) async {
        final repo = _MockSettingsRepository();
        when(() => repo.grantConsent(any())).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(repo),
              myConsentsProvider.overrideWith(
                (ref) async => <String, bool>{'marketing': false},
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('consent_marketing')));
        await tester.pumpAndSettle();

        expect(find.text('Không lưu được cài đặt, thử lại.'), findsNothing);
        verify(() => repo.grantConsent('marketing')).called(1);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
