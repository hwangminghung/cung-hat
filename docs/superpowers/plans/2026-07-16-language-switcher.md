# In-app Language Switcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** User đổi ngôn ngữ NGAY TRONG APP (Cài đặt → Ngôn ngữ: Theo hệ thống / Tiếng Việt / English), lựa chọn lưu bền qua restart.

**Architecture:** `LocaleController` (Riverpod `Notifier<Locale?>`, null = theo hệ thống) là nguồn sự thật; `MaterialApp.locale` watch nó — set xong toàn app rebuild sang ngôn ngữ mới tức thì, `localeResolutionCallback` sẵn có xử lý nhánh null. Persist bằng `shared_preferences` (key `locale_override`); main đọc pref TRƯỚC runApp và seed qua `initialLocaleProvider.overrideWithValue` để không nháy ngôn ngữ lúc mở app. UI = section mới trong SettingsScreen dùng `_Section` + ListTile check-mark sẵn có (né API Radio đang chuyển đổi).

**Tech Stack:** Riverpod 3 manual Notifier (pattern repo), shared_preferences, gen-l10n.

**Quy ước kế thừa từ đợt l10n-parity:** chuỗi UI mới → key ARB cả en+vi + fallback VI nguyên văn; tên ngôn ngữ ('Tiếng Việt', 'English') hiển thị bằng chính ngôn ngữ đó — KHÔNG l10n. Sau khi sửa arb PHẢI `flutter gen-l10n` trước analyze.

---

## Task 0: Worktree + dep

- [ ] Worktree `..\cung-hat-lang-wt` @ `feat/language-switcher` (đã tạo), plan này commit trong worktree.
- [ ] `pubspec.yaml` dependencies thêm `shared_preferences: ^2.3.0` → `flutter pub get`.
- [ ] Commit `chore: them shared_preferences cho locale override`.

## Task 1: LocaleController + persist

**Files:**
- Create: `lib/core/l10n/locale_controller.dart`
- Test: `test/core/locale_controller_test.dart`

- [ ] **Step 1: Test (fail trước):**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cung_hat/core/l10n/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mặc định theo initialLocaleProvider (null = hệ thống)', () {
    final c = ProviderContainer();
    expect(c.read(localeControllerProvider), isNull);
  });

  test('set(en) → state đổi + lưu prefs; set(null) → xoá pref', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    await c.read(localeControllerProvider.notifier).set(const Locale('en'));
    expect(c.read(localeControllerProvider), const Locale('en'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kLocaleOverridePrefKey), 'en');

    await c.read(localeControllerProvider.notifier).set(null);
    expect(c.read(localeControllerProvider), isNull);
    expect(prefs.getString(kLocaleOverridePrefKey), isNull);
  });

  test('loadSavedLocaleOverride đọc pref đã lưu', () async {
    SharedPreferences.setMockInitialValues({kLocaleOverridePrefKey: 'vi'});
    expect(await loadSavedLocaleOverride(), const Locale('vi'));
  });

  test('seed qua initialLocaleProvider', () {
    final c = ProviderContainer(overrides: [
      initialLocaleProvider.overrideWithValue(const Locale('en')),
    ]);
    expect(c.read(localeControllerProvider), const Locale('en'));
  });
}
```

- [ ] **Step 2:** Run FAIL (file chưa tồn tại).
- [ ] **Step 3: Implementation:**

```dart
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pref key cho locale override ('vi'/'en'); vắng = theo hệ thống.
const kLocaleOverridePrefKey = 'locale_override';

/// Đọc override đã lưu — gọi trong main() TRƯỚC runApp để seed
/// [initialLocaleProvider] (không nháy ngôn ngữ frame đầu). Best-effort:
/// prefs hỏng/thiếu plugin (unit test cũ) → null (theo hệ thống).
Future<Locale?> loadSavedLocaleOverride() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(kLocaleOverridePrefKey);
    return code == null ? null : Locale(code);
  } catch (e) {
    debugPrint('locale override load skipped: $e');
    return null;
  }
}

/// Giá trị seed từ main (override trong ProviderScope). null = hệ thống.
final initialLocaleProvider = Provider<Locale?>((_) => null);

/// Nguồn sự thật locale trong app: null = theo hệ thống (rơi vào
/// localeResolutionCallback của MaterialApp), khác null = user tự chọn.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => ref.watch(initialLocaleProvider);

  Future<void> set(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(kLocaleOverridePrefKey);
      } else {
        await prefs.setString(kLocaleOverridePrefKey, locale.languageCode);
      }
    } catch (e) {
      debugPrint('locale override save skipped: $e'); // state vẫn đổi cho phiên này
    }
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
```

- [ ] **Step 4:** Run PASS → commit `feat(l10n): LocaleController override + persist`.

## Task 2: Wire vào app

**Files:**
- Modify: `lib/app/app.dart` (thêm `locale:` watch controller)
- Modify: `lib/main.dart` (load pref + seed override)

- [ ] **Step 1: app.dart** — trong `MaterialApp.router`, NGAY TRÊN `localeResolutionCallback`:

```dart
      // [LANG] User chọn ngôn ngữ trong Cài đặt → override; null = theo máy.
      locale: ref.watch(localeControllerProvider),
```
import `../core/l10n/locale_controller.dart`. (CungHatApp là ConsumerStatefulWidget — build có ref.)

- [ ] **Step 2: main.dart** — sau `AppConfig.fromEnv()`:

```dart
  final savedLocale = await loadSavedLocaleOverride();
```
và thêm vào overrides của ProviderScope:
```dart
        initialLocaleProvider.overrideWithValue(savedLocale),
```
import `core/l10n/locale_controller.dart`.

- [ ] **Step 3:** `flutter analyze` 0 → commit `feat(l10n): ap locale override vao MaterialApp + seed tu prefs`.

## Task 3: UI Cài đặt + ARB

**Files:**
- Modify: `lib/l10n/app_vi.arb` + `app_en.arb` (2 key: `settingsLanguage` "Ngôn ngữ"/"Language", `settingsLangSystem` "Theo hệ thống"/"System default")
- Modify: `lib/features/settings/presentation/settings_screen.dart` (section Ngôn ngữ sau section Quyền riêng tư)
- Test: `test/features/settings/language_switch_test.dart`

- [ ] **Step 1: Widget test (fail trước):**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cung_hat/core/l10n/locale_controller.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import 'package:cung_hat/features/settings/presentation/settings_screen.dart';

class _MockSettingsRepo extends Mock implements SettingsRepository {}

void main() {
  testWidgets('chọn English trong Cài đặt → locale override = en + lưu pref',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _MockSettingsRepo();
    when(() => repo.myConsents()).thenAnswer((_) async => {});

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(home: SettingsScreen());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Theo hệ thống'), findsOneWidget);

    await tester.tap(find.byKey(const Key('lang_en')));
    await tester.pumpAndSettle();
    expect(container.read(localeControllerProvider), const Locale('en'));

    await tester.tap(find.byKey(const Key('lang_system')));
    await tester.pumpAndSettle();
    expect(container.read(localeControllerProvider), isNull);
  });
}
```

- [ ] **Step 2:** Run FAIL.
- [ ] **Step 3: settings_screen** — thêm sau section 'Quyền riêng tư' (trước 'Dữ liệu của tôi'):

```dart
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: _l10n?.settingsLanguage ?? 'Ngôn ngữ',
            child: Column(
              children: [
                _LanguageTile(
                  key: const Key('lang_system'),
                  label: _l10n?.settingsLangSystem ?? 'Theo hệ thống',
                  selected: ref.watch(localeControllerProvider) == null,
                  onTap: () =>
                      ref.read(localeControllerProvider.notifier).set(null),
                ),
                _LanguageTile(
                  key: const Key('lang_vi'),
                  label: 'Tiếng Việt', // tên ngôn ngữ giữ nguyên bản — không l10n
                  selected: ref.watch(localeControllerProvider) ==
                      const Locale('vi'),
                  onTap: () => ref
                      .read(localeControllerProvider.notifier)
                      .set(const Locale('vi')),
                ),
                _LanguageTile(
                  key: const Key('lang_en'),
                  label: 'English',
                  selected: ref.watch(localeControllerProvider) ==
                      const Locale('en'),
                  onTap: () => ref
                      .read(localeControllerProvider.notifier)
                      .set(const Locale('en')),
                ),
              ],
            ),
          ),
```

và widget cuối file (mirror `_SettingsTile` Material transparency):

```dart
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        title: Text(label),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: AppColors.primaryDark)
            : null,
        onTap: onTap,
      ),
    );
  }
}
```
import `../../../core/l10n/locale_controller.dart`.

- [ ] **Step 4:** gen-l10n + analyze + `flutter test test/features/settings/ test/core/ test/l10n/` PASS → commit `feat(settings): muc Ngon ngu doi VI/EN/he thong trong app`.

## Task 4: Gates + kết thúc

- [ ] `flutter analyze` 0 · `flutter test` full xanh (pgTAP không đổi — không đụng DB).
- [ ] finishing-a-development-branch: merge master --no-ff, tag `language-switcher`, xoá nhánh+worktree, push, watch CI 3 job, cập nhật memory.
