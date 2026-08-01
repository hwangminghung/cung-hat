# UI Upgrade 2026-08-01 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dark mode "retro mixtape đêm" (theo máy + toggle) + polish 4 màn audit + chuẩn hoá loading/error + push primer sheet.

**Architecture:** `AppColors` giữ nguyên tên member nhưng đổi từ `static const` sang getter đọc `AppPalette` hiện hành (2 bảng const light/dark, chọn theo `ThemeModeController` + platformBrightness). Compile error tại các call-site `const` là cơ chế liệt kê chỗ cần sweep. Mỗi đợt là chuỗi commit độc lập trên `ui-upgrade-0801`, gate = analyze 0 + full test.

**Tech Stack:** Flutter/Riverpod/go_router, shared_preferences (persist), pgTAP không đụng (thuần client), l10n ARB vi+en có guard parity.

**Spec:** `docs/superpowers/specs/2026-08-01-ui-upgrade-design.md`

---

## Đợt 1 — Dark mode

### Task 1: AppPalette + AppColors chuyển sang getter

**Files:**
- Create: `lib/core/theme/app_palette.dart`
- Modify: `lib/core/theme/app_colors.dart` (toàn bộ)
- Modify: `lib/core/theme/app_shadows.dart`
- Test: `test/theme/color_contrast_test.dart` (parametrize 2 palette)

- [ ] **Step 1: Viết `AppPalette`** — class thuần dữ liệu, mọi field `final Color`, 2 factory const `light`/`dark`. Copy nguyên giá trị light từ AppColors hiện tại. Dark theo bảng spec:

```dart
// app_palette.dart (rút gọn — đủ 35 vai trò như AppColors hiện có)
import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette({
    required this.primary, required this.primaryDark, required this.primaryTint,
    required this.primarySoft, required this.onPrimary, required this.secondary,
    required this.secondaryDark, required this.secondaryTint, required this.teal,
    required this.tertiaryTint, required this.tertiaryPop, required this.pink,
    required this.background, required this.surface, required this.surfaceAlt,
    required this.surfaceWarm, required this.surfaceMuted, required this.ink,
    required this.textSecondary, required this.textHint, required this.success,
    required this.successTint, required this.warning, required this.warningTint,
    required this.error, required this.errorTint, required this.shadowColor,
  });

  // ... các field final tương ứng ...

  static const light = AppPalette(
    primary: Color(0xFFE8501F), /* ... nguyên trạng AppColors hiện tại ... */
    shadowColor: Color(0x331E3A2F),
  );
  static const dark = AppPalette(
    primary: Color(0xFFE8501F), onPrimary: Color(0xFFFFFFFF),
    primaryDark: Color(0xFFFFB59B), primaryTint: Color(0xFF4A2417),
    primarySoft: Color(0xFFF18D69),
    secondary: Color(0xFFC6E534), secondaryDark: Color(0xFFDFF07E),
    secondaryTint: Color(0xFF333D12),
    teal: Color(0xFF8FD8C8), tertiaryTint: Color(0xFF1F3A34),
    tertiaryPop: Color(0xFF5DBBA8), pink: Color(0xFFE979A9),
    background: Color(0xFF14231C), surface: Color(0xFF1B2E25),
    surfaceAlt: Color(0xFF24382C), surfaceWarm: Color(0xFF3A2E24),
    surfaceMuted: Color(0xFF2E4237),
    ink: Color(0xFFF2EAD3), textSecondary: Color(0xFFB7C7BB),
    textHint: Color(0xFF93A79A),
    success: Color(0xFF58C389), successTint: Color(0xFF163326),
    warning: Color(0xFFD99A3D), warningTint: Color(0xFF3A2E14),
    error: Color(0xFFEF6A5E), errorTint: Color(0xFF45201C),
    shadowColor: Color(0x8C000000),
  );
}
```

- [ ] **Step 2: `AppColors` → getter + select()**. Giữ nguyên TÊN mọi member; thêm:

```dart
abstract final class AppColors {
  static AppPalette _p = AppPalette.light;
  @visibleForTesting
  static AppPalette get palette => _p;
  /// Gọi từ CungHatApp.build TRƯỚC khi dựng MaterialApp; test dark gọi tay.
  static void select(Brightness b) =>
      _p = b == Brightness.dark ? AppPalette.dark : AppPalette.light;

  static Color get primary => _p.primary;
  // ... 1 getter / vai trò; alias textPrimary=>ink, border=>ink, tertiary=>teal
  // giữ nguyên; onPrimaryMinBoldSize/const không-màu giữ const;
  // brandGradient/warmGradient thành getter dựng từ _p.
}
```

- [ ] **Step 3: `AppShadows.hard` → getter** dùng `AppColors` (hết const):
`static BoxShadow get hard => BoxShadow(color: AppColors.shadow, offset: Offset(3,3), blurRadius: 0);` — chú ý mọi chỗ `const <BoxShadow>[AppShadows.hard]` sẽ compile-error → bỏ const.

- [ ] **Step 4: `flutter analyze`** → compiler liệt kê mọi call-site `const` vỡ. Sweep bỏ `const` đúng các chỗ đó (không đổi gì khác). Lặp tới 0 error.

- [ ] **Step 5: parametrize contrast test.** Bọc toàn bộ case hiện có trong `for (final (name, palette) in [('light', AppPalette.light), ('dark', AppPalette.dark)])`, thay `AppColors.x` bằng `palette.x`. Chạy `flutter test test/theme/` — hex nào trượt thì CHỈNH HEX Ở PALETTE (không nới ngưỡng), ghi tỉ lệ mới vào comment.

- [ ] **Step 6: full test + commit** `feat(theme): AppPalette 2 bang mau + AppColors getter theo mode`.

### Task 2: ThemeModeController + AppTheme.dark() + wiring app

**Files:**
- Create: `lib/core/theme/theme_mode_controller.dart` (copy khuôn `locale_controller.dart`: pref `theme_mode` 'light'/'dark', vắng = system; `loadSavedThemeMode()` gọi ở main() trước runApp; `initialThemeModeProvider` override trong ProviderScope)
- Modify: `lib/core/theme/app_theme.dart` — tách builder chung `ThemeData _build(AppPalette p)`; `light() => _build(AppPalette.light)`, thêm `dark() => _build(AppPalette.dark)`. Trong builder, thay MỌI `AppColors.x` bằng `p.x`, bỏ `const scheme`.
- Modify: `lib/main.dart` (seed pref), `lib/app/app.dart`:

```dart
// app.dart build():
final mode = ref.watch(themeModeControllerProvider); // ThemeMode
final platformB = ref.watch(platformBrightnessProvider); // provider cập nhật qua WidgetsBindingObserver
AppColors.select(switch (mode) {
  ThemeMode.light => Brightness.light,
  ThemeMode.dark => Brightness.dark,
  ThemeMode.system => platformB,
});
return MaterialApp.router(
  theme: AppTheme.light(), darkTheme: AppTheme.dark(), themeMode: mode, ...);
```
`platformBrightnessProvider`: StateProvider seed `platformDispatcher.platformBrightness`; `_CungHatAppState` thêm `WidgetsBindingObserver.didChangePlatformBrightness` → cập nhật provider.

- [ ] Test: `test/core/theme_mode_controller_test.dart` — set('dark') persist + build lại đọc đúng; set(null) → system. Widget test `test/app/theme_mode_switch_test.dart`: pump app-shell tối giản, đổi controller → `Theme.of` brightness đổi + `AppColors.background` đổi.
- [ ] Commit `feat(theme): dark mode theo may + ThemeModeController persist`.

### Task 3: Toggle trong Cài đặt

**Files:** Modify `lib/features/settings/presentation/settings_screen.dart` (thêm `_Section` "Giao diện" NGAY TRÊN section Ngôn ngữ, 3 tile key `theme_system|theme_light|theme_dark`, dùng `_LanguageTile` — nếu private thì đổi tên chung `_ChoiceTile`), l10n vi+en: `settingsTheme`("Giao diện"/"Appearance"), `settingsThemeSystem`("Theo máy"/"System"), `settingsThemeLight`("Sáng"/"Light"), `settingsThemeDark`("Tối"/"Dark"). Test `test/features/settings/theme_switcher_test.dart` (tap tile → controller đổi + tick đúng tile). Commit `feat(settings): chon giao dien Sang/Toi/Theo may`.

### Task 4: Sweep hardcode màu + verify dark trên emulator

- [ ] `grep -rn "Color(0x" lib/ --include=*.dart | grep -v core/theme` — chỗ nào là màu UI thật (không phải alpha overlay có chủ đích) chuyển về AppColors.
- [ ] `grep -rn "Colors\." lib/ --include=*.dart | grep -v transparent` — xử tương tự.
- [ ] Build APK + emulator: đổi Tối trong Cài đặt, đi 4 tab + Store + Bộ lọc + chat, chụp light/dark từng màn, soát chữ chìm/viền mất. Chỉnh palette nếu lệch.
- [ ] Commit `fix(theme): sweep mau hardcode + tinh chinh dark palette theo emulator`.

## Đợt 2 — Polish 4 màn

### Task 5: PlanScreen CTA hierarchy

**Files:** `lib/features/plan/presentation/plan_screen.dart`, `safety_toolkit.dart`, test `test/features/plan/plan_screen_test.dart` (file test plan hiện có — thêm case).

- CTA chính ("Đồng ý kế hoạch" khi chưa confirm; "Đặt phòng"/BookingButton khi đã confirm) = full-width `GradientButton` (SizedBox width: double.infinity, height: AppSpacing.buttonHeight).
- `SafetyToolkit`: đổi 2 nút Expanded thành hàng OutlinedButton.icon đồng cỡ; label share rút còn `safetyShareShort` "Chia sẻ" (vi) / "Share" (en) — key MỚI, giữ key cũ cho message. Test: pump width 360 textScale 1.4 → mỗi label maxLines 1 không tràn (`tester.takeException() == null` + text không wrap: so sánh size).
- Commit `feat(plan): CTA chinh full-width + hang action phu dong co`.

### Task 6: Chat rỗng gợi ý + disable nút gửi

**Files:** `lib/features/chat/presentation/chat_screen.dart`, `chat_widgets.dart` (ChatComposer), `keo_chat_screen.dart`, l10n, test `test/features/chat/chat_composer_test.dart` + case mới trong chat_screen test.

- `ChatComposer` thêm `enabled`/lắng nghe controller: nút gửi `onPressed: text.trim().isEmpty ? null : onSend` (AnimatedBuilder trên TextEditingController).
- Empty state chat 1-1: dưới `chatEmptyMatch` thêm `Wrap` 3 `ActionChip` key `chat_sugg_baitu|chat_sugg_taste|chat_sugg_invite`: "Gửi bài tủ" mở sheet bài tủ sẵn có (nút share bài tủ hiện hữu — tái dùng handler '♪ '); 2 chip kia điền template vào composer (`l10n.chatSuggTasteMsg` "Gu nhạc của bạn là gì? 🎵", `chatSuggInviteMsg` "Cuối tuần này đi hát không?").
- l10n keys vi+en: `chatSuggBaitu/chatSuggTaste/chatSuggInvite/chatSuggTasteMsg/chatSuggInviteMsg`.
- Test: composer trống → send null; gõ chữ → enabled; tap chip taste → controller.text = template.
- Commit `feat(chat): goi y bat chuyen khi chat rong + disable gui khi trong`.

### Task 7: Store tách Pro / Mua lẻ

**Files:** `lib/features/billing/presentation/store_screen.dart`, l10n, test `test/features/billing/store_screen_test.dart` (sửa case danh sách).

- Trước danh sách: `_SectionLabel(l10n.storeSectionPro 'Gói Pro')` cho tile pro (highlight, giữ nguyên); `_SectionLabel(l10n.storeSectionALaCarte 'Mua lẻ')` trước 3 tile còn lại.
- `_UpgradeTile` thêm `includedInPro` (chip nhỏ lime `l10n.storeIncludedInPro 'Đã gồm trong Pro'` cạnh giá) cho boost/see_likes/premium_filters; khi user Pro: các tile lẻ hiện `ownedLabel` (đã có prop owned — truyền thêm `ref.watch(isProProvider)`).
- Test: đủ 2 section label; user pro → 3 tile lẻ không còn nút Mua.
- Commit `feat(store): tach Goi Pro / Mua le + nhan "Da gom trong Pro"`.

### Task 8: SharedPlanScreen typed states

**Files:** `lib/features/plan/presentation/shared_plan_screen.dart`, l10n (`planSharedLoadError` "Không tải được kế hoạch" vi/en), test `test/features/plan/shared_plan_screen_test.dart`.

- Mirror SharedKeoScreen: `loading:` → `ListView(children: [SkeletonTile(), SkeletonTile()])`; `error:` → EmptyState wifi_off + commonRetry → `ref.invalidate(sharedPlanProvider(token))`; `data null` → giữ "Không tìm thấy kế hoạch".
- Test 3 nhánh (skeleton khi pending, retry gọi invalidate — đếm số lần provider chạy, not-found khi null).
- Commit `fix(plan): shared plan phan biet loi mang voi khong ton tai + retry`.

## Đợt 3 — Chuẩn hoá + a11y

### Task 9: Inventory + quét spinner/error trần

- [ ] `grep -rn "CircularProgressIndicator" lib/ --include=*.dart` — loại các chỗ trong nút đang-lưu (pattern hợp lệ); còn lại (loading cả màn/list) → Skeleton. `grep -rn "error: (" lib/` — nhánh nào chỉ Text lỗi không retry → EmptyState + Thử lại (invalidate provider tương ứng). Sửa từng màn một, test đi kèm mỗi màn (case: error → có nút Thử lại → provider refetch).
- [ ] Commit theo cụm màn: `fix(ux): chuan hoa loading/error <cum man> theo Skeleton+EmptyState`.

### Task 10: 4 lỗ accessibility

- `prompt_editor_sheet.dart:323`: IconButton xoá thêm `tooltip: l10n.promptDeleteTooltip` ("Xoá câu này"/"Remove this prompt").
- `photo_carousel.dart:206`: bọc 2 vùng chạm trái/phải bằng `Semantics(button: true, label: l10n.photoPrev/photoNext)`; thêm xử lý phím ← → qua `Focus`+`KeyboardListener` (chỉ khi carousel có focus).
- `datetime_format.dart`: thêm tham số `String? locale`, dùng `intl DateFormat.Hm(locale) + ' · ' + DateFormat.yMd(locale)`; caller truyền `Localizations.localeOf(context).toString()`; giữ hàm cũ làm fallback khi locale null. Test: vi → `1/8/2026`, en_US → `8/1/2026`.
- `app_vi.arb`: thay mọi `...` bằng `…` (grep xác nhận; app_en tương tự nếu có).
- Commit `fix(a11y): tooltip xoa prompt, semantics carousel, ngay theo locale, dau …`.

## Đợt 4 — Push primer

### Task 11: PushPrimerSheet + gate

**Files:**
- Create: `lib/core/push/push_primer.dart` (sheet + provider + pref `push_primer_choice`: 'on'/'later')
- Modify: `lib/core/push/push_registrar.dart` — `pushRegistrationProvider` chỉ auto-register khi pref == 'on'
- Modify: `lib/app/home_shell.dart` — sau frame đầu, nếu có hồ sơ && pref chưa set → show sheet 1 lần
- Modify: settings_screen — section Thông báo: tile "Bật thông báo" khi pref != 'on'
- Test: `test/core/push_primer_test.dart` + sửa `push_registrar_test.dart` (case: pref chưa set → KHÔNG requestPermission; pref 'on' → có)

Sheet: icon chuông, title `pushPrimerTitle` "Đừng lỡ kèo và match mới", 2 bullet, nút `pushPrimerAccept` "Bật thông báo" (→ set pref 'on' + `registerForSignedInUser()`), TextButton `pushPrimerLater` "Để sau" (→ pref 'later'). l10n vi+en đủ key.

- Commit `feat(push): man giai thich truoc khi xin quyen thong bao`.

### Task 12: Gates cuối + verify + tag

- [ ] analyze 0 · full Flutter test · vi/en parity (guard tự chạy trong suite) · build APK.
- [ ] Emulator: light + dark đi hết 4 tab, Store, Bộ lọc, chat, primer sheet lần đầu vào app. Screenshot đối chứng gửi user.
- [ ] Đề xuất merge master + tag `ui-upgrade-0801` (chờ user duyệt).

## Self-review đã chạy

- Spec coverage: Đợt 1→Task 1-4, Đợt 2→5-8, Đợt 3→9-10, Đợt 4→11; gallery states nằm ngoài phạm vi (ghi trong spec).
- Không placeholder: các bước sweep (Task 4/9) là bước grep-có-lệnh với tiêu chí quyết định rõ, kết quả cụ thể chốt lúc thực thi.
- Nhất quán tên: `AppPalette.light/dark`, `AppColors.select`, `themeModeControllerProvider`, `platformBrightnessProvider` dùng thống nhất các task.
