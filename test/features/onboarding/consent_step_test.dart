import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/onboarding/presentation/consent_step.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import 'package:cung_hat/shared/widgets/hard_card.dart';

const _allOff = {
  'location': false,
  'photos': false,
  'matching': false,
  'marketing': false,
  'cross_border': false,
};

Future<void> pumpConsentStep(
  WidgetTester tester, {
  required void Function(String, bool) onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ConsentStep(values: _allOff, onChanged: onChanged),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('marketing switch reports its new value', (tester) async {
    final changes = <String, bool>{};
    await pumpConsentStep(
      tester,
      onChanged: (key, value) => changes[key] = value,
    );

    await tester.tap(find.byKey(const Key('consent_marketing')));
    await tester.pump();

    expect(changes, equals(<String, bool>{'marketing': true}));
  });

  testWidgets('renders four required info rows and one optional switch', (
    tester,
  ) async {
    await pumpConsentStep(tester, onChanged: (_, _) {});

    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('consent_marketing')))
          .value,
      isFalse,
    );
    expect(find.text('Bắt buộc'), findsNWidgets(4));

    const requiredKeys = [
      Key('consent_location'),
      Key('consent_photos'),
      Key('consent_matching'),
      Key('consent_cross_border'),
    ];
    for (final key in requiredKeys) {
      expect(find.byKey(key), findsOneWidget);
    }

    final rowTops = [
      for (final key in requiredKeys) tester.getTopLeft(find.byKey(key)).dy,
    ];
    expect(rowTops, orderedEquals([...rowTops]..sort()));

    for (final purpose in consentPurposes) {
      expect(find.byKey(Key('consent_$purpose')), findsOneWidget);
    }
  });

  testWidgets('groups required and optional consent rows in one calm list', (
    tester,
  ) async {
    await pumpConsentStep(tester, onChanged: (_, _) {});

    final list = find.byType(HardCard);
    expect(list, findsOneWidget);
    for (final purpose in consentPurposes) {
      expect(
        find.descendant(
          of: list,
          matching: find.byKey(Key('consent_$purpose')),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('P2-b: nút gộp bật các mục bắt buộc trong một chạm', (
    tester,
  ) async {
    final changes = <String, bool>{};
    await pumpConsentStep(
      tester,
      onChanged: (key, value) => changes[key] = value,
    );

    await tester.ensureVisible(find.byKey(const Key('consent_all_btn')));
    await tester.tap(find.byKey(const Key('consent_all_btn')));
    await tester.pump();

    for (final purpose in requiredConsents) {
      expect(
        changes[purpose],
        isTrue,
        reason: 'purpose $purpose phải được bật',
      );
    }
  });

  // [AUDIT C1] Đồng ý nhận quảng cáo bắt buộc phải là opt-in riêng. Trước đây
  // nút gộp bật luôn cả marketing, khiến sự đồng ý không còn tự nguyện và có
  // thể bị coi là vô hiệu theo Nghị định 13/2023/NĐ-CP.
  testWidgets('nút gộp KHÔNG đụng tới marketing', (tester) async {
    final changes = <String, bool>{};
    await pumpConsentStep(
      tester,
      onChanged: (key, value) => changes[key] = value,
    );

    await tester.ensureVisible(find.byKey(const Key('consent_all_btn')));
    await tester.tap(find.byKey(const Key('consent_all_btn')));
    await tester.pump();

    expect(
      changes.containsKey('marketing'),
      isFalse,
      reason: 'marketing chỉ được bật bằng công tắc riêng',
    );
  });

  // [AUDIT C1] Chuyển dữ liệu ra nước ngoài là một mục đích RIÊNG theo Nghị
  // định 13. Nhãn cũ gộp nó chung câu với Điều khoản + Chính sách bảo mật nên
  // không thể từ chối riêng phần lưu dữ liệu tại Singapore.
  testWidgets('nhãn cross_border chỉ nói về việc lưu dữ liệu, không gộp '
      'Điều khoản/Bảo mật', (tester) async {
    await pumpConsentStep(tester, onChanged: (_, _) {});

    final label = consentLabel('cross_border', null);
    expect(label, contains('Singapore'));
    expect(label, isNot(contains('Điều khoản')));
    expect(label, isNot(contains('Chính sách bảo mật')));

    // Điều khoản + Bảo mật được nêu riêng, kèm link đọc được.
    expect(find.byKey(const Key('consent_tos_notice')), findsOneWidget);
  });
}
