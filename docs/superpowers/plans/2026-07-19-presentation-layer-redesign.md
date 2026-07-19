# Cùng Hát Presentation Layer Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Viết lại presentation layer của Cùng Hát theo 22 mockup đã duyệt mà không thay đổi backend, route, provider contract hoặc business logic.

**Architecture:** Giữ screen cấp cao làm lớp wiring cho provider và callback hiện có, tách các khối trình bày lớn thành feature section, rồi dựng tất cả trên một shared UI system duy nhất. `ResponsiveFrame` chuẩn hóa SafeArea, keyboard inset và bề rộng mobile-web; từng task thay đổi UI theo TDD và giữ nguyên các hành vi đã được 437 baseline test bảo vệ.

**Tech Stack:** Flutter 3.x, Dart `^3.12.1`, Material 3, Riverpod 3, GoRouter 17, `flutter_test`, Android emulator `emulator-5554`, Chrome mobile web.

## Global Constraints

- Chỉ light mode trong đợt này.
- Viewport bắt buộc: 360dp, 393dp và 430dp; text scale: 1.0, 1.2 và 1.4.
- Android được kiểm tra trên emulator thật; mobile web được kiểm tra trên Chrome.
- iOS được kiểm tra bằng widget test với `TargetPlatform.iOS`; Windows không được dùng để tuyên bố đã build hoặc chạy iOS Simulator.
- Không thêm dependency mới.
- Giữ nguyên route declaration, redirect, provider contract, model, API, analytics, feature flag, entitlement và business logic.
- Không sửa `supabase/**`, `lib/features/**/data/**`, `lib/features/**/domain/**`, `lib/features/**/application/**`, `lib/app/router.dart`, `lib/core/providers/**` hoặc `lib/core/analytics/**`.
- Nếu mockup cần dữ liệu chưa có, bỏ chi tiết đó hoặc ánh xạ sang dữ liệu hiện có; không mở rộng backend.
- Palette bắt buộc: background `#F7EFD8`, surface `#FCF6E3`, ink `#1E3A2F`, primary `#E8501F`, lime `#C6E534`, teal `#8FD8C8`.
- Card/input/button/sheet dùng viền ink 2px, radius 14px; hard shadow offset 3×3px, blur 0, màu `#331E3A2F`.
- Heading dùng Oswald; body/control dùng Be Vietnam Pro; body tối thiểu 13px.
- CTA chính dùng nhãn trắng `19px / 700 / 1.05` trên primary; text thường đạt tương phản tối thiểu 4.5:1, large bold tối thiểu 3:1.
- Touch target tối thiểu 44×44px; mọi swipe có action button tương đương.
- Motion dùng 150/220/300/140ms và tôn trọng `MediaQuery.disableAnimations`.
- Giữ nguyên các `Key`, semantic label và callback hiện có; chỉ thêm key `screen_XX_*` làm mỏ neo kiểm thử/chụp ảnh.
- Người dùng chỉ được yêu cầu duyệt sau khi đủ cả 22 màn hình và hoàn tất kiểm tra cuối.
- Mốc boundary audit là commit `e3f1f389`.

## Screen Coverage Map

| Mockup | Root key | Task |
|---|---|---:|
| 01 Login | `screen_01_login` | 4 |
| 02 OTP | `screen_02_otp` | 4 |
| 03 DOB | `screen_03_onboarding_dob` | 5 |
| 04 Consent | `screen_04_onboarding_consent` | 5 |
| 05 Profile setup | `screen_05_onboarding_profile` | 6 |
| 06 Music taste | `screen_06_onboarding_music_taste` | 6 |
| 07 Đôi deck | `screen_07_doi_deck` | 7 |
| 08 Profile detail | `screen_08_doi_profile_detail` | 7 |
| 09 Match celebration | `screen_09_match_celebration` | 8 |
| 10 Explore themes | `screen_10_explore_themes` | 8 |
| 11 Kèo board | `screen_11_keo_board` | 9 |
| 12 Kèo auto-match | `screen_12_keo_auto_match` | 9 |
| 13 Create Kèo | `screen_13_create_keo` | 10 |
| 14 Kèo detail | `screen_14_keo_detail` | 10 |
| 15 Inbox | `screen_15_inbox` | 11 |
| 16 Chat 1-to-1 | `screen_16_chat_1to1` | 12 |
| 17 Kèo group chat | `screen_17_keo_group_chat` | 12 |
| 18 Profile | `screen_18_profile` | 3 |
| 19 Plan/map | `screen_19_plan` | 13 |
| 20 Booking/payment | `screen_20_booking_payment` | 13 |
| 21 Store | `screen_21_store` | 14 |
| 22 Settings | `screen_22_settings` | 15 |

---

### Task 1: Responsive presentation frame

**Files:**
- Create: `lib/shared/widgets/responsive_frame.dart`
- Create: `test/shared/widgets/responsive_frame_test.dart`

**Interfaces:**
- Consumes: `MediaQuery.viewInsets`, `MediaQuery.disableAnimations`, `SafeArea`.
- Produces: `ResponsiveFrame({required Widget child, double maxWidth = 430, EdgeInsetsGeometry padding = EdgeInsets.zero, bool avoidKeyboard = true})`.

- [ ] **Step 1: Write the failing responsive-frame tests**

```dart
import 'package:cung_hat/shared/widgets/responsive_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('centers a 430dp mobile surface on a wide viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveFrame(
          child: ColoredBox(
            key: Key('content'),
            color: Colors.orange,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('content'))).width, 430);
    expect(tester.getCenter(find.byKey(const Key('content'))).dx, 450);
  });

  testWidgets('uses the full width on a 360dp viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveFrame(child: SizedBox.expand(key: Key('content'))),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('content'))).width, 360);
  });

  testWidgets('animates the keyboard inset only when avoidance is enabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: 240)),
          child: ResponsiveFrame(
            child: SizedBox(key: Key('content'), height: 100),
          ),
        ),
      ),
    );
    final padding = tester.widget<AnimatedPadding>(find.byType(AnimatedPadding));
    expect(padding.padding, const EdgeInsets.only(bottom: 240));
  });
}
```

- [ ] **Step 2: Run the tests and verify the missing-type failure**

Run: `flutter test test/shared/widgets/responsive_frame_test.dart`

Expected: FAIL because `responsive_frame.dart` and `ResponsiveFrame` do not exist.

- [ ] **Step 3: Implement `ResponsiveFrame`**

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({
    super.key,
    required this.child,
    this.maxWidth = 430,
    this.padding = EdgeInsets.zero,
    this.avoidKeyboard = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool avoidKeyboard;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = avoidKeyboard ? media.viewInsets.bottom : 0.0;
    final duration = media.disableAnimations ? Duration.zero : AppMotion.base;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: AnimatedPadding(
              duration: duration,
              curve: AppMotion.enterCurve,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the focused tests**

Run: `flutter test test/shared/widgets/responsive_frame_test.dart`

Expected: PASS, 3 tests.

- [ ] **Step 5: Commit**

```powershell
git add lib/shared/widgets/responsive_frame.dart test/shared/widgets/responsive_frame_test.dart
git commit -m "feat: add responsive presentation frame"
```

### Task 2: Shared retro UI system and component states

**Files:**
- Modify: `lib/core/theme/app_theme.dart`
- Modify: `lib/shared/widgets/gradient_button.dart`
- Modify: `lib/shared/widgets/empty_state.dart`
- Modify: `lib/shared/widgets/otp_input.dart`
- Modify: `lib/shared/widgets/pressable.dart`
- Modify: `lib/shared/widgets/hard_card.dart`
- Modify: `lib/shared/widgets/tab_header.dart`
- Modify: `lib/shared/widgets/skeleton.dart`
- Modify: `test/core/theme/app_theme_test.dart`
- Modify: `test/shared/widgets/widgets_test.dart`
- Create: `test/shared/widgets/component_states_test.dart`

**Interfaces:**
- Consumes: tokens from `AppColors`, `AppSpacing`, `AppShadows`, `AppMotion`.
- Produces: unchanged public constructors for all existing shared widgets.

- [ ] **Step 1: Add failing tests for visual states**

```dart
import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_shadows.dart';
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:cung_hat/shared/widgets/empty_state.dart';
import 'package:cung_hat/shared/widgets/gradient_button.dart';
import 'package:cung_hat/shared/widgets/otp_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) =>
      MaterialApp(theme: AppTheme.light(), home: Scaffold(body: Center(child: child)));

  testWidgets('primary CTA keeps a 2px border and hard shadow', (tester) async {
    await tester.pumpWidget(host(GradientButton(onPressed: () {}, child: const Text('Tiếp tục'))));
    final decorated = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(GradientButton), matching: find.byType(DecoratedBox)).first,
    );
    final box = decorated.decoration as BoxDecoration;
    expect((box.border! as Border).top.width, 2);
    expect(box.boxShadow, const <BoxShadow>[AppShadows.hard]);
  });

  testWidgets('empty state uses a hard-surface icon without blur', (tester) async {
    await tester.pumpWidget(host(const EmptyState(icon: Icons.wifi_off, title: 'Mất kết nối')));
    final boxes = tester.widgetList<Container>(
      find.descendant(of: find.byType(EmptyState), matching: find.byType(Container)),
    );
    final decorations = boxes.map((box) => box.decoration).whereType<BoxDecoration>();
    expect(decorations.any((box) => box.boxShadow?.contains(AppShadows.hard) ?? false), isTrue);
    expect(
      decorations.expand((box) => box.boxShadow ?? const <BoxShadow>[]).any((shadow) => shadow.blurRadius > 0),
      isFalse,
    );
  });

  testWidgets('OTP cells use the shared 2px ink border', (tester) async {
    await tester.pumpWidget(host(OtpInput(onChanged: (_) {})));
    final cells = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
    for (final cell in cells) {
      final box = cell.decoration! as BoxDecoration;
      expect((box.border! as Border).top.width, 2);
      expect((box.border! as Border).top.color, anyOf(AppColors.ink, AppColors.primary));
    }
  });
}
```

- [ ] **Step 2: Run the state tests and confirm current style failures**

Run: `flutter test test/shared/widgets/component_states_test.dart`

Expected: FAIL for the blurred `EmptyState` treatment and 1/1.5px OTP borders.

- [ ] **Step 3: Normalize shared internals without changing public APIs**

Apply these exact state rules:

```dart
final hardSurface = BoxDecoration(
  color: AppColors.surface,
  border: Border.all(color: AppColors.ink, width: 2),
  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
  boxShadow: const <BoxShadow>[AppShadows.hard],
);

final otpBorder = Border.all(
  color: isFilled || isActive ? AppColors.primary : AppColors.ink,
  width: 2,
);

final pressDuration = MediaQuery.maybeOf(context)?.disableAnimations == true
    ? Duration.zero
    : AppMotion.fast;
```

Use `hardSurface` geometry for `EmptyState` icon framing, remove all blurred shadows and decorative gradients from empty/loading/error states, use `otpBorder` in `_DigitBox`, and feed `pressDuration` to `Pressable`'s `AnimatedScale`. Keep `GradientButton`, `HardCard`, `TabHeader`, `Skeleton`, `SkeletonTile` and `SkeletonCard` constructor signatures unchanged.

- [ ] **Step 4: Run shared and theme tests**

Run: `flutter test test/core/theme test/shared`

Expected: PASS with no changed public API failures.

- [ ] **Step 5: Commit**

```powershell
git add lib/core/theme/app_theme.dart lib/shared/widgets test/core/theme test/shared
git commit -m "feat: normalize retro component states"
```

### Task 3: Home shell and profile screen

**Files:**
- Create: `lib/features/profile/presentation/profile_screen.dart`
- Modify: `lib/app/home_shell.dart`
- Create: `test/features/profile/profile_screen_test.dart`
- Modify: `test/app/home_shell_test.dart`
- Modify: `test/app/responsive_smoke_test.dart`

**Interfaces:**
- Consumes: `myProfileProvider`, `myTasteCountsProvider`, `hasEntitlementProvider('see_likes')`.
- Produces: `ProfileScreen({Key? key})`; `HomeShell` keeps the same four tab indices and lazy `IndexedStack` behavior.

- [ ] **Step 1: Add failing tests for screen 18 and shell geometry**

```dart
testWidgets('profile screen exposes the mockup-18 hierarchy', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myProfileProvider.overrideWith((ref) async => const Profile(id: 'u1', displayName: 'Minh')),
        myTasteCountsProvider.overrideWith((ref) async => const TasteCounts(0, 0, 0)),
        entitlementsProvider.overrideWith((ref) async => <String>{}),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const ProfileScreen()),
    ),
  );
  await tester.pump();
  expect(find.byKey(const Key('screen_18_profile')), findsOneWidget);
  expect(find.byKey(const Key('profile_identity_card')), findsOneWidget);
  expect(find.byKey(const Key('completion_card')), findsOneWidget);
  expect(find.widgetWithText(StampChip, 'PRO'), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run profile and shell tests**

Run: `flutter test test/features/profile/profile_screen_test.dart test/app/home_shell_test.dart`

Expected: FAIL because `ProfileScreen` and the new presentation keys do not exist.

- [ ] **Step 3: Extract and redesign the profile presentation**

Move `_ProfileTab`, `_CompletionCard` and `_ProfileTile` from `home_shell.dart` into `profile_screen.dart`. Rename the public root to:

```dart
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveFrame(
      child: KeyedSubtree(
        key: const Key('screen_18_profile'),
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              TabHeader(title: Localizations.of<AppLocalizations>(context, AppLocalizations)?.tabProfile ?? 'Hồ sơ'),
              const Expanded(child: _ProfileContent()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final taste = ref.watch(myTasteCountsProvider).value;
    return _ProfileList(profile: profile, taste: taste);
  }
}
```

Define `_ProfileList` in the same file with required `Profile? profile` and
`TasteCounts? taste` constructor arguments. It must place the
avatar/name/bio in `HardCard(key: Key('profile_identity_card'))`, preserve
the existing completion calculation and routes, and render tiles in this
order: likes, upgrade, photos, prompts, settings. Replace the fourth tab
factory with `() => const ProfileScreen()`; do not alter `_select`,
`_visited`, tab indices or inbox invalidation.

- [ ] **Step 4: Run shell, profile and responsive tests**

Run: `flutter test test/features/profile test/app/home_shell_test.dart test/app/responsive_smoke_test.dart`

Expected: PASS, including lazy tab initialization and state retention.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/home_shell.dart lib/features/profile/presentation/profile_screen.dart test/app test/features/profile
git commit -m "feat: redesign shell profile presentation"
```

### Task 4: Login and OTP screens

**Files:**
- Modify: `lib/features/auth/presentation/phone_screen.dart`
- Modify: `lib/features/auth/presentation/otp_screen.dart`
- Modify: `lib/shared/widgets/app_logo.dart`
- Modify: `test/features/auth/phone_screen_test.dart`
- Modify: `test/features/auth/otp_screen_test.dart`

**Interfaces:**
- Consumes: unchanged `authControllerProvider`, `sendOtp`, `verifyOtp`, resend timer and `/otp` navigation.
- Produces: root keys `screen_01_login` and `screen_02_otp`; existing `send_otp_btn`, `verify_otp_btn`, `resend_otp_btn` remain.

- [ ] **Step 1: Add failing hierarchy and compact-keyboard tests**

```dart
expect(find.byKey(const Key('screen_01_login')), findsOneWidget);
expect(find.byKey(const Key('login_music_box_hero')), findsOneWidget);
expect(find.byKey(const Key('phone_input_frame')), findsOneWidget);
expect(find.byKey(const Key('send_otp_btn')), findsOneWidget);

expect(find.byKey(const Key('screen_02_otp')), findsOneWidget);
expect(find.byKey(const Key('otp_brand_header')), findsOneWidget);
expect(find.byKey(const Key('otp_ticket_hero')), findsOneWidget);
expect(find.byKey(const Key('verify_otp_btn')), findsOneWidget);
```

Add a 360×640 test with a 260px bottom `viewInsets` for each screen and assert the primary CTA is hit-testable after scrolling.

- [ ] **Step 2: Run auth presentation tests**

Run: `flutter test test/features/auth/phone_screen_test.dart test/features/auth/otp_screen_test.dart`

Expected: FAIL only for the new screen keys/layout expectations.

- [ ] **Step 3: Wrap the two screens in the responsive presentation contract**

Add this complete helper to each screen state and pass its existing content
column as `child`:

```dart
Widget _presentationFrame({
  required Key screenKey,
  required Widget child,
}) {
  return ResponsiveFrame(
    maxWidth: 430,
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      child: KeyedSubtree(key: screenKey, child: child),
    ),
  );
}
```

Call it with `const Key('screen_01_login')` in `PhoneScreen` and
`const Key('screen_02_otp')` in `OtpScreen`. Keep `_normalize`, `_sendOtp`,
`_submit`, `_resendOtp`, `_submitted`, `_resendInFlight` and all
controller/listener behavior byte-for-byte equivalent. Match mockups 01–02
with one hero, one clear form surface, one primary CTA and no decorative
element that competes with the form.

- [ ] **Step 4: Run auth behavior and integration anchor tests**

Run: `flutter test test/features/auth`

Expected: all auth unit/widget tests PASS; the unchanged integration anchors
`send_otp_btn` and `verify_otp_btn` remain present.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/auth/presentation lib/shared/widgets/app_logo.dart test/features/auth
git commit -m "feat: redesign login and otp screens"
```

### Task 5: Onboarding DOB and consent

**Files:**
- Modify: `lib/features/onboarding/presentation/onboarding_flow.dart`
- Modify: `lib/features/onboarding/presentation/dob_step.dart`
- Modify: `lib/features/onboarding/presentation/consent_step.dart`
- Modify: `test/features/onboarding/onboarding_flow_test.dart`
- Modify: `test/features/onboarding/dob_step_test.dart`
- Modify: `test/features/onboarding/consent_step_test.dart`

**Interfaces:**
- Consumes: `DobStep(dob, onPick)`, `ConsentStep(values, onChanged)` and existing consent helpers.
- Produces: step-root keys `screen_03_onboarding_dob`, `screen_04_onboarding_consent`.

- [ ] **Step 1: Add failing step-root and accessibility tests**

```dart
expect(find.byKey(const Key('screen_03_onboarding_dob')), findsOneWidget);
expect(find.byKey(const Key('pick_dob_btn')), findsOneWidget);
expect(find.byKey(const Key('dob_day')), findsOneWidget);
expect(find.byKey(const Key('dob_month')), findsOneWidget);
expect(find.byKey(const Key('dob_year')), findsOneWidget);

await tester.tap(find.byKey(const Key('onb_continue')));
await tester.pump();
expect(find.byKey(const Key('screen_04_onboarding_consent')), findsOneWidget);
expect(find.byKey(const Key('consent_all_btn')), findsOneWidget);
expect(find.text('Bắt buộc'), findsNWidgets(4));
```

At 360dp and text scale 1.4, assert no overflow and `onb_continue` remains hit-testable.

- [ ] **Step 2: Run the three onboarding test files**

Run: `flutter test test/features/onboarding/onboarding_flow_test.dart test/features/onboarding/dob_step_test.dart test/features/onboarding/consent_step_test.dart`

Expected: FAIL for the new root keys.

- [ ] **Step 3: Apply the mockup-03/04 hierarchy**

In `_currentStep`, wrap the existing widgets:

```dart
0 => KeyedSubtree(
  key: const Key('screen_03_onboarding_dob'),
  child: DobStep(dob: _dob, onPick: (date) => setState(() => _dob = date)),
),
1 => KeyedSubtree(
  key: const Key('screen_04_onboarding_consent'),
  child: ConsentStep(
    values: _consents,
    onChanged: (key, value) => setState(() => _consents[key] = value),
  ),
),
```

Use a single `HardCard` for DOB art plus the three date cells and a single calm consent list with required badges. Preserve the exact age gate, consent order, mandatory set, optional marketing switch, legal routes and `consent_all_btn` behavior.

- [ ] **Step 4: Run onboarding tests**

Run: `flutter test test/features/onboarding`

Expected: PASS with age/consent logic unchanged.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/onboarding/presentation/onboarding_flow.dart lib/features/onboarding/presentation/dob_step.dart lib/features/onboarding/presentation/consent_step.dart test/features/onboarding
git commit -m "feat: redesign onboarding age and consent steps"
```

### Task 6: Onboarding profile and music taste

**Files:**
- Create: `lib/features/onboarding/presentation/profile_step.dart`
- Modify: `lib/features/onboarding/presentation/onboarding_flow.dart`
- Modify: `lib/features/onboarding/presentation/taste_step.dart`
- Modify: `test/features/onboarding/onboarding_flow_test.dart`
- Modify: `test/features/onboarding/taste_step_test.dart`

**Interfaces:**
- Consumes: current `_nameCtrl`, `_bioCtrl`, genre/artist/song providers and selection sets.
- Produces: `ProfileStep({required TextEditingController nameController, required TextEditingController bioController, required String brand})`; root keys `screen_05_onboarding_profile`, `screen_06_onboarding_music_taste`.

- [ ] **Step 1: Add failing profile/taste hierarchy tests**

```dart
expect(find.byKey(const Key('screen_05_onboarding_profile')), findsOneWidget);
expect(find.byKey(const Key('onb_profile_preview')), findsOneWidget);
expect(find.byKey(const Key('onb_name')), findsOneWidget);
expect(find.byKey(const Key('onb_bio')), findsOneWidget);

expect(find.byKey(const Key('screen_06_onboarding_music_taste')), findsOneWidget);
expect(find.byKey(const Key('onb_finish')), findsOneWidget);
expect(find.byKey(const Key('taste_genres_section')), findsOneWidget);
expect(find.byKey(const Key('taste_artists_section')), findsOneWidget);
expect(find.byKey(const Key('taste_songs_section')), findsOneWidget);
```

- [ ] **Step 2: Run profile/taste tests**

Run: `flutter test test/features/onboarding/onboarding_flow_test.dart test/features/onboarding/taste_step_test.dart`

Expected: FAIL for `ProfileStep` and the new section keys.

- [ ] **Step 3: Extract profile presentation and style selectable stamps**

Create `ProfileStep` with the public constructor above and move the existing preview/name/bio presentation into it. The flow keeps ownership of controllers and renders:

```dart
2 => ProfileStep(
  key: const Key('screen_05_onboarding_profile'),
  nameController: _nameCtrl,
  bioController: _bioCtrl,
  brand: l10n?.appTitle ?? 'Cùng Hát',
),
```

Wrap the taste column in `KeyedSubtree(key: Key('screen_06_onboarding_music_taste'))`; add the three section keys at `_tasteSection` call sites. Keep `TasteChips<T>` controlled, retain every `chip_<id>` key, and use lime for selected stamps, surface for unselected stamps, 2px ink borders and 44px minimum height.

- [ ] **Step 4: Run all onboarding tests**

Run: `flutter test test/features/onboarding`

Expected: PASS, including preserved field values, analytics and submit behavior.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/onboarding/presentation test/features/onboarding
git commit -m "feat: redesign onboarding profile and music taste"
```

### Task 7: Đôi deck and candidate detail

**Files:**
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart`
- Modify: `lib/features/discovery/presentation/candidate_card.dart`
- Modify: `lib/features/discovery/presentation/candidate_detail_sheet.dart`
- Modify: `lib/features/discovery/presentation/deck_action_bar.dart`
- Modify: `lib/features/discovery/presentation/swipe_overlays.dart`
- Modify: `lib/features/discovery/presentation/filter_sheet.dart`
- Modify: `test/features/discovery/doi_deck_screen_test.dart`
- Modify: `test/features/discovery/candidate_card_test.dart`
- Modify: `test/features/discovery/candidate_detail_sheet_test.dart`
- Modify: `test/features/discovery/deck_action_bar_test.dart`

**Interfaces:**
- Consumes: all current discovery providers, `CardSwiperController`, swipe directions and callbacks.
- Produces: root keys `screen_07_doi_deck`, `screen_08_doi_profile_detail`; existing action/filter/detail keys remain.

- [ ] **Step 1: Add failing screen-root and decision-hierarchy tests**

```dart
expect(find.byKey(const Key('screen_07_doi_deck')), findsOneWidget);
expect(find.byKey(const Key('card_photo_area')), findsOneWidget);
expect(find.byKey(const Key('card_detail_btn')), findsOneWidget);
expect(find.byKey(const Key('deck_pass_btn')), findsOneWidget);
expect(find.byKey(const Key('deck_like_btn')), findsOneWidget);

expect(find.byKey(const Key('screen_08_doi_profile_detail')), findsOneWidget);
expect(find.byKey(const Key('detail_sheet_handle')), findsOneWidget);
expect(find.byType(PhotoCarousel), findsOneWidget);
```

Also assert the four deck action buttons are at least 44×44 and remain callable without a swipe gesture.

- [ ] **Step 2: Run the focused discovery tests**

Run: `flutter test test/features/discovery/doi_deck_screen_test.dart test/features/discovery/candidate_card_test.dart test/features/discovery/candidate_detail_sheet_test.dart test/features/discovery/deck_action_bar_test.dart`

Expected: FAIL for the new root keys or touch-size assertions.

- [ ] **Step 3: Rewrite only the deck presentation tree**

Put the screen body inside:

```dart
ResponsiveFrame(
  child: KeyedSubtree(
    key: const Key('screen_07_doi_deck'),
    child: Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: _buildHeader(context, l10n),
        ),
        Expanded(child: _buildDeckBody(context, l10n, itemsAsync)),
      ],
    ),
  ),
)
```

Keep `_handleSwipe`, `_handleRewind`, `_handleBoost`, `_refreshDeck`, location retry, analytics calls, coach mark persistence and provider reads unchanged. Candidate cards prioritize photo, identity, online state and shared music; move secondary facts below the identity block. Wrap `CandidateDetailSheet` content with `screen_08_doi_profile_detail`, preserve deck mode versus quote mode, raw-song fallback and report/block access.

- [ ] **Step 4: Run all discovery tests**

Run: `flutter test test/features/discovery`

Expected: PASS, including swipe quotas, rewind anchoring, location states and theme routing.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/discovery/presentation test/features/discovery
git commit -m "feat: redesign doi deck and profile detail"
```

### Task 8: Match celebration and explore themes

**Files:**
- Modify: `lib/features/discovery/presentation/match_celebration.dart`
- Modify: `lib/features/discovery/presentation/theme_board_screen.dart`
- Modify: `test/features/discovery/match_celebration_test.dart`
- Modify: `test/features/discovery/theme_decks_test.dart`

**Interfaces:**
- Consumes: unchanged match callbacks, `songsProvider`, `themeDeckCountsProvider` and GoRouter calls.
- Produces: root keys `screen_09_match_celebration`, `screen_10_explore_themes`.

- [ ] **Step 1: Add failing motion and hierarchy tests**

```dart
expect(find.byKey(const Key('screen_09_match_celebration')), findsOneWidget);
expect(find.byKey(const Key('match_identity_my')), findsOneWidget);
expect(find.byKey(const Key('match_identity_other')), findsOneWidget);
expect(find.byKey(const Key('match_chat_btn')), findsOneWidget);
expect(find.byKey(const Key('match_continue_btn')), findsOneWidget);

expect(find.byKey(const Key('screen_10_explore_themes')), findsOneWidget);
expect(find.byKey(const Key('theme_card_ballad')), findsOneWidget);
expect(find.byKey(const Key('theme_brand_plaque')), findsOneWidget);
```

Pump match celebration with `MediaQueryData(disableAnimations: true)` and assert the final identities and CTAs render immediately.

- [ ] **Step 2: Run match/theme tests**

Run: `flutter test test/features/discovery/match_celebration_test.dart test/features/discovery/theme_decks_test.dart`

Expected: FAIL for the new root keys.

- [ ] **Step 3: Apply the high-playfulness presentation**

Add the root keys, keep the existing 1400ms celebration controller and reduced-motion branch, and ensure the CTA area remains static while note rain and identity cards animate. For themes, use `ResponsiveFrame`, preserve every `theme_card_<genreId>` key and `/explore/<genre>` push, and retain live-count fallback behavior.

```dart
final duration = MediaQuery.maybeDisableAnimationsOf(context) == true
    ? Duration.zero
    : AppMotion.slow;
```

Use this token for theme-card entrances; do not add motion to the live-count provider or navigation.

- [ ] **Step 4: Run all discovery tests again**

Run: `flutter test test/features/discovery`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/discovery/presentation/match_celebration.dart lib/features/discovery/presentation/theme_board_screen.dart test/features/discovery
git commit -m "feat: redesign match and theme discovery"
```

### Task 9: Kèo board and auto-match

**Files:**
- Modify: `lib/features/keo/presentation/keo_board_screen.dart`
- Modify: `lib/features/keo/presentation/keo_card.dart`
- Modify: `lib/features/keo/presentation/keo_match_sheet.dart`
- Modify: `test/features/keo/keo_board_gate_test.dart`
- Modify: `test/features/keo/keo_board_location_test.dart`
- Modify: `test/features/keo/keo_card_test.dart`
- Modify: `test/features/keo/keo_match_sheet_test.dart`

**Interfaces:**
- Consumes: unchanged open-Kèo, location, suggestion, join and create operations.
- Produces: root keys `screen_11_keo_board`, `screen_12_keo_auto_match`.

- [ ] **Step 1: Add failing ticket hierarchy tests**

```dart
expect(find.byKey(const Key('screen_11_keo_board')), findsOneWidget);
expect(find.byType(TicketCard), findsWidgets);
expect(find.byKey(const Key('keo_member_strip')), findsOneWidget);

expect(find.byKey(const Key('screen_12_keo_auto_match')), findsOneWidget);
expect(find.byKey(const Key('keo_match_reason_grid')), findsOneWidget);
expect(find.byKey(const Key('keo_match_join_btn')), findsOneWidget);
```

Keep tests for `keo_match_create_btn`, `keo_match_later_btn`, disabled in-flight state and 320px large text.

- [ ] **Step 2: Run board/card/match-sheet tests**

Run: `flutter test test/features/keo/keo_board_gate_test.dart test/features/keo/keo_board_location_test.dart test/features/keo/keo_card_test.dart test/features/keo/keo_match_sheet_test.dart`

Expected: FAIL for new root keys.

- [ ] **Step 3: Implement the board and sheet presentation**

Wrap the board list and sticky create CTA inside `ResponsiveFrame` and `KeyedSubtree(key: Key('screen_11_keo_board'))`. Preserve `_runAutoMatch`, `_runSheetAction`, `_joinSuggestion`, `_createSuggestion` and the free-user gate exactly. Wrap `KeoMatchSheet`'s scrollable content in `screen_12_keo_auto_match`; keep action keys and loading guards.

Use `TicketCard` for every Kèo/suggestion card. The visible information order
is time window, title, area/distance, member capacity, genres/join mode, then
host; none of these display labels are sent to a provider.

- [ ] **Step 4: Run all Kèo tests**

Run: `flutter test test/features/keo`

Expected: PASS, including location, free/pro gates, permissions and double-submit protection.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/keo/presentation/keo_board_screen.dart lib/features/keo/presentation/keo_card.dart lib/features/keo/presentation/keo_match_sheet.dart test/features/keo
git commit -m "feat: redesign keo board and auto match"
```

### Task 10: Create Kèo and Kèo detail

**Files:**
- Modify: `lib/features/keo/presentation/create_keo_screen.dart`
- Modify: `lib/features/keo/presentation/keo_detail_screen.dart`
- Modify: `test/features/keo/create_keo_test.dart`
- Modify: `test/features/keo/keo_detail_test.dart`

**Interfaces:**
- Consumes: all existing form controllers, validation, repository actions, permission and entitlement gates.
- Produces: root keys `screen_13_create_keo`, `screen_14_keo_detail`.

- [ ] **Step 1: Add failing root, grouping and compact-layout tests**

```dart
expect(find.byKey(const Key('screen_13_create_keo')), findsOneWidget);
expect(find.byKey(const Key('create_keo_title_field')), findsOneWidget);
expect(find.byKey(const Key('create_keo_venue_hint')), findsOneWidget);
expect(find.byKey(const Key('create_keo_genre_grid')), findsOneWidget);

expect(find.byKey(const Key('screen_14_keo_detail')), findsOneWidget);
expect(find.byKey(const Key('request_join_btn')), findsOneWidget);
```

At 360dp/text scale 1.4, scroll through each screen and assert its primary action remains hit-testable with no Flutter exception.

- [ ] **Step 2: Run create/detail tests**

Run: `flutter test test/features/keo/create_keo_test.dart test/features/keo/keo_detail_test.dart`

Expected: FAIL for new root keys.

- [ ] **Step 3: Recompose the forms and detail sections**

Use `ResponsiveFrame` around each existing scroll view. Create Kèo groups remain: basic information, time/place, music/vibe, group size/join mode, submit. Detail groups remain: header, facts, roster, permissions/actions. Add the root keys at the top of the scrollable content and keep every provider/repository call and action key unchanged.

```dart
const sectionGap = SizedBox(height: AppSpacing.lg);
const fieldGap = SizedBox(height: AppSpacing.md);
```

Use these two spacing constants consistently inside both files; do not create new domain fields.

- [ ] **Step 4: Run Kèo presentation tests**

Run: `flutter test test/features/keo`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/keo/presentation/create_keo_screen.dart lib/features/keo/presentation/keo_detail_screen.dart test/features/keo
git commit -m "feat: redesign keo creation and detail"
```

### Task 11: Inbox

**Files:**
- Modify: `lib/features/chat/presentation/inbox_screen.dart`
- Modify: `test/features/chat/inbox_screen_test.dart`
- Modify: `test/features/chat/inbox_turn_pill_test.dart`

**Interfaces:**
- Consumes: `inboxProvider`, `myKeosProvider`, `myProfileProvider`, existing navigation callbacks.
- Produces: root key `screen_15_inbox`; match and Kèo sections retain routing meaning.

- [ ] **Step 1: Add failing section and state tests**

```dart
expect(find.byKey(const Key('screen_15_inbox')), findsOneWidget);
expect(find.byKey(const Key('inbox_keo_section')), findsOneWidget);
expect(find.byKey(const Key('inbox_match_section')), findsOneWidget);
expect(find.text('Kèo của bạn'), findsOneWidget);
expect(find.text('Tin nhắn đôi'), findsOneWidget);
```

For no data, assert `EmptyState` still has the existing `onFindKeo` CTA. For loading, assert `SkeletonTile` reserves list-row geometry.

- [ ] **Step 2: Run inbox tests**

Run: `flutter test test/features/chat/inbox_screen_test.dart test/features/chat/inbox_turn_pill_test.dart`

Expected: FAIL for the new root/section keys or skeleton expectation.

- [ ] **Step 3: Build the calm inbox hierarchy**

Wrap the inbox in `ResponsiveFrame` and `screen_15_inbox`; put Kèo rows and pair-chat rows under their respective section keys. Keep unread count, turn pill, host badge, route paths and `onFindKeo` behavior unchanged. Use one `HardCard` per row and a `WaveDivider` only between sections, not between every message row.

- [ ] **Step 4: Run chat inbox tests**

Run: `flutter test test/features/chat/inbox_screen_test.dart test/features/chat/inbox_turn_pill_test.dart test/app/home_shell_test.dart`

Expected: PASS, including refetch when reselecting the Chat tab.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/chat/presentation/inbox_screen.dart test/features/chat test/app/home_shell_test.dart
git commit -m "feat: redesign inbox presentation"
```

### Task 12: One-to-one and Kèo group chat

**Files:**
- Modify: `lib/features/chat/presentation/chat_screen.dart`
- Modify: `lib/features/chat/presentation/chat_widgets.dart`
- Modify: `lib/features/chat/presentation/chat_timeline.dart`
- Modify: `lib/features/keo/presentation/keo_chat_screen.dart`
- Modify: `test/features/chat/chat_screen_test.dart`
- Modify: `test/features/chat/chat_history_error_test.dart`
- Modify: `test/features/keo/keo_chat_test.dart`

**Interfaces:**
- Consumes: unchanged history/live-message providers, send/safety/song-share callbacks.
- Produces: root keys `screen_16_chat_1to1`, `screen_17_keo_group_chat`; unchanged `ChatComposer` constructor.

- [ ] **Step 1: Add failing timeline/composer tests**

```dart
expect(find.byKey(const Key('screen_16_chat_1to1')), findsOneWidget);
expect(find.byKey(const Key('chat_timeline')), findsOneWidget);
expect(find.byKey(const Key('chat_composer')), findsOneWidget);

expect(find.byKey(const Key('screen_17_keo_group_chat')), findsOneWidget);
expect(find.byKey(const Key('keo_chat_subtitle')), findsOneWidget);
expect(find.byKey(const Key('group_rules_banner')), findsOneWidget);
expect(find.byKey(const Key('chat_composer')), findsOneWidget);
```

At 360×640 with a 260px keyboard inset, assert the composer remains visible and the timeline takes the remaining height.

- [ ] **Step 2: Run chat tests**

Run: `flutter test test/features/chat/chat_screen_test.dart test/features/chat/chat_history_error_test.dart test/features/keo/keo_chat_test.dart`

Expected: FAIL for the new presentation keys.

- [ ] **Step 3: Recompose chat chrome while preserving messaging behavior**

Add the keys to the two shared chrome roots:

```diff
--- a/lib/features/chat/presentation/chat_widgets.dart
+++ b/lib/features/chat/presentation/chat_widgets.dart
@@ ChatComposer.build
     return SafeArea(
+      key: const Key('chat_composer'),
       top: false,

--- a/lib/features/keo/presentation/keo_chat_screen.dart
+++ b/lib/features/keo/presentation/keo_chat_screen.dart
@@ _GroupRulesBanner.build
     return Padding(
+      key: const Key('group_rules_banner'),
       padding: const EdgeInsets.fromLTRB(
```

Add `KeyedSubtree(key: Key('chat_timeline'))` around the current
history/error/empty/list expression, and wrap the full bodies with
`screen_16_chat_1to1` and `screen_17_keo_group_chat`. Keep message
merge/order/dedup, sender identity, read marking, realtime subscription,
unsafe-message confirmation and analytics unchanged. Use primary tint for
own bubbles and surface for other bubbles so normal text can remain ink and
meet 4.5:1.

- [ ] **Step 4: Run all chat and Kèo-chat tests**

Run: `flutter test test/features/chat test/features/keo/keo_chat_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/chat/presentation lib/features/keo/presentation/keo_chat_screen.dart test/features/chat test/features/keo/keo_chat_test.dart
git commit -m "feat: redesign direct and group chat"
```

### Task 13: Plan/map and booking/payment presentation

**Files:**
- Modify: `lib/features/plan/presentation/plan_screen.dart`
- Modify: `lib/features/plan/presentation/venue_map_surface.dart`
- Modify: `lib/features/plan/presentation/plan_time_picker_sheet.dart`
- Modify: `lib/features/plan/presentation/booking_button.dart`
- Modify: `lib/features/plan/presentation/safety_toolkit.dart`
- Modify: `test/features/plan/plan_screen_test.dart`
- Modify: `test/features/plan/presentation/plan_screen_v1_test.dart`
- Modify: `test/features/plan/venue_map_surface_test.dart`
- Modify: `test/features/plan/booking_button_test.dart`

**Interfaces:**
- Consumes: existing plan/venue providers, `bookingEnabled`, payment gateway callbacks and URL launch.
- Produces: root keys `screen_19_plan`, `screen_20_booking_payment`.

- [ ] **Step 1: Add failing plan/payment hierarchy tests**

```dart
expect(find.byKey(const Key('screen_19_plan')), findsOneWidget);
expect(find.byKey(const Key('venue_map_surface')), findsOneWidget);
expect(find.byKey(const Key('venue_marker_v1')), findsOneWidget);

expect(find.byKey(const Key('screen_20_booking_payment')), findsOneWidget);
expect(find.byKey(const Key('booking_gw_momo')), findsOneWidget);
expect(find.byKey(const Key('booking_gw_zalopay')), findsOneWidget);
```

Retain the test that `BOOKING_ENABLED` is off by default and `directions_btn` replaces booking.

- [ ] **Step 2: Run plan tests**

Run: `flutter test test/features/plan`

Expected: FAIL for the new root keys.

- [ ] **Step 3: Recompose map, current plan and venue cards**

Wrap the plan scroll view in `ResponsiveFrame` plus `screen_19_plan`. The map remains first, followed by current-plan card and venue/action cards. Replace blocking spinners with `SkeletonCard`; convert provider errors to `EmptyState` with the current invalidate callbacks. Add `screen_20_booking_payment` to the payment gateway sheet only, leaving `bookingEnabled`, plan proposal/confirmation, payment amount authority and gateway values unchanged.

```dart
const planSectionPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.lg,
  vertical: AppSpacing.sm,
);
```

Use this padding for current-plan and venue sections; do not alter Google Maps/native-map behavior.

- [ ] **Step 4: Run all plan tests**

Run: `flutter test test/features/plan`

Expected: PASS, including the v1 payment feature flag test.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/plan/presentation test/features/plan
git commit -m "feat: redesign plan and booking presentation"
```

### Task 14: Store

**Files:**
- Modify: `lib/features/billing/presentation/store_screen.dart`
- Modify: `test/features/billing/store_screen_test.dart`

**Interfaces:**
- Consumes: `storeProductsProvider`, catalog order and `iapControllerProvider.buy`.
- Produces: root key `screen_21_store`; product prices remain catalog-derived.

- [ ] **Step 1: Add failing store hierarchy/state tests**

```dart
expect(find.byKey(const Key('screen_21_store')), findsOneWidget);
expect(find.byKey(const Key('store_pro_hero')), findsOneWidget);
expect(find.byKey(const Key('store_product_pro')), findsOneWidget);
expect(find.text('199k'), findsOneWidget);
expect(find.text('Mua'), findsNWidgets(4));
```

For loading, assert `SkeletonCard` is shown; for error, assert `EmptyState` contains the current retry callback.

- [ ] **Step 2: Run store tests**

Run: `flutter test test/features/billing/store_screen_test.dart`

Expected: FAIL for the new keys/states.

- [ ] **Step 3: Implement the calm commerce hierarchy**

Wrap the body in `ResponsiveFrame` and `screen_21_store`. Use `HardCard(key: Key('store_pro_hero'))` for the Pro value proposition and `HardCard(key: Key('store_product_${product.type}'))` for each catalog item. Preserve `_order`, `_copyFor`, `formatPriceK`, product type passed to `buy`, unknown-type fallback and failure SnackBar.

- [ ] **Step 4: Run billing tests**

Run: `flutter test test/features/billing`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/billing/presentation/store_screen.dart test/features/billing
git commit -m "feat: redesign store presentation"
```

### Task 15: Settings

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Modify: `test/features/settings/language_switch_test.dart`
- Modify: `test/features/settings/settings_toggle_error_test.dart`
- Modify: `test/features/settings/settings_delete_error_test.dart`

**Interfaces:**
- Consumes: existing consent, locale, export, sign-out, delete-account and legal-route behavior.
- Produces: root key `screen_22_settings`; settings sections use valid Material ink surfaces.

- [ ] **Step 1: Add failing settings hierarchy and no-assertion tests**

```dart
expect(find.byKey(const Key('screen_22_settings')), findsOneWidget);
expect(find.byKey(const Key('settings_privacy_section')), findsOneWidget);
expect(find.byKey(const Key('settings_language_section')), findsOneWidget);
expect(find.byKey(const Key('settings_account_section')), findsOneWidget);
expect(find.byKey(const Key('settings_legal_section')), findsOneWidget);
expect(tester.takeException(), isNull);
```

Remove the helpers that suppress the “ListTile background color or ink splashes” assertion; the redesigned surface must not emit that assertion.

- [ ] **Step 2: Run settings tests**

Run: `flutter test test/features/settings`

Expected: FAIL because section keys are absent or the old suppressed assertion becomes visible.

- [ ] **Step 3: Rebuild settings groups with Material-backed hard cards**

Wrap the list in `ResponsiveFrame` and `screen_22_settings`. Change `_Section` to accept `Key? key`, return `HardCard(key: key, child: Column(...))`, and assign the four section keys. Use error tint only for delete; keep confirmation, `_deleting` guard, locale persistence, consent rollback and legal routes unchanged.

```dart
const settingsSectionKeys = <String, Key>{
  'privacy': Key('settings_privacy_section'),
  'language': Key('settings_language_section'),
  'account': Key('settings_account_section'),
  'legal': Key('settings_legal_section'),
};
```

- [ ] **Step 4: Run settings tests**

Run: `flutter test test/features/settings`

Expected: PASS without filtering any Flutter assertion.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/settings/presentation/settings_screen.dart test/features/settings
git commit -m "feat: redesign settings presentation"
```

### Task 16: Complete responsive, platform and accessibility matrix

**Files:**
- Create: `test/support/presentation_harness.dart`
- Create: `test/app/presentation_matrix_test.dart`
- Modify: `test/app/responsive_smoke_test.dart`
- Modify: relevant screen tests under `test/features/**`

**Interfaces:**
- Consumes: all 22 `screen_XX_*` keys and existing provider overrides.
- Produces: reusable `pumpPresentation` helper and a matrix that covers Android/iOS presentation at required widths/scales.

- [ ] **Step 1: Create the shared test harness**

```dart
import 'package:cung_hat/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpPresentation(
  WidgetTester tester, {
  required Widget child,
  Size size = const Size(393, 852),
  double textScale = 1,
  TargetPlatform platform = TargetPlatform.android,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light().copyWith(platform: platform),
      home: child,
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}
```

- [ ] **Step 2: Add matrix tests that initially expose uncovered layouts**

Use the existing provider fakes from each feature test and iterate:

```dart
const widths = <double>[360, 393, 430];
const scales = <double>[1, 1.2, 1.4];
const platforms = <TargetPlatform>[
  TargetPlatform.android,
  TargetPlatform.iOS,
];
```

For every root key in the screen coverage map, assert:

```dart
expect(find.byKey(screenKey), findsOneWidget);
expect(tester.takeException(), isNull);
```

For scrollable screens, call `tester.dragUntilVisible` for the primary CTA. For swipe-driven screen 07, tap `deck_pass_btn` and `deck_like_btn` in separate pumps to verify pointer alternatives.

- [ ] **Step 3: Run the matrix**

Run: `flutter test test/app/presentation_matrix_test.dart test/app/responsive_smoke_test.dart`

Expected: all 22 keys are covered at least once; any overflow/focus/touch failure is reported by the exact screen case.

- [ ] **Step 4: Fix only presentation defects exposed by the matrix**

Allowed fixes are `Flexible`, `Expanded`, `Wrap`, `FittedBox`, `ConstrainedBox`, scrolling, padding, max-lines, focus order, semantic labels and touch sizing inside the permitted presentation paths. Do not weaken the matrix, reduce widths/scales or suppress Flutter errors.

- [ ] **Step 5: Run analysis and the complete test suite**

Run: `flutter analyze`

Expected: `No issues found!`

Run: `flutter test --reporter compact`

Expected: `All tests passed!` with at least the 437 baseline tests plus the new presentation tests.

- [ ] **Step 6: Commit**

```powershell
git add -- lib/core/theme lib/shared/widgets lib/app/home_shell.dart ':(glob)lib/features/*/presentation/**' test
git commit -m "test: cover presentation platform matrix"
```

### Task 17: Android, web, evidence and backend-boundary audit

**Files:**
- Create: `integration_test/presentation_capture_test.dart`
- Create: `test_driver/presentation_capture_driver.dart`
- Create: `docs/redesign-validation/2026-07-19-presentation-report.md`
- Create: `docs/redesign-validation/after/01-login.png` through `docs/redesign-validation/after/22-settings.png`
- Modify: none outside documentation if code already passes.

**Interfaces:**
- Consumes: emulator `emulator-5554`, Chrome, 22 root keys and mockups under `docs/redesign-mockups/`.
- Produces: one final review package with 22 screenshots, intentional-difference log and test/boundary evidence.

- [ ] **Step 1: Add the Android screenshot driver**

```dart
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (
      String name,
      List<int> bytes, [
      Map<String, Object?>? args,
    ]) async {
      final file = File('docs/redesign-validation/after/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return true;
    },
  );
}
```

- [ ] **Step 2: Add the deterministic 22-state capture test**

Start `integration_test/presentation_capture_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized()
          as IntegrationTestWidgetsFlutterBinding;
  var surfaceConverted = false;

  Future<void> capture(
    WidgetTester tester, {
    required String name,
    required Widget app,
    required Finder screen,
  }) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    if (!surfaceConverted) {
      await binding.convertFlutterSurfaceToImage();
      surfaceConverted = true;
      await tester.pumpAndSettle();
    }
    expect(screen, findsOneWidget);
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot(name);
  }
}
```

Add one `testWidgets` case per row in the Screen Coverage Map. Pump the same
production widget and provider overrides used by its focused widget test,
then call `capture` with the exact basename (`01-login` through
`22-settings`). For sheet states 08, 12 and 20, pump the sheet widget
directly. For onboarding states 03–06, pump `OnboardingFlow`, advance with
the preserved keys, then capture. The capture file must not import or call
an external backend. It may import a repository type solely to implement an
in-memory fake, but it must not instantiate the production repository or
make a network/RPC call.

- [ ] **Step 3: Verify the Android target and build**

Run:

```powershell
adb -s emulator-5554 shell getprop sys.boot_completed
flutter build apk --debug
```

Expected: boot property `1` and a successful APK build.

- [ ] **Step 4: Capture all 22 states on Android**

Run:

```powershell
flutter drive --driver=test_driver/presentation_capture_driver.dart --target=integration_test/presentation_capture_test.dart -d emulator-5554
```

Expected: 22 PNG files whose basenames exactly match the 22 mockups. Open
every PNG and confirm it contains the expected `screen_XX_*` state before
continuing.

- [ ] **Step 5: Verify mobile web**

Run:

```powershell
flutter build web
flutter run -d chrome --web-port 7357
```

Expected: successful build; at 360, 393 and 430 CSS pixels, all primary flows center correctly, keyboard/focus/pointer interaction works, and no horizontal scrollbar appears.

- [ ] **Step 6: Compare screenshots and write the validation report**

The report must contain this complete table:

```markdown
| # | Mockup | Android capture | Result | Intentional difference |
|---:|---|---|---|---|
| 01 | `docs/redesign-mockups/01-login.png` | `after/01-login.png` | Pass | Data-safe production copy retained |
```

Add rows 02–22, record every intentional hybrid adjustment, state that iOS was validated through `TargetPlatform.iOS` widget tests only, and list the exact analyze/test/build commands and outcomes.

- [ ] **Step 7: Run the forbidden-path audit**

Run:

```powershell
$changed = @(
  git diff --name-only e3f1f389..HEAD
  git diff --name-only
  git diff --cached --name-only
  git ls-files --others --exclude-standard
) | Sort-Object -Unique
$forbidden = $changed | Where-Object {
  $_ -match '^supabase/' -or
  $_ -match '^lib/features/.+/(data|domain|application)/' -or
  $_ -eq 'lib/app/router.dart' -or
  $_ -match '^lib/core/providers/' -or
  $_ -match '^lib/core/analytics/'
}
if ($forbidden) {
  $forbidden
  throw 'Frontend-only boundary violated.'
}
'Frontend-only boundary clean.'
```

Expected: `Frontend-only boundary clean.`

- [ ] **Step 8: Run final verification**

Run:

```powershell
flutter analyze
flutter test --reporter compact
flutter build apk --debug
flutter build web
git diff --check e3f1f389..HEAD
git status --short
```

Expected: analyze clean, all tests pass, both builds succeed, diff check is empty, and status contains only the intended redesign/evidence files plus the user's pre-existing untracked files.

- [ ] **Step 9: Commit the capture harness and evidence package**

```powershell
git add integration_test/presentation_capture_test.dart test_driver/presentation_capture_driver.dart docs/redesign-validation
git commit -m "docs: add presentation redesign validation"
```

- [ ] **Step 10: Present the single final review**

Show the user the report, the 22 after images, the test totals, Android/web build results, the iOS validation limitation and the clean backend-boundary audit. Do not request any earlier user review.
