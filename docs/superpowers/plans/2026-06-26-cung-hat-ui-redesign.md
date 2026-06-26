# Cùng Hát UI Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace default Material theming with a centralized Coral / Be Vietnam Pro light design system and hand-polish the key screens (login/OTP, onboarding, Kèo board, nav).

**Architecture:** One `lib/core/theme/` package is the single source of truth; `app.dart` consumes `AppTheme.light`. Every screen inherits the new look via `ThemeData`; key screens get extra hand-polish using a few reusable widgets in `lib/shared/widgets/`. No business logic, schema, routes, or existing widget `Key`s change.

**Tech Stack:** Flutter 3.44 / Dart 3.12 · Material 3 · `google_fonts` (Be Vietnam Pro) · Riverpod (unchanged).

**Spec:** `docs/superpowers/specs/2026-06-26-cung-hat-ui-redesign-design.md`

---

## File structure

Create:
- `lib/core/theme/app_colors.dart` — color constants
- `lib/core/theme/app_spacing.dart` — radius/spacing constants
- `lib/core/theme/app_typography.dart` — Be Vietnam Pro TextTheme
- `lib/core/theme/app_theme.dart` — `AppTheme.light` ThemeData
- `lib/shared/widgets/app_logo.dart`
- `lib/shared/widgets/section_header.dart`
- `lib/shared/widgets/empty_state.dart`
- `lib/shared/widgets/otp_input.dart`
- `test/core/theme/app_theme_test.dart`
- `test/shared/widgets/widgets_test.dart`

Modify:
- `pubspec.yaml` — add `google_fonts`
- `lib/app/app.dart` — use `AppTheme.light`
- `lib/app/home_shell.dart` — nav icons/labels via theme
- `lib/features/keo/presentation/keo_card.dart` — redesigned card
- `lib/features/keo/presentation/keo_board_screen.dart` — header, banner, empty state
- `lib/features/auth/presentation/phone_screen.dart` — hero logo
- `lib/features/auth/presentation/otp_screen.dart` — OtpInput
- `lib/features/onboarding/presentation/onboarding_flow.dart` — step progress
- `lib/features/onboarding/presentation/taste_step.dart` — SectionHeader + chips

Keep these `Key`s untouched: `send_otp_btn`, `verify_otp_btn`, `pick_dob_btn`, `onb_name`, `onb_bio`, `onb_finish`, `consent_<purpose>`.

---

## Task 1: Add google_fonts dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add dependency**

In `pubspec.yaml` under `dependencies:` (after `app_links: ^7.2.0`):

```yaml
  google_fonts: ^6.2.1
```

- [ ] **Step 2: Fetch packages**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" pub get`
Expected: `Got dependencies!`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build: add google_fonts for Be Vietnam Pro"
```

---

## Task 2: Color tokens

**Files:**
- Create: `lib/core/theme/app_colors.dart`

- [ ] **Step 1: Write the file**

```dart
import 'package:flutter/material.dart';

/// Coral warm palette — single source of color truth (light mode).
abstract final class AppColors {
  static const primary = Color(0xFFE05732);
  static const primaryDark = Color(0xFFC2451F); // pressed state
  static const primaryTint = Color(0xFFFCE9E2); // selected fills, soft accents
  static const onPrimary = Color(0xFFFFFFFF);

  static const background = Color(0xFFFBF6F3); // warm off-white page bg
  static const surface = Color(0xFFFFFFFF); // cards, inputs

  static const textPrimary = Color(0xFF2A1D18);
  static const textSecondary = Color(0xFF7A6A63);
  static const textHint = Color(0xFFA89A93);
  static const border = Color(0xFFF0E6E0);

  static const success = Color(0xFF2E9E6B);
  static const warning = Color(0xFFE8A33D);
  static const error = Color(0xFFD64545);
}
```

- [ ] **Step 2: Verify it analyzes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/core/theme/app_colors.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat(theme): add color tokens"
```

---

## Task 3: Spacing & radius tokens

**Files:**
- Create: `lib/core/theme/app_spacing.dart`

- [ ] **Step 1: Write the file**

```dart
/// Spacing, radius and sizing tokens.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;

  static const radiusInput = 12.0;
  static const radiusButton = 14.0;
  static const radiusCard = 16.0;
  static const radiusSheet = 24.0;
  static const radiusPill = 999.0;

  static const buttonHeight = 52.0;
  static const inputHeight = 56.0;
  static const navHeight = 64.0;
}
```

- [ ] **Step 2: Verify it analyzes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/core/theme/app_spacing.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_spacing.dart
git commit -m "feat(theme): add spacing and radius tokens"
```

---

## Task 4: Typography (Be Vietnam Pro)

**Files:**
- Create: `lib/core/theme/app_typography.dart`

- [ ] **Step 1: Write the file**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Be Vietnam Pro text theme mapped onto Material text styles.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final t = GoogleFonts.beVietnamProTextTheme(base);
    return t.copyWith(
      headlineMedium: t.headlineMedium?.copyWith(
          fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleLarge: t.titleLarge?.copyWith(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleMedium: t.titleMedium?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: t.bodyLarge?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium: t.bodyMedium?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodySmall: t.bodySmall?.copyWith(
          fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge: t.labelLarge?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
```

- [ ] **Step 2: Verify it analyzes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/core/theme/app_typography.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_typography.dart
git commit -m "feat(theme): add Be Vietnam Pro typography"
```

---

## Task 5: ThemeData (AppTheme.light)

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Test: `test/core/theme/app_theme_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/core/theme/app_colors.dart';

void main() {
  test('AppTheme.light builds a Material 3 light theme with coral primary', () {
    final theme = AppTheme.light();
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/core/theme/app_theme_test.dart`
Expected: FAIL — `app_theme.dart` / `AppTheme` not found.

- [ ] **Step 3: Write the implementation**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primaryDark,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme = AppTypography.textTheme(base.textTheme);

    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: AppColors.primary, textStyle: textTheme.labelLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        enabledBorder: border(AppColors.border, 1),
        border: border(AppColors.border, 1),
        focusedBorder: border(AppColors.primary, 1.5),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w500),
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.navHeight,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryTint,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textHint,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textHint,
            )),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusInput)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/core/theme/app_theme_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_theme.dart test/core/theme/app_theme_test.dart
git commit -m "feat(theme): add AppTheme.light with component themes"
```

---

## Task 6: Wire theme into the app

**Files:**
- Modify: `lib/app/app.dart`

- [ ] **Step 1: Replace the theme line**

In `lib/app/app.dart`, add import near the top:

```dart
import '../core/theme/app_theme.dart';
```

Replace:

```dart
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6750A4), useMaterial3: true),
```

with:

```dart
      theme: AppTheme.light(),
```

- [ ] **Step 2: Analyze + run full test suite**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/app/app.dart`
Then: `& "C:\Users\Public\flutter\bin\flutter.bat" test`
Expected: `No issues found!` and all existing tests still PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/app/app.dart
git commit -m "feat(theme): apply AppTheme.light app-wide"
```

---

## Task 7: Reusable widgets

**Files:**
- Create: `lib/shared/widgets/app_logo.dart`, `section_header.dart`, `empty_state.dart`, `otp_input.dart`
- Test: `test/shared/widgets/widgets_test.dart`

- [ ] **Step 1: Write `app_logo.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Wordmark + round icon used on auth/landing screens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.tagline});
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
              color: AppColors.primaryTint, shape: BoxShape.circle),
          child: const Icon(Icons.mic_external_on, color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Cùng Hát',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary)),
        if (tagline != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(tagline!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Write `section_header.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Bold section label used in lists/forms (e.g. taste sections).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
```

- [ ] **Step 3: Write `empty_state.dart`**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Friendly empty/placeholder state: round icon + title + subtitle + optional CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.primaryTint, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle!,
                  style: text.bodySmall, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write `otp_input.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Six separate single-digit boxes backed by one hidden TextField.
/// Exposes the entered string via [onChanged]; fires [onCompleted] at 6 digits.
class OtpInput extends StatefulWidget {
  const OtpInput({super.key, this.length = 6, required this.onChanged, this.onCompleted});
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: widget.length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              setState(() {});
              widget.onChanged(v);
              if (v.length == widget.length) widget.onCompleted?.call(v);
            },
          ),
        ),
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) {
              final filled = i < _controller.text.length;
              return Container(
                width: 46,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                  border: Border.all(
                      color: filled ? AppColors.primary : AppColors.border,
                      width: filled ? 1.5 : 1),
                ),
                child: Text(filled ? _controller.text[i] : '',
                    style: Theme.of(context).textTheme.titleLarge),
              );
            }),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Write widget smoke tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/shared/widgets/app_logo.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
import 'package:cung_hat/shared/widgets/otp_input.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child));

void main() {
  testWidgets('AppLogo shows wordmark and tagline', (tester) async {
    await tester.pumpWidget(_wrap(const AppLogo(tagline: 'Kết bạn qua âm nhạc')));
    expect(find.text('Cùng Hát'), findsOneWidget);
    expect(find.text('Kết bạn qua âm nhạc'), findsOneWidget);
  });

  testWidgets('EmptyState shows CTA and fires callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(EmptyState(
      icon: Icons.groups,
      title: 'Chưa có kèo quanh đây',
      actionLabel: 'Tạo kèo',
      onAction: () => tapped = true,
    )));
    await tester.tap(find.text('Tạo kèo'));
    expect(tapped, isTrue);
  });

  testWidgets('OtpInput reports completion at full length', (tester) async {
    String? done;
    await tester.pumpWidget(_wrap(OtpInput(
      onChanged: (_) {},
      onCompleted: (v) => done = v,
    )));
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(done, '123456');
  });
}
```

- [ ] **Step 6: Run the widget tests**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/shared/widgets/widgets_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/shared/widgets test/shared/widgets/widgets_test.dart
git commit -m "feat(ui): add AppLogo, SectionHeader, EmptyState, OtpInput"
```

---

## Task 8: Redesign KeoCard

**Files:**
- Modify: `lib/features/keo/presentation/keo_card.dart`

- [ ] **Step 1: Replace the file**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/keo.dart';

class KeoCard extends StatelessWidget {
  const KeoCard({super.key, required this.keo, this.onTap});
  final Keo keo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(keo.title, style: text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  if (keo.distanceBand != null)
                    _meta(context, Icons.place_outlined, 'cách ${keo.distanceBand} km'),
                  _meta(context, Icons.groups_outlined,
                      '${keo.slotsFilled}/${keo.sizeTarget} người'),
                  if (keo.hostName != null)
                    _meta(context, Icons.person_outline, keo.hostName!),
                ],
              ),
              if (keo.genres.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [for (final g in keo.genres) _genreChip(g)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );

  Widget _genreChip(String g) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
        child: Text(g,
            style: const TextStyle(
                fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
      );
}
```

- [ ] **Step 2: Add a render test**

Create `test/features/keo/keo_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/presentation/keo_card.dart';

void main() {
  testWidgets('KeoCard renders title, meta and genres', (tester) async {
    const keo = Keo(
      id: '1', title: 'Hát K-Pop cuối tuần', distanceBand: '<1',
      sizeTarget: 4, slotsFilled: 1, genres: ['K-Pop'], hostName: 'Minh',
    );
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: KeoCard(keo: keo)),
    ));
    expect(find.text('Hát K-Pop cuối tuần'), findsOneWidget);
    expect(find.text('1/4 người'), findsOneWidget);
    expect(find.text('K-Pop'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/keo_card_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/keo/presentation/keo_card.dart test/features/keo/keo_card_test.dart
git commit -m "feat(keo): redesign KeoCard with icons and genre chips"
```

---

## Task 9: Polish Kèo board screen

**Files:**
- Modify: `lib/features/keo/presentation/keo_board_screen.dart`

- [ ] **Step 1: Replace the file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/keo_providers.dart';
import 'keo_card.dart';

class KeoBoardScreen extends ConsumerWidget {
  const KeoBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keosAsync = ref.watch(openKeosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kèo quanh bạn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/keo/create'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo kèo'),
      ),
      body: keosAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => const EmptyState(
          icon: Icons.wifi_off,
          title: 'Không tải được danh sách kèo',
          subtitle: 'Kiểm tra kết nối rồi thử lại.',
        ),
        data: (keos) {
          if (keos.isEmpty) {
            return EmptyState(
              icon: Icons.groups,
              title: 'Chưa có kèo quanh đây',
              subtitle: 'Hãy là người đầu tiên rủ mọi người đi hát.',
              actionLabel: 'Tạo kèo đầu tiên',
              onAction: () => context.push('/keo/create'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96, top: AppSpacing.sm),
            itemCount: keos.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _matchBanner(context, ref);
              final k = keos[index - 1];
              return KeoCard(
                keo: k,
                onTap: () => context.push(
                    '/keo/${k.id}?title=${Uri.encodeComponent(k.title)}'),
              );
            },
          );
        },
      ),
    );
  }

  Widget _matchBanner(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
        child: Material(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            onTap: () => ref.invalidate(openKeosProvider),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ghép nhóm cho tôi',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('Tự động gợi ý kèo phù hợp (sắp có)',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
```

- [ ] **Step 2: Analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/features/keo/presentation/keo_board_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/keo/presentation/keo_board_screen.dart
git commit -m "feat(keo): polish board with header, match banner, empty state"
```

---

## Task 10: Polish nav shell

**Files:**
- Modify: `lib/app/home_shell.dart`

- [ ] **Step 1: Update icon constants and destinations**

Replace the `_icons` line:

```dart
  static const _icons = [Icons.favorite, Icons.groups, Icons.chat_bubble, Icons.person];
```

with selected/unselected pairs:

```dart
  static const _icons = [
    Icons.favorite_border, Icons.groups_outlined,
    Icons.chat_bubble_outline, Icons.person_outline,
  ];
  static const _iconsSel = [
    Icons.favorite, Icons.groups, Icons.chat_bubble, Icons.person,
  ];
```

Then replace the `destinations:` builder block:

```dart
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_iconsSel[i]),
              label: _labels[i],
            ),
        ],
```

- [ ] **Step 2: Analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/app/home_shell.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/app/home_shell.dart
git commit -m "feat(nav): outlined/filled icon pairs in bottom nav"
```

---

## Task 11: Polish login (phone) screen

**Files:**
- Modify: `lib/features/auth/presentation/phone_screen.dart`

- [ ] **Step 1: Replace the build body**

Add import:

```dart
import '../../../shared/widgets/app_logo.dart';
```

Replace the `Column` (the one with `mainAxisAlignment: MainAxisAlignment.center`) so the hero sits above the field. Keep the `send_otp_btn` Key and `sendOtp` call exactly. New body:

```dart
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const AppLogo(tagline: 'Kết bạn qua những bài hát'),
              const SizedBox(height: 48),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixText: '+84 ',
                  labelText: l10n?.phoneLabel ?? 'Số điện thoại',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('send_otp_btn'),
                onPressed: state.phase == AuthPhase.sending
                    ? null
                    : () => ref.read(authControllerProvider.notifier)
                        .sendOtp(_normalize(_ctrl.text)),
                child: Text(l10n?.sendOtp ?? 'Gửi mã OTP'),
              ),
              if (state.phase == AuthPhase.error)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(state.error ?? 'Lỗi',
                      style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
```

Note: keep the existing `ref.listen(authControllerProvider, ...)` (the `/otp` navigation fix) above the `return Scaffold(`.

- [ ] **Step 2: Analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/features/auth/presentation/phone_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/phone_screen.dart
git commit -m "feat(auth): hero logo + scrollable login layout"
```

---

## Task 12: Polish OTP screen

**Files:**
- Modify: `lib/features/auth/presentation/otp_screen.dart`

- [ ] **Step 1: Use OtpInput**

Add import:

```dart
import '../../../shared/widgets/otp_input.dart';
```

Replace the plain `TextField` (the OTP `_ctrl` field) with `OtpInput` writing into `_ctrl`. Keep `verify_otp_btn` Key and `verifyOtp(_ctrl.text)`. The body becomes:

```dart
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Mã đã gửi tới ${state.phone ?? ''}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OtpInput(
              onChanged: (v) => _ctrl.text = v,
              onCompleted: (v) {
                _ctrl.text = v;
                ref.read(authControllerProvider.notifier).verifyOtp(v);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('verify_otp_btn'),
              onPressed: state.phase == AuthPhase.verifying
                  ? null
                  : () => ref.read(authControllerProvider.notifier).verifyOtp(_ctrl.text),
              child: Text(l10n?.verify ?? 'Xác nhận'),
            ),
            if (state.phase == AuthPhase.error)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(state.error ?? 'Lỗi', style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
```

- [ ] **Step 2: Analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/features/auth/presentation/otp_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/otp_screen.dart
git commit -m "feat(auth): 6-box OTP input"
```

---

## Task 13: Polish onboarding (progress + taste)

**Files:**
- Modify: `lib/features/onboarding/presentation/onboarding_flow.dart`
- Modify: `lib/features/onboarding/presentation/taste_step.dart`

- [ ] **Step 1: Add a step-progress line to the AppBar**

In `onboarding_flow.dart`, replace the `appBar:` line:

```dart
      appBar: AppBar(
          title: Text(l10n?.onbSetupTitle ?? 'Thiết lập hồ sơ')),
```

with:

```dart
      appBar: AppBar(
        title: Text(l10n?.onbSetupTitle ?? 'Thiết lập hồ sơ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Bước ${_step + 1}/4',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ),
      ),
```

- [ ] **Step 2: Add SectionHeader to taste sections**

In `taste_step.dart` (the `TasteChips` widget that renders chips), ensure each section uses the shared `SectionHeader`. If section labels are rendered in `onboarding_flow.dart`'s `_tasteSection` via a bold `Text`, replace that `Text(label, style: const TextStyle(fontWeight: FontWeight.bold))` with:

```dart
        SectionHeader(label),
```

and add import in that file:

```dart
import '../../../shared/widgets/section_header.dart';
```

- [ ] **Step 3: Analyze + run full suite**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze`
Then: `& "C:\Users\Public\flutter\bin\flutter.bat" test`
Expected: `No issues found!` and all tests PASS (including the unchanged onboarding/router tests — the `Key`s are intact).

- [ ] **Step 4: Commit**

```bash
git add lib/features/onboarding/presentation/onboarding_flow.dart lib/features/onboarding/presentation/taste_step.dart
git commit -m "feat(onboarding): step progress label + SectionHeader for taste"
```

---

## Task 14: Full verification (analyze, test, emulator)

**Files:** none (verification only)

- [ ] **Step 1: Static checks**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze`
Expected: `No issues found!`
Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test`
Expected: all tests PASS.

- [ ] **Step 2: Build the APK (cloud — local Gradle is blocked by the Winsock/AF_UNIX defect)**

Push the `feat/ui-redesign` branch and trigger the existing workflow:

```bash
GH_TOKEN=<token> "C:\Program Files\GitHub CLI\gh.exe" workflow run build-apk.yml --ref feat/ui-redesign
```

Wait for success, then download `app-debug-apk` (see the APK-blocker memory for the exact `gh run download` recipe).

- [ ] **Step 3: Install on the emulator and screenshot each key screen**

Start AVD `cunghat_test` headless, `adb uninstall dev.cunghat.cung_hat` then `adb install -t <apk>`, drive via `adb shell input` and capture with `adb exec-out screencap -p > x.png` (use the Bash tool — PowerShell `>` corrupts the PNG). Capture: login, OTP, onboarding (each step), Kèo board with seeded keo. Compare against the pre-redesign screenshots in `Desktop\cung-hat-test-screenshots\`.

Expected: coral palette, Be Vietnam Pro, new KeoCard/empty-state visible; login → OTP → onboarding → home → Kèo board flow still works end-to-end.

- [ ] **Step 4: Final commit / open PR**

```bash
GH_TOKEN=<token> "C:\Program Files\GitHub CLI\gh.exe" pr create --base master --head feat/ui-redesign --title "UI redesign: Coral / Be Vietnam Pro" --body "Centralized light theme + key-screen polish. Verified on emulator."
```

(Merge only with the user's go-ahead.)

---

## Self-review notes

- Spec coverage: tokens (T2-4), components (T5), app wiring (T6), reusable widgets (T7), KeoCard (T8), board (T9), nav (T10), login (T11), OTP (T12), onboarding (T13), verification (T14). google_fonts dep (T1). All spec sections covered.
- Keys preserved: `send_otp_btn` (T11), `verify_otp_btn` (T12), `onb_*`/`consent_*`/`pick_dob_btn` untouched (T13 only adds a progress label + swaps a section label widget).
- Non-goals respected: no dark mode, no logic/schema/route changes.
