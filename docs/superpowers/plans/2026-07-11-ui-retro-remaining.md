# UI Retro — Phần còn lại (chat/profile/plan/store-settings) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn tất đợt re-skin "retro mixtape" cho 5 mảng Codex chưa đụng (inbox, profile tab, plan v1, store/settings sweep) theo bộ mockup đã chốt `docs/redesign-mockups/` + quyết định payments-v1.

**Architecture:** Chỉ sửa presentation layer (lib/app/home_shell.dart, lib/features/*/presentation/, lib/shared/widgets/) — tái dùng component retro đã có (`StampChip`, `TicketCard`, `WaveDivider`, `GradientButton`). Không đụng backend/RPC/models. Server-authoritative giữ nguyên.

**Tech Stack:** Flutter 3.44 / Riverpod 3.3 (manual providers) / theme tokens tại lib/core/theme/ (AppColors, AppSpacing, AppShadows). Test bằng flutter_test + mocktail, harness `test/support/supabase_mocks.dart`.

**Bối cảnh bắt buộc đọc trước khi làm bất kỳ task nào:**
- Nhánh `feat/ui-retro`, worktree `C:\Users\Hwang Ming Hung\cung-hat-ui-retro-wt`. Flutter chạy qua `C:\Users\Public\flutter\bin\flutter.bat` (đường dẫn home có space).
- Gates hiện tại: analyze 0 issue, **322 test pass** — mọi task kết thúc phải giữ 2 gates này.
- KHÔNG đổi/xoá bất kỳ `Key('...')` hiện có. KHÔNG thêm package. Copy chữ mới dùng literal tiếng Việt (nhất quán với inbox/settings hiện tại), KHÔNG cần .arb.
- Bẫy: nút trong Row phải `minimumSize Size(0,52)`; Riverpod 3.3 FutureProvider auto-retry `Exception` (test nhánh error phải `thenThrow(StateError(...))`).
- Mockup tham chiếu: `C:\Users\Hwang Ming Hung\cung-hat\docs\redesign-mockups\{15-inbox,18-profile,20-booking-payment,21-store,22-settings}.png` (repo gốc, worktree không có ảnh).

---

### Task 1: Inbox — tiêu đề section "Tin nhắn đôi" (mockup 15)

Mockup 15 có 2 section: "Kèo của bạn" (chat nhóm kèo) và "Tin nhắn đôi" (chat 1-1). Backend CHƯA có RPC `get_my_keos` để liệt kê kèo của user → **section "Kèo của bạn" DEFERRED (ghi vào verify doc), task này chỉ thêm tiêu đề section "Tin nhắn đôi"** ngay trên danh sách match, đúng vị trí theo mockup.

**Files:**
- Modify: `lib/features/chat/presentation/inbox_screen.dart` (khu vực `_InboxHeader`, itemBuilder index 0 tại dòng ~56)
- Test: `test/features/chat/presentation/inbox_screen_test.dart` (file test inbox hiện có — tìm bằng `Glob test/**/inbox*`; nếu tên khác thì thêm test case vào đúng file đó theo harness sẵn có của nó)

- [ ] **Step 1: Thêm test fail** — trong file test inbox hiện có, thêm case mới dùng đúng harness/override sẵn của file (inboxProvider + myProfileProvider đã được override ở các test cũ):

```dart
testWidgets('inbox hiện tiêu đề section Tin nhắn đôi khi có match', (tester) async {
  // Dùng đúng helper pump + overrides như các test hiện có trong file này
  // (inboxProvider trả 1 match, myProfileProvider trả profile giả).
  // Sau khi pump xong:
  expect(find.text('Tin nhắn đôi'), findsOneWidget);
});
```

- [ ] **Step 2: Chạy để thấy FAIL** — `flutter.bat test test/features/chat/ -r expanded` → case mới FAIL (không tìm thấy text).

- [ ] **Step 3: Implement** — trong `inbox_screen.dart`, tại `itemBuilder` index 0 (sau `_InboxHeader`), render thêm tiêu đề section. Sửa gọn: bọc header cũ vào Column:

```dart
if (index == 0) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      _InboxHeader(),
      Padding(
        padding: EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: _SectionLabel('Tin nhắn đôi'),
      ),
    ],
  );
}
```

và thêm widget nhỏ cuối file (style theo mockup — chữ rêu đậm, cỡ titleSmall):

```dart
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
```

- [ ] **Step 4: Chạy PASS** — `flutter.bat test test/features/chat/` → tất cả xanh.

- [ ] **Step 5: Commit** — `git add lib/features/chat/presentation/inbox_screen.dart test/features/chat/ && git commit -m "feat(chat): inbox section Tin nhan doi theo mockup 15"`

---

### Task 2: Profile tab — badge PRO cho "Ai đã thích bạn" (mockup 18)

**Files:**
- Modify: `lib/app/home_shell.dart` (`_ProfileTile` + call-site 'Ai đã thích bạn' dòng ~150)
- Test: `test/app/home_shell_test.dart` (đã có harness override provider — thêm expectation)

- [ ] **Step 1: Thêm test fail** — trong `home_shell_test.dart`, ở test đã pump tab Hồ sơ (hoặc thêm case mới dùng đúng harness đó):

```dart
testWidgets('dòng Ai đã thích bạn có badge PRO', (tester) async {
  // pump HomeShell bằng helper sẵn có của file, chuyển sang tab Hồ sơ
  // (tap find.text('Hồ sơ')), rồi:
  expect(
    find.widgetWithText(StampChip, 'PRO'),
    findsOneWidget,
  );
});
```

(import `package:cung_hat/shared/widgets/stamp_chip.dart` vào file test.)

- [ ] **Step 2: Chạy FAIL** — `flutter.bat test test/app/home_shell_test.dart` → case mới FAIL.

- [ ] **Step 3: Implement** — trong `home_shell.dart`:
  1. Import `../shared/widgets/stamp_chip.dart` (chỉnh relative path theo vị trí file: `import '../shared/widgets/stamp_chip.dart';`).
  2. `_ProfileTile` thêm param optional:

```dart
final String? badgeLabel; // constructor: this.badgeLabel,
```

  3. Trong build của `_ProfileTile`, chỗ render title (Text(title)) đổi thành Row:

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
    if (badgeLabel != null) ...[
      const SizedBox(width: AppSpacing.sm),
      StampChip(label: badgeLabel!),
    ],
  ],
),
```

  4. Call-site 'Ai đã thích bạn' thêm `badgeLabel: 'PRO',`.

- [ ] **Step 4: Chạy PASS** — `flutter.bat test test/app/home_shell_test.dart` → xanh hết.

- [ ] **Step 5: Commit** — `git commit -m "feat(profile): badge PRO cho dong Ai da thich ban theo mockup 18"`

---

### Task 3: Plan v1 — flag BOOKING_ENABLED + nút "Chỉ đường" (mockup 20 + quyết định payments-v1)

Theo `docs/superpowers/specs/2026-07-10-payments-v1-decision.md` (repo gốc): màn Kế hoạch v1 KHÔNG hiện UI thanh toán; BookingButton giấu sau flag; thay bằng "Chỉ đường" + giữ SafetyToolkit (đã có nút chia sẻ). KHÔNG xoá code BookingButton.

**Files:**
- Modify: `lib/features/plan/presentation/plan_screen.dart` (nhánh `plan.status == 'confirmed'` dòng ~165-169, helper `_venueName` dòng ~133)
- Test: Create `test/features/plan/presentation/plan_screen_v1_test.dart` (file mới, tự chứa)

- [ ] **Step 1: Viết test fail** — file mới, override provider theo pattern repo (xem file test plan hiện có trong `test/features/plan/` để lấy đúng tên providers; `currentPlanProvider` là family theo keoId, `nearestVenuesProvider` family):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/plan/presentation/plan_screen.dart';
// + import providers/domain theo file test plan sẵn có

void main() {
  testWidgets('plan confirmed (flag off): co Chi duong, khong co Dat phong', (tester) async {
    // Override: currentPlanProvider(keoId) -> Plan(status: 'confirmed', venueId: 'v1', ...)
    //           nearestVenuesProvider(keoId) -> [VenueSuggestion(id:'v1', name:'Music Box Thủ Đức', address:'120 Võ Văn Ngân', ...)]
    // Pump PlanScreen(keoId: ...) trong ProviderScope + MaterialApp như test plan sẵn có.
    expect(find.text('Chỉ đường'), findsOneWidget);
    expect(find.textContaining('Đặt phòng'), findsNothing);
    expect(find.byKey(const Key('directions_btn')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy FAIL** — `flutter.bat test test/features/plan/presentation/plan_screen_v1_test.dart` → FAIL.

- [ ] **Step 3: Implement** — trong `plan_screen.dart`:
  1. Đầu file thêm hằng + import:

```dart
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/gradient_button.dart';

/// Cổng đặt cọc chỉ bật khi build với --dart-define=BOOKING_ENABLED=true
/// (quyết định payments-v1 2026-07-10: v1 không thanh toán).
const bookingEnabled = bool.fromEnvironment('BOOKING_ENABLED');
```

  2. Thêm helper cạnh `_venueName`:

```dart
String _venueAddress(List<VenueSuggestion> venues, String? venueId) {
  for (final v in venues) {
    if (v.id == venueId) return v.address;
  }
  return '';
}
```

  3. Nhánh confirmed (dòng ~165) đổi thành:

```dart
else ...[
  if (bookingEnabled) ...[
    BookingButton(planId: plan.id, venueId: plan.venueId),
    const SizedBox(height: 12),
  ],
  GradientButton(
    key: const Key('directions_btn'),
    icon: Icons.place_rounded,
    onPressed: () async {
      final query = Uri.encodeComponent(
        '$name ${_venueAddress(venues, plan.venueId)}'.trim(),
      );
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) _snack(context, 'Không mở được bản đồ');
      }
    },
    child: const Text('Chỉ đường'),
  ),
  const SizedBox(height: 12),
  SafetyToolkit(planId: plan.id),
],
```

(GradientButton signature: `{onPressed, child, icon, height, gradient}` — icon là IconData. KHÔNG xoá import BookingButton.)

- [ ] **Step 4: Chạy PASS** — file test mới + `flutter.bat test test/features/plan/` xanh hết.

- [ ] **Step 5: Commit** — `git commit -m "feat(plan): v1 khong thanh toan - flag BOOKING_ENABLED + nut Chi duong (mockup 20)"`

---

### Task 4: Store/Settings sweep màu cũ + đồng bộ design-system/MASTER.md

**Files:**
- Modify (nếu còn màu hardcode lệch token): `lib/features/billing/presentation/store_screen.dart`, `lib/features/settings/presentation/settings_screen.dart`
- Modify: `design-system/MASTER.md`

- [ ] **Step 1: Sweep** — `grep -n "Color(0x" lib/features/billing/ lib/features/settings/ -r` và `grep -rn "colorScheme\.\|Colors\.[a-z]" lib/features/billing/presentation/store_screen.dart lib/features/settings/presentation/settings_screen.dart`. Mọi màu hardcode không thuộc AppColors → thay bằng token gần nghĩa nhất (nền `AppColors.surface`, chữ `AppColors.ink`, nhấn `AppColors.primary`, cảnh báo giữ `AppColors.error`). Nếu grep ra 0 kết quả lệch → ghi nhận "đã sạch", bỏ qua Step này không sửa gì.

- [ ] **Step 2: Chạy test liên quan** — `flutter.bat test test/features/billing/ test/features/settings/` (nếu folder test tồn tại; không có thì chạy full suite) → xanh.

- [ ] **Step 3: Cập nhật `design-system/MASTER.md`** — thay section palette/typography cũ (coral/Be Vietnam Pro) bằng bảng token retro hiện hành, ngắn gọn:

```markdown
## Design tokens (retro mixtape — 2026-07-11)
| Token | Giá trị | Dùng cho |
|---|---|---|
| background | #F7EFD8 | nền app (giấy kem) |
| surface | #FCF6E3 | card/sheet |
| ink | #1E3A2F | chữ, viền 2px, icon |
| primary | #E8501F | CTA cam (chữ trắng ≥16 bold) |
| secondary | #C6E534 | lime nhấn/badge |
| teal | #8FD8C8 | chip nhạc/trạng thái |
| radius | 14 (pill 999 chỉ cho chip tròn cũ) | nút/card/input |
| shadow | offset(3,3) blur 0 ink 20% | AppShadows.hard |
Typography: display Oswald (headline/title, VN đủ dấu, bundle offline) · body Be Vietnam Pro.
Component chuẩn: GradientButton (CTA), TicketCard (kèo/vé), StampChip (badge/trạng thái), WaveDivider (ngăn section).
Nguồn chuẩn: docs/redesign-mockups/ (22 ảnh, bản 2026-07-11).
```

- [ ] **Step 4: Commit** — `git add -A && git commit -m "chore(ui): sweep mau cu store/settings + dong bo MASTER.md token retro"`

---

### Task 5: Final verify — gates + emulator + verify doc

- [ ] **Step 1: Gates** — `flutter.bat analyze` (0 issue) + `flutter.bat test` (100% pass, ≥322).

- [ ] **Step 2: Build + cài emulator** — copy env nếu thiếu (`cp ../cung-hat/env/*.json env/`), rồi:

```bash
export JAVA_TOOL_OPTIONS="-Djdk.net.unixdomain.tmpdir=C:/nonexistent/<120 ky tu a>"
flutter.bat build apk --debug --dart-define-from-file=env/dev.emulator.json
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

(Emulator `cunghat_test3`; Supabase local phải chạy; login 900000001/123456.)

- [ ] **Step 3: Walkthrough chụp màn** — Đôi (deck card + 4 nút có nhãn) · Kèo board (TicketCard) · Tạo kèo · Chat inbox ("Tin nhắn đôi") · chat 1-1 · Hồ sơ (badge PRO) · Store · Settings. So với mockup tương ứng, ghi lệch còn lại.

- [ ] **Step 4: Verify doc** — tạo `docs/verify-ui-retro-2026-07-11.md`: bảng kết quả từng màn PASS/lệch, mục DEFERRED (tối thiểu: section "Kèo của bạn" inbox chờ RPC get_my_keos; hard shadow chưa áp cho mọi component Material), gates cuối, danh sách screenshot.

- [ ] **Step 5: Commit** — `git add docs/ && git commit -m "docs: verify ui-retro dot cuoi + deferred"` — rồi DỪNG chờ user quyết merge/push.

---

## Self-review đã chạy
- Spec coverage: mockup 15→T1, 18→T2, 20+payments-v1→T3, 21/22→T4, verify→T5. Mockup 01-14 đã do 21 commit Codex phủ (kiểm ở T5 walkthrough). Gap ghi rõ: "Kèo của bạn" (backend thiếu) — DEFERRED có chủ đích.
- Placeholder scan: các bước test T1/T2 dựa harness sẵn có của file test đích (chỉ thị cụ thể + assertion đầy đủ) — chấp nhận vì file harness đã tồn tại và implementer đọc được; code implement đầy đủ không TBD.
- Type consistency: StampChip(label:) đúng signature đã đọc; GradientButton(icon: IconData) đúng; VenueSuggestion.address tồn tại (đã đọc domain file); `bookingEnabled` const dùng nhất quán T3.
