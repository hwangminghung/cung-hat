# Đôi Tab Tinder-Quality Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nâng trải nghiệm tab Đôi lên chất lượng Tinder — overlay THÍCH/BỎ QUA theo ngón tay, action bar + rewind (Pro), sheet chi tiết ứng viên, match celebration có animation + đi thẳng vào chat, quota like/super-like kiểu Tinder map vào hệ Pro entitlements sẵn có — **giữ nguyên design system Cùng Hát (MASTER.md)**, không sao chép asset/brand Tinder.

**Architecture:** Tận dụng tối đa hạ tầng có sẵn: `flutter_card_swiper` 7.2.0 đã render deck và cấp `horizontalOffsetPercentage/verticalOffsetPercentage` cho cardBuilder (nguồn duy nhất cho overlay opacity — không thêm gesture detector riêng); backend đã có `direction='super'` trong `swipes` CHECK (0008), `record_swipe` xử lý super như like (0009), `app_private.is_pro()` + `enforce_rate_limit` (0024/0007). Một migration mới duy nhất thêm quota + `undo_last_swipe` + `get_match_id_with` + ưu tiên super-liker trong ranking. Mọi gate đều server-authoritative; client chỉ hiển thị.

**Tech Stack:** Flutter 3.44 / Riverpod 3.3.2 (manual providers) / flutter_card_swiper 7.2.0 / Supabase (plpgsql SECURITY DEFINER, search_path='', pgTAP) / mocktail + `test/support/supabase_mocks.dart` (`rpcOk`).

**Điều KHÔNG làm trong plan này (chốt khi brainstorm):**
- **Boost** — cần semantics consumable-IAP (P6 receipt validation còn placeholder) + rework ranking riêng → plan kế tiếp.
- **Multi-photo carousel** — photos upload (P1.5) chưa build; `CandidateDetailSheet` thiết kế quanh dữ liệu hiện có (monogram + taste), carousel sẽ ghép vào khi có photos.
- Không dùng logo/asset/tên gọi của Tinder; chữ overlay là tiếng Việt, màu theo AppColors.

**Quy ước chạy lệnh (Windows, path có dấu cách):** flutter = `flutter` (PATH ok); build APK cần `$env:JAVA_TOOL_OPTIONS = "-Djdk.net.unixdomain.tmpdir=C:\nonexistent\" + ("a"*120)`; psql = `docker exec supabase_db_cung-hat psql -U postgres -d postgres`; **nạp file SQL tiếng Việt LUÔN qua `docker cp` + `psql -f`, KHÔNG pipe PowerShell** (mojibake).

---

## File Structure

```
lib/features/discovery/
  presentation/
    swipe_overlays.dart          # MỚI — stamp THÍCH/BỎ QUA/SIÊU THÍCH, opacity theo tiến độ kéo
    deck_action_bar.dart         # MỚI — hàng nút rewind/pass/super/like (chỉ callback, không Supabase)
    candidate_detail_sheet.dart  # MỚI — bottom sheet chi tiết ứng viên
    doi_deck_screen.dart         # SỬA — wire overlays, action bar, detail sheet, rewind, error→paywall
    match_celebration.dart       # VIẾT LẠI — animation vào + confetti + nút Nhắn tin ngay
    candidate_card.dart          # GIỮ NGUYÊN (overlay bọc ngoài, không đụng card)
  data/
    discovery_repository.dart    # SỬA — thêm undoLastSwipe(), getMatchIdWith()
    discovery_errors.dart        # MỚI — map errcode server → copy VI (như keo_errors.dart)
lib/shared/widgets/
  pro_upsell_sheet.dart          # MỚI — trích từ _showProSheet của keo_board (DRY, dùng chung)
lib/features/keo/presentation/
  keo_board_screen.dart          # SỬA — dùng ProUpsellSheet chung
supabase/migrations/
  20260703100000_doi_swipe_upgrade.sql   # MỚI — quota like/super, undo_last_swipe, get_match_id_with, super-liker priority
supabase/tests/
  doi_swipe_upgrade_test.sql     # MỚI — pgTAP
test/features/discovery/
  swipe_overlays_test.dart       # MỚI
  deck_action_bar_test.dart      # MỚI
  candidate_detail_sheet_test.dart # MỚI
  discovery_errors_test.dart     # MỚI
  match_celebration_test.dart    # SỬA — key/label mới
```

---

### Task 1: SwipeOverlays — stamp theo tiến độ kéo

Cơ chế Tinder: khi kéo card, chữ "THÍCH" (kéo phải) / "BỎ QUA" (kéo trái) / "SIÊU THÍCH" (kéo lên) hiện dần theo khoảng kéo. `CardSwiper.cardBuilder` cấp `horizontalOffsetPercentage`/`verticalOffsetPercentage` (int, -100..100, đạt ±100 tại ngưỡng swipe) — chia 100 là có progress. Card cũng đã tự xoay theo ngón tay (`maxAngle` mặc định 30°).

**Files:**
- Create: `lib/features/discovery/presentation/swipe_overlays.dart`
- Test: `test/features/discovery/swipe_overlays_test.dart`
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart` (cardBuilder)

- [ ] **Step 1: Viết test fail**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/presentation/swipe_overlays.dart';

void main() {
  Future<void> pump(WidgetTester t, double h, double v) => t.pumpWidget(
        MaterialApp(
          home: SwipeOverlays(
            hProgress: h,
            vProgress: v,
            child: const SizedBox(width: 300, height: 400),
          ),
        ),
      );

  double opacityOf(WidgetTester t, Key key) =>
      t.widget<Opacity>(find.byKey(key)).opacity;

  testWidgets('kéo phải hiện THÍCH theo tiến độ, không hiện BỎ QUA',
      (tester) async {
    await pump(tester, 0.6, 0);
    expect(opacityOf(tester, const Key('overlay_like')), closeTo(0.6, 0.01));
    expect(opacityOf(tester, const Key('overlay_nope')), 0);
    expect(find.text('THÍCH'), findsOneWidget);
  });

  testWidgets('kéo trái hiện BỎ QUA', (tester) async {
    await pump(tester, -0.8, 0);
    expect(opacityOf(tester, const Key('overlay_nope')), closeTo(0.8, 0.01));
    expect(opacityOf(tester, const Key('overlay_like')), 0);
  });

  testWidgets('kéo lên hiện SIÊU THÍCH, bị triệt khi kéo ngang mạnh',
      (tester) async {
    await pump(tester, 0, -0.7);
    expect(opacityOf(tester, const Key('overlay_super')), closeTo(0.7, 0.01));
    await pump(tester, -0.9, -0.7);
    expect(opacityOf(tester, const Key('overlay_super')), lessThan(0.1));
  });

  testWidgets('progress ngoài [-1,1] bị clamp', (tester) async {
    await pump(tester, 1.4, 0);
    expect(opacityOf(tester, const Key('overlay_like')), 1.0);
  });
}
```

- [ ] **Step 2: Chạy test — phải FAIL** (`flutter test test/features/discovery/swipe_overlays_test.dart` → lỗi compile: file chưa tồn tại)

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Bọc ngoài CandidateCard trong CardSwiper.cardBuilder. Stamp mờ dần theo
/// tiến độ kéo — đúng cơ chế deck app hẹn hò: người dùng thấy trước hệ quả
/// của cú vuốt đang thực hiện.
class SwipeOverlays extends StatelessWidget {
  const SwipeOverlays({
    super.key,
    required this.hProgress, // -1..1, dương = kéo phải (thích)
    required this.vProgress, // -1..1, âm = kéo lên (siêu thích)
    required this.child,
  });

  final double hProgress;
  final double vProgress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final like = hProgress.clamp(0.0, 1.0);
    final nope = (-hProgress).clamp(0.0, 1.0);
    // Kéo chéo: ưu tiên hướng ngang — siêu thích chỉ rõ khi kéo thẳng lên.
    final superLike =
        ((-vProgress).clamp(0.0, 1.0) * (1 - hProgress.abs()).clamp(0.0, 1.0));

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        _Stamp(
          key: const Key('overlay_like'),
          label: 'THÍCH',
          color: AppColors.success,
          opacity: like,
          alignment: Alignment.topLeft,
          angle: -0.25,
        ),
        _Stamp(
          key: const Key('overlay_nope'),
          label: 'BỎ QUA',
          color: AppColors.error,
          opacity: nope,
          alignment: Alignment.topRight,
          angle: 0.25,
        ),
        _Stamp(
          key: const Key('overlay_super'),
          label: 'SIÊU THÍCH',
          color: AppColors.tertiary,
          opacity: superLike,
          alignment: Alignment.bottomCenter,
          angle: -0.12,
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    super.key,
    required this.label,
    required this.color,
    required this.opacity,
    required this.alignment,
    required this.angle,
  });

  final String label;
  final Color color;
  final double opacity;
  final Alignment alignment;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Transform.rotate(
              angle: angle,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: AppTypography.display(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Chạy test — PASS** (4/4)

- [ ] **Step 5: Wire vào deck.** Trong `doi_deck_screen.dart` sửa cardBuilder (hiện tại bỏ qua `h, v`):

```dart
cardBuilder: (context, index, h, v) => SwipeOverlays(
  hProgress: h / 100,
  vProgress: v / 100,
  child: CandidateCard(candidate: candidates[index]),
),
```
Thêm import `swipe_overlays.dart`. Đồng thời thêm 2 tham số cho CardSwiper (cùng chỗ `isLoop: false`): `maxAngle: 25,` và `threshold: 60,` (xoay dịu hơn mặc định, ngưỡng nhả xa hơn chút cho cảm giác chắc tay).

- [ ] **Step 6: `flutter analyze` sạch + toàn bộ `flutter test` xanh, rồi commit**

```bash
git add lib/features/discovery/presentation/swipe_overlays.dart test/features/discovery/swipe_overlays_test.dart lib/features/discovery/presentation/doi_deck_screen.dart
git commit -m "feat(doi): swipe stamps THICH/BO QUA/SIEU THICH theo tien do keo"
```

---

### Task 2: DeckActionBar — nút rewind / pass / super / like

Widget thuần callback (không Supabase) để test dễ. Nút to nhỏ xen kẽ như chuẩn deck dating: pass + like to, rewind + super nhỏ. Haptics khi bấm.

**Files:**
- Create: `lib/features/discovery/presentation/deck_action_bar.dart`
- Test: `test/features/discovery/deck_action_bar_test.dart`
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart`

- [ ] **Step 1: Test fail**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/presentation/deck_action_bar.dart';

void main() {
  testWidgets('4 nút gọi đúng callback', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeckActionBar(
          rewindEnabled: true,
          onRewind: () => calls.add('rewind'),
          onPass: () => calls.add('pass'),
          onSuperLike: () => calls.add('super'),
          onLike: () => calls.add('like'),
        ),
      ),
    ));
    for (final k in ['rewind', 'pass', 'super', 'like']) {
      await tester.tap(find.byKey(Key('deck_${k}_btn')));
    }
    expect(calls, ['rewind', 'pass', 'super', 'like']);
  });

  testWidgets('rewindEnabled=false vẫn bấm được (để hiện upsell) nhưng mờ',
      (tester) async {
    var rewound = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeckActionBar(
          rewindEnabled: false,
          onRewind: () => rewound = true,
          onPass: () {},
          onSuperLike: () {},
          onLike: () {},
        ),
      ),
    ));
    // Nút vẫn nhận tap: free user bấm → caller mở Pro upsell.
    await tester.tap(find.byKey(const Key('deck_rewind_btn')));
    expect(rewound, isTrue);
    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.byKey(const Key('deck_rewind_btn')),
        matching: find.byType(Opacity),
      ).first,
    );
    expect(opacity.opacity, lessThan(1));
  });
}
```

- [ ] **Step 2: Chạy — FAIL** (file chưa có)

- [ ] **Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// Hàng nút hành động dưới deck. Thuần UI — mọi logic (gate Pro, quota,
/// controller.swipe) do DoiDeckScreen quyết định qua callback.
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({
    super.key,
    required this.onRewind,
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    required this.rewindEnabled,
  });

  final VoidCallback onRewind;
  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;

  /// false = user free: nút vẫn tap được nhưng mờ; caller mở Pro upsell.
  final bool rewindEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Opacity(
          opacity: rewindEnabled ? 1 : 0.45,
          child: _RoundButton(
            key: const Key('deck_rewind_btn'),
            icon: Icons.replay_rounded,
            color: AppColors.warning,
            size: 48,
            onTap: onRewind,
          ),
        ),
        _RoundButton(
          key: const Key('deck_pass_btn'),
          icon: Icons.close_rounded,
          color: AppColors.error,
          size: 62,
          onTap: onPass,
        ),
        _RoundButton(
          key: const Key('deck_super_btn'),
          icon: Icons.star_rounded,
          color: AppColors.tertiary,
          size: 48,
          onTap: onSuperLike,
        ),
        _RoundButton(
          key: const Key('deck_like_btn'),
          icon: Icons.favorite_rounded,
          color: AppColors.success,
          size: 62,
          onTap: onLike,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: CircleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      elevation: 2,
      shadowColor: AppColors.shadow.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, color: color, size: size * 0.5),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Chạy test — PASS**

- [ ] **Step 5: Wire vào deck.** Trong `_DoiDeckScreenState`: thêm field `final _controller = CardSwiperController();` (+ `_controller.dispose()` trong dispose; import từ flutter_card_swiper). Truyền `controller: _controller` vào CardSwiper. Dưới `Expanded(child: ... CardSwiper)` trong Column, thêm:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(
    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
  ),
  child: DeckActionBar(
    rewindEnabled: ref.watch(isProProvider).value ?? false,
    onRewind: _handleRewind, // Task 5 — tạm thời: () {}
    onPass: () => _controller.swipe(CardSwiperDirection.left),
    onSuperLike: () => _controller.swipe(CardSwiperDirection.top),
    onLike: () => _controller.swipe(CardSwiperDirection.right),
  ),
),
```
`isProProvider` import từ `../../billing/application/billing_providers.dart` (đã tồn tại từ nhánh pro-keo-gating). Bước này tạm để `onRewind: () {}` — Task 5 thay bằng `_handleRewind`.

- [ ] **Step 6: analyze + full test + commit** (`feat(doi): action bar rewind/pass/super/like dieu khien deck`)

---

### Task 3: Migration — quota like/super, undo_last_swipe, get_match_id_with, super-liker priority

Server-authoritative: quota + Pro gate nằm ở DB. Free: 30 like/ngày, 1 super/ngày; Pro: like không giới hạn, 5 super/ngày; rewind chỉ Pro. Super-liker được đẩy lên đầu deck của người nhận + reason `super_liked_you`.

**Files:**
- Create: `supabase/migrations/20260703100000_doi_swipe_upgrade.sql`
- Test: `supabase/tests/doi_swipe_upgrade_test.sql`

- [ ] **Step 1: Viết migration.** Nội dung file (lưu UTF-8, nạp qua docker cp — KHÔNG pipe PowerShell):

```sql
-- Đôi swipe upgrade: quota kiểu dating-app + rewind Pro + match id cho chat.

-- 1) record_swipe: thêm quota. Copy nguyên body từ 0009 + chèn khối quota
--    NGAY SAU dòng "perform app_private.enforce_rate_limit('swipe', 200, interval '1 day');"
create or replace function public.record_swipe(p_target uuid, p_direction text)
returns boolean language plpgsql security definer set search_path='' as $$
declare a uuid; b uuid; reciprocal boolean; matched boolean := false;
begin
  perform app_private.enforce_rate_limit('swipe', 200, interval '1 day');

  -- Quota kiểu dating-app (server-authoritative, Pro qua app_private.is_pro()):
  if p_direction = 'like' and not app_private.is_pro() then
    begin
      perform app_private.enforce_rate_limit('daily_like', 30, interval '1 day');
    exception when sqlstate '23514' then
      raise exception 'like_limit' using errcode='check_violation';
    end;
  end if;
  if p_direction = 'super' then
    begin
      perform app_private.enforce_rate_limit(
        'daily_super',
        case when app_private.is_pro() then 5 else 1 end,
        interval '1 day');
    exception when sqlstate '23514' then
      raise exception 'super_limit' using errcode='check_violation';
    end;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      least(auth.uid(), p_target)::text || ':' || greatest(auth.uid(), p_target)::text, 0));
  insert into public.swipes(swiper_id, target_type, target_id, direction)
  values (auth.uid(), 'user', p_target::text, p_direction)
  on conflict (swiper_id, target_type, target_id) do nothing;

  if p_direction in ('like','super') then
    select exists(
      select 1 from public.swipes s
      where s.swiper_id = p_target and s.target_type='user'
        and s.target_id = auth.uid()::text and s.direction in ('like','super')
    ) into reciprocal;
    if reciprocal then
      a := least(auth.uid(), p_target); b := greatest(auth.uid(), p_target);
      insert into public.matches(user_a, user_b) values (a, b)
      on conflict (user_a, user_b) do nothing;
      matched := true;
    end if;
  end if;
  return matched;
end; $$;

-- 2) Rewind (Pro): xoá lượt vuốt gần nhất nếu nó CHƯA tạo match.
create or replace function public.undo_last_swipe()
returns boolean language plpgsql security definer set search_path='' as $$
declare last_target text; last_created timestamptz;
begin
  if not app_private.is_pro() then
    raise exception 'pro_required' using errcode='check_violation';
  end if;
  select s.target_id, s.created_at into last_target, last_created
  from public.swipes s
  where s.swiper_id = auth.uid() and s.target_type = 'user'
  order by s.created_at desc limit 1;
  if last_target is null then
    return false;
  end if;
  if exists (
    select 1 from public.matches m
    where m.status = 'active'
      and m.user_a = least(auth.uid(), last_target::uuid)
      and m.user_b = greatest(auth.uid(), last_target::uuid)
  ) then
    return false; -- đã match thì không rút lại được
  end if;
  delete from public.swipes s
  where s.swiper_id = auth.uid() and s.target_type = 'user'
    and s.target_id = last_target;
  return true;
end; $$;
revoke execute on function public.undo_last_swipe() from public, anon;
grant execute on function public.undo_last_swipe() to authenticated;

-- 3) Lấy match id với một người (mở chat ngay từ match celebration).
create or replace function public.get_match_id_with(p_other uuid)
returns uuid language sql security definer set search_path='' as $$
  select m.id from public.matches m
  where m.status = 'active'
    and m.user_a = least(auth.uid(), p_other)
    and m.user_b = greatest(auth.uid(), p_other)
  limit 1;
$$;
revoke execute on function public.get_match_id_with(uuid) from public, anon;
grant execute on function public.get_match_id_with(uuid) to authenticated;
```

- [ ] **Step 2: Super-liker priority.** Mở `supabase/migrations/0008_discovery.sql`, copy NGUYÊN VĂN `create or replace function public.get_discovery_candidates(...)` (toàn bộ body) dán vào CUỐI migration mới, rồi áp đúng 2 chỉnh sửa sau (không đổi gì khác):
  1. Trong biểu thức score, thêm term (cùng vị trí các term `+ case ...` khác):
     ```sql
     + case when exists (
         select 1 from public.swipes ss
         where ss.swiper_id = c.id and ss.target_type = 'user'
           and ss.target_id = auth.uid()::text and ss.direction = 'super'
       ) then 5.0 else 0 end
     ```
     (`c` = alias của bảng profiles/candidate trong function 0008 — dùng đúng alias thực tế trong file.)
  2. Trong mảng reason_labels, thêm phần tử:
     ```sql
     case when exists (
       select 1 from public.swipes ss
       where ss.swiper_id = c.id and ss.target_type = 'user'
         and ss.target_id = auth.uid()::text and ss.direction = 'super'
     ) then 'super_liked_you'::text end,
     ```
  Nếu 0008 KHÔNG có cột reason_labels trong composite `discovery_candidate` thì BỎ QUA chỉnh sửa (2) — chỉ áp (1); không được đổi composite type (vỡ RLS/grants cũ).

- [ ] **Step 3: Viết pgTAP test** `supabase/tests/doi_swipe_upgrade_test.sql` (theo pattern các test cũ: seed auth.users + profiles as postgres, fake uid qua `set local request.jwt.claims`; SQLSTATE trong throws_ok phải là `'23514'`):

```sql
begin;
select plan(7);

-- Seed: F (free), P (pro), T (target). age_verified=true để qua các gate.
insert into auth.users (id, aud, role, email) values
  ('f0000000-0000-4000-8000-000000000001','authenticated','authenticated','f@t.vn'),
  ('f0000000-0000-4000-8000-000000000002','authenticated','authenticated','p@t.vn'),
  ('f0000000-0000-4000-8000-000000000003','authenticated','authenticated','t@t.vn');
insert into public.profiles (id, display_name, age_verified) values
  ('f0000000-0000-4000-8000-000000000001','Free',true),
  ('f0000000-0000-4000-8000-000000000002','Pro',true),
  ('f0000000-0000-4000-8000-000000000003','Target',true);
insert into public.entitlements (user_id, feature) values
  ('f0000000-0000-4000-8000-000000000002','pro');

-- 1) Free đã dùng 30 like hôm nay → like thứ 31 bị chặn 'like_limit'
set local request.jwt.claims to '{"sub":"f0000000-0000-4000-8000-000000000001","role":"authenticated"}';
insert into public.rate_limits (user_id, action, created_at)
  select 'f0000000-0000-4000-8000-000000000001','daily_like', now()
  from generate_series(1,30);
select throws_ok(
  $$select public.record_swipe('f0000000-0000-4000-8000-000000000003','like')$$,
  '23514', null, 'free het 30 like/ngay bi chan');

-- 2) Free vẫn pass được khi hết like
select lives_ok(
  $$select public.record_swipe('f0000000-0000-4000-8000-000000000003','pass')$$,
  'pass khong tinh vao quota like');

-- 3) Free super thứ 2 trong ngày bị chặn
insert into public.rate_limits (user_id, action, created_at)
  values ('f0000000-0000-4000-8000-000000000001','daily_super', now());
select throws_ok(
  $$select public.record_swipe('f0000000-0000-4000-8000-000000000003','super')$$,
  '23514', null, 'free chi 1 super/ngay');

-- 4) Pro không dính quota like (seed 30 daily_like rồi vẫn like được)
set local request.jwt.claims to '{"sub":"f0000000-0000-4000-8000-000000000002","role":"authenticated"}';
insert into public.rate_limits (user_id, action, created_at)
  select 'f0000000-0000-4000-8000-000000000002','daily_like', now()
  from generate_series(1,30);
select lives_ok(
  $$select public.record_swipe('f0000000-0000-4000-8000-000000000003','like')$$,
  'pro like khong gioi han');

-- 5) Rewind: free bị chặn pro_required
set local request.jwt.claims to '{"sub":"f0000000-0000-4000-8000-000000000001","role":"authenticated"}';
select throws_ok(
  $$select public.undo_last_swipe()$$,
  '23514', null, 'rewind can Pro');

-- 6) Rewind Pro xoá lượt vuốt vừa rồi
set local request.jwt.claims to '{"sub":"f0000000-0000-4000-8000-000000000002","role":"authenticated"}';
select ok(public.undo_last_swipe(), 'pro rewind tra ve true');
select is(
  (select count(*)::int from public.swipes
   where swiper_id='f0000000-0000-4000-8000-000000000002'),
  0, 'swipe da bi xoa');

select * from finish();
rollback;
```
LƯU Ý: nếu bảng `rate_limits` có schema khác (xem 0007 — cột có thể là `occurred_at` thay vì `created_at`, hoặc nằm trong schema `app_private`), sửa INSERT seed cho đúng schema thực tế TRƯỚC khi chạy; logic test giữ nguyên.

- [ ] **Step 4: Apply + chạy pgTAP**

```powershell
cd 'C:\Users\Hwang Ming Hung\cung-hat'
supabase migration up          # hoặc: supabase db reset (rồi nạp lại seed qua docker cp!)
supabase test db
```
Expected: file mới ok (7 test), các file cũ vẫn ok. (Nhớ `chat_media_test.sql.pending` không chạy — đúng chủ đích.)

- [ ] **Step 5: Nếu `supabase db reset`: nạp lại seed đúng cách**

```powershell
docker cp scripts/seed_launch.sql supabase_db_cung-hat:/tmp/seed_launch.sql
docker exec -e PGCLIENTENCODING=UTF8 supabase_db_cung-hat psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f /tmp/seed_launch.sql
```

- [ ] **Step 6: Commit** (`feat(doi-db): quota like/super theo Pro, undo_last_swipe, get_match_id_with, uu tien super-liker`)

---

### Task 4: discovery_errors + ProUpsellSheet dùng chung + xử lý lỗi ở deck

**Files:**
- Create: `lib/features/discovery/data/discovery_errors.dart`
- Create: `lib/shared/widgets/pro_upsell_sheet.dart`
- Modify: `lib/features/keo/presentation/keo_board_screen.dart` (thay `_showProSheet` nội bộ bằng widget chung)
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart` (catchError phân loại)
- Test: `test/features/discovery/discovery_errors_test.dart`

- [ ] **Step 1: Test fail cho mapper**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/data/discovery_errors.dart';

void main() {
  test('map các mã lỗi swipe sang copy VI', () {
    expect(discoverySwipeError(Exception('like_limit x')),
        DiscoverySwipeError.likeLimit);
    expect(discoverySwipeError(Exception('super_limit')),
        DiscoverySwipeError.superLimit);
    expect(discoverySwipeError(Exception('pro_required')),
        DiscoverySwipeError.proRequired);
    expect(discoverySwipeError(Exception('boom')),
        DiscoverySwipeError.unknown);
    expect(DiscoverySwipeError.likeLimit.message, contains('lượt thích'));
  });
}
```

- [ ] **Step 2: Chạy — FAIL. Step 3: Implement**

```dart
/// Phân loại lỗi record_swipe/undo_last_swipe từ server (message chứa mã lỗi
/// do plpgsql raise — cùng pattern keo_errors.dart).
enum DiscoverySwipeError {
  likeLimit('Bạn đã hết lượt thích hôm nay. Nâng cấp Pro để thích không giới hạn.'),
  superLimit('Bạn đã hết lượt Siêu thích hôm nay.'),
  proRequired('Tính năng này dành cho thành viên Pro.'),
  unknown('Không lưu được lượt vuốt. Thử lại sau.');

  const DiscoverySwipeError(this.message);
  final String message;
}

DiscoverySwipeError discoverySwipeError(Object e) {
  final s = e.toString();
  if (s.contains('like_limit')) return DiscoverySwipeError.likeLimit;
  if (s.contains('super_limit')) return DiscoverySwipeError.superLimit;
  if (s.contains('pro_required')) return DiscoverySwipeError.proRequired;
  return DiscoverySwipeError.unknown;
}
```

- [ ] **Step 4: Test PASS. Step 5: Trích ProUpsellSheet.** Mở `keo_board_screen.dart`, tìm hàm `_showProSheet` (sheet nâng cấp Pro hiện có). Chuyển phần UI sheet thành widget chung:

```dart
// lib/shared/widgets/pro_upsell_sheet.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Bottom sheet mời nâng cấp Pro — dùng chung cho gate ở Kèo và Đôi.
class ProUpsellSheet extends StatelessWidget {
  const ProUpsellSheet({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  static Future<void> show(BuildContext context,
      {required String title, required String subtitle}) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => ProUpsellSheet(title: title, subtitle: subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.workspace_premium_rounded,
                size: 44, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              key: const Key('pro_upsell_cta'),
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/store');
              },
              child: const Text('Nâng cấp Pro'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Để sau'),
            ),
          ],
        ),
      ),
    );
  }
}
```
Trong `keo_board_screen.dart`: thay body của `_showProSheet(context)` bằng `ProUpsellSheet.show(context, title: <giữ title cũ>, subtitle: <giữ subtitle cũ>)` — giữ nguyên copy chữ hiện có của Kèo, chỉ đổi chỗ ở. Chạy lại test keo hiện có (`flutter test test/features/keo/`) — nếu test cũ tìm text theo copy, copy không đổi nên vẫn xanh.

- [ ] **Step 6: Deck dùng mapper.** Trong `doi_deck_screen.dart._handleSwipe`, thay `catchError` hiện tại:

```dart
.catchError((Object e) {
  if (!mounted) return;
  final err = discoverySwipeError(e);
  switch (err) {
    case DiscoverySwipeError.likeLimit:
      ProUpsellSheet.show(context,
          title: 'Hết lượt thích hôm nay',
          subtitle:
              'Pro thích không giới hạn và có 5 Siêu thích mỗi ngày.');
    case DiscoverySwipeError.superLimit:
    case DiscoverySwipeError.proRequired:
    case DiscoverySwipeError.unknown:
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err.message)));
  }
});
```
(import `discovery_errors.dart` + `pro_upsell_sheet.dart`.)

- [ ] **Step 7: analyze + full test + commit** (`feat(doi): paywall het luot thich + ProUpsellSheet dung chung`)

---

### Task 5: Rewind end-to-end

**Files:**
- Modify: `lib/features/discovery/data/discovery_repository.dart`
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart`
- Test: cập nhật `test/features/discovery/` — repo test mới `discovery_repository_rewind_test.dart`

- [ ] **Step 1: Repo test fail** (pattern mocks sẵn có `test/support/supabase_mocks.dart`):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('undoLastSwipe gọi RPC và trả bool', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('undo_last_swipe')).thenAnswer((_) => rpcOk(true));
    final repo = DiscoveryRepository(client);
    expect(await repo.undoLastSwipe(), isTrue);
  });

  test('getMatchIdWith trả uuid hoặc null', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_match_id_with',
            params: {'p_other': 'u1'}))
        .thenAnswer((_) => rpcOk('m-uuid'));
    final repo = DiscoveryRepository(client);
    expect(await repo.getMatchIdWith('u1'), 'm-uuid');
  });
}
```

- [ ] **Step 2: FAIL. Step 3: Thêm 2 method vào DiscoveryRepository**

```dart
  /// Rút lại lượt vuốt gần nhất (Pro). Server raise `pro_required` nếu free.
  Future<bool> undoLastSwipe() async {
    final res = await _client.rpc('undo_last_swipe');
    return res == true;
  }

  /// Match id đang active với [otherId], null nếu chưa match.
  Future<String?> getMatchIdWith(String otherId) async {
    final res =
        await _client.rpc('get_match_id_with', params: {'p_other': otherId});
    return res as String?;
  }
```

- [ ] **Step 4: PASS. Step 5: Deck wiring.** Trong `_DoiDeckScreenState` thêm:

```dart
  Candidate? _lastSwiped; // set trong onSwipe để rewind khôi phục đúng người

  Future<void> _handleRewind() async {
    final isPro = ref.read(isProProvider).value ?? false;
    if (!isPro) {
      ProUpsellSheet.show(context,
          title: 'Rút lại lượt vuốt?',
          subtitle: 'Thành viên Pro có thể rút lại lượt vuốt gần nhất.');
      return;
    }
    if (_lastSwiped == null) return;
    try {
      final undone = await ref.read(discoveryRepositoryProvider).undoLastSwipe();
      if (undone && mounted) {
        _controller.undo(); // card_swiper đưa card trước đó trở lại deck
        _lastSwiped = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(discoverySwipeError(e).message)));
      }
    }
  }
```
Trong `onSwipe` callback của CardSwiper, trước `_handleSwipe(...)` thêm `_lastSwiped = candidates[previousIndex];`. Ở Task 2 đã đặt `onRewind: _handleRewind` (nếu còn `() {}` thì thay).

- [ ] **Step 6: analyze + full test + commit** (`feat(doi): rewind luot vuot cho Pro`)

---

### Task 6: CandidateDetailSheet — tap card xem chi tiết

**Files:**
- Create: `lib/features/discovery/presentation/candidate_detail_sheet.dart`
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart` (bọc GestureDetector quanh card trong cardBuilder)
- Test: `test/features/discovery/candidate_detail_sheet_test.dart`

- [ ] **Step 1: Test fail**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/candidate_detail_sheet.dart';

void main() {
  const c = Candidate(
    id: 'u1',
    displayName: 'Mai',
    age: 24,
    distanceBand: '1-3',
    sharedGenres: ['vpop', 'ballad'],
    sharedBaitu: ['Nơi Này Có Anh', 'Lạc Trôi'],
    verified: true,
    activeToday: true,
  );

  testWidgets('hiện đủ tên tuổi, khoảng cách, gu chung, bài tủ chung',
      (tester) async {
    String? action;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CandidateDetailSheet(
          candidate: c,
          onPass: () => action = 'pass',
          onLike: () => action = 'like',
        ),
      ),
    ));
    expect(find.text('Mai, 24'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
    expect(find.text('#vpop'), findsOneWidget);
    expect(find.text('Nơi Này Có Anh'), findsOneWidget);
    await tester.tap(find.byKey(const Key('detail_like_btn')));
    expect(action, 'like');
  });

  testWidgets('không có dữ liệu chung vẫn render (empty-safe)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CandidateDetailSheet(
          candidate: const Candidate(id: 'u2'),
          onPass: () {},
          onLike: () {},
        ),
      ),
    ));
    expect(find.text('Bạn hát mới'), findsOneWidget);
    expect(find.text('Chưa có bài tủ chung — cơ hội khám phá!'),
        findsOneWidget);
  });
}
```

- [ ] **Step 2: FAIL. Step 3: Implement**

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/candidate.dart';
import 'report_sheet.dart';

/// Sheet chi tiết ứng viên (tap card để mở). Dữ liệu = những gì
/// get_discovery_candidates đã trả (sanitized, band-only) — không gọi thêm RPC.
class CandidateDetailSheet extends StatelessWidget {
  const CandidateDetailSheet({
    super.key,
    required this.candidate,
    required this.onPass,
    required this.onLike,
  });

  final Candidate candidate;
  final VoidCallback onPass;
  final VoidCallback onLike;

  static Future<void> show(
    BuildContext context, {
    required Candidate candidate,
    required VoidCallback onPass,
    required VoidCallback onLike,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.95,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: CandidateDetailSheet(
            candidate: candidate,
            onPass: () {
              Navigator.of(sheetCtx).pop();
              onPass();
            },
            onLike: () {
              Navigator.of(sheetCtx).pop();
              onLike();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = candidate.displayName ?? 'Bạn hát mới';
    final title = candidate.age == null ? name : '$name, ${candidate.age}';
    final monogram = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(monogram,
                    style: AppTypography.display(
                        fontSize: 28, color: AppColors.onPrimary)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(title,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      if (candidate.verified) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.verified_rounded,
                            size: 20, color: AppColors.tertiary),
                      ],
                    ]),
                    Text('Cách ${candidate.distanceBand ?? '?'} km',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Gu nhạc chung',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (candidate.sharedGenres.isEmpty)
            Text('Chưa trùng thể loại nào.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary))
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final g in candidate.sharedGenres)
                  Chip(label: Text('#$g')),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Bài tủ chung',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (candidate.sharedBaitu.isEmpty)
            Text('Chưa có bài tủ chung — cơ hội khám phá!',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary))
          else
            for (final song in candidate.sharedBaitu)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.music_note_rounded,
                    color: AppColors.primary),
                title: Text(song),
              ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('detail_pass_btn'),
                  onPressed: onPass,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Bỏ qua'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('detail_like_btn'),
                  onPressed: onLike,
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('Thích'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              key: const Key('detail_report_btn'),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => ReportSheet(targetId: candidate.id),
              ),
              child: const Text('Báo cáo / Chặn'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: PASS. Step 5: Wire tap.** Trong deck cardBuilder, bọc GestureDetector (tap không xung đột pan của CardSwiper):

```dart
cardBuilder: (context, index, h, v) => GestureDetector(
  onTap: () => CandidateDetailSheet.show(
    context,
    candidate: candidates[index],
    onPass: () => _controller.swipe(CardSwiperDirection.left),
    onLike: () => _controller.swipe(CardSwiperDirection.right),
  ),
  child: SwipeOverlays(
    hProgress: h / 100,
    vProgress: v / 100,
    child: CandidateCard(candidate: candidates[index]),
  ),
),
```

- [ ] **Step 6: analyze + full test + commit** (`feat(doi): sheet chi tiet ung vien khi tap card`)

---

### Task 7: MatchCelebration v2 — animation + Nhắn tin ngay

Màn full-screen brandGradient: 2 bong bóng monogram trượt vào từ 2 bên (easeOutBack), tiêu đề scale-in, hạt nốt nhạc rơi (CustomPainter đơn giản), haptic mediumImpact khi mở, 2 nút: **Nhắn tin ngay** (→ `/chat/:matchId`) + **Tiếp tục khám phá**.

**Files:**
- Rewrite: `lib/features/discovery/presentation/match_celebration.dart`
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart` (lấy matchId, truyền tên 2 bên)
- Test: Modify `test/features/discovery/match_celebration_test.dart`

- [ ] **Step 1: Sửa test trước (fail với code hiện tại).** Mở test hiện có, GIỮ các assertion nội dung còn hợp lệ, thay/bổ sung:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/presentation/match_celebration.dart';

void main() {
  testWidgets('hiện tên, bài tủ chung, 2 nút hành động', (tester) async {
    var chat = false;
    var continued = false;
    await tester.pumpWidget(MaterialApp(
      home: MatchCelebration(
        otherName: 'Mai',
        myName: 'Minh',
        sharedBaitu: const ['Lạc Trôi'],
        onChat: () => chat = true,
        onContinue: () => continued = true,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 900)); // chờ entrance
    expect(find.textContaining('Mai'), findsWidgets);
    expect(find.textContaining('Lạc Trôi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('match_chat_btn')));
    expect(chat, isTrue);
    await tester.tap(find.byKey(const Key('match_continue_btn')));
    expect(continued, isTrue);
  });
}
```

- [ ] **Step 2: Chạy — FAIL (signature mới `myName`/`onContinue` chưa có).**

- [ ] **Step 3: Viết lại match_celebration.dart**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class MatchCelebration extends StatefulWidget {
  const MatchCelebration({
    super.key,
    required this.otherName,
    required this.myName,
    required this.sharedBaitu,
    required this.onChat,
    required this.onContinue,
  });

  final String otherName;
  final String myName;
  final List<String> sharedBaitu;
  final VoidCallback onChat;
  final VoidCallback onContinue;

  @override
  State<MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends State<MatchCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _slide;   // bong bóng trượt vào
  late final Animation<double> _titleIn; // tiêu đề scale
  late final Animation<double> _rain;    // hạt nốt nhạc

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    final reduced =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    _slide = CurvedAnimation(
        parent: _c,
        curve: const Interval(0, 0.45, curve: Curves.easeOutBack));
    _titleIn = CurvedAnimation(
        parent: _c,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic));
    _rain = CurvedAnimation(parent: _c, curve: const Interval(0.2, 1));
    if (reduced) {
      _c.value = 1; // tôn trọng reduced motion (MASTER.md)
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _mono(String s) =>
      s.trim().isEmpty ? '?' : s.trim().characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rain,
                  builder: (_, _) => CustomPaint(
                      painter: _NoteRainPainter(progress: _rain.value)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _slide,
                      builder: (_, _) {
                        final t = _slide.value;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: Offset(-160 * (1 - t), 0),
                              child: _Bubble(letter: _mono(widget.myName)),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Transform.scale(
                              scale: t,
                              child: const Icon(Icons.favorite_rounded,
                                  color: AppColors.onPrimary, size: 40),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Transform.translate(
                              offset: Offset(160 * (1 - t), 0),
                              child: _Bubble(letter: _mono(widget.otherName)),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ScaleTransition(
                      scale: _titleIn,
                      child: Column(
                        children: [
                          Text('Hợp cạ rồi!',
                              style: AppTypography.display(
                                  fontSize: 36,
                                  color: AppColors.onPrimary)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Bạn và ${widget.otherName} đã thích nhau',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.onPrimary),
                          ),
                          if (widget.sharedBaitu.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.onPrimary
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusPill),
                              ),
                              child: Text(
                                'Cùng tủ: ${widget.sharedBaitu.take(2).join(' · ')}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: AppColors.onPrimary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      key: const Key('match_chat_btn'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.onPrimary,
                        foregroundColor: AppColors.primaryDark,
                      ),
                      onPressed: widget.onChat,
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('Nhắn tin ngay'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      key: const Key('match_continue_btn'),
                      onPressed: widget.onContinue,
                      child: const Text('Tiếp tục khám phá',
                          style: TextStyle(color: AppColors.onPrimary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.onPrimary, width: 3),
      ),
      child: Text(letter,
          style:
              AppTypography.display(fontSize: 40, color: AppColors.onPrimary)),
    );
  }
}

/// Mưa nốt nhạc nhẹ — hạt deterministic theo seed, bay xuống theo progress.
class _NoteRainPainter extends CustomPainter {
  _NoteRainPainter({required this.progress});
  final double progress;
  static final _rng = Random(7);
  static final _seeds = List.generate(
      18, (_) => (_rng.nextDouble(), _rng.nextDouble(), _rng.nextDouble()));

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final (sx, sp, ss) in _seeds) {
      final y = (progress * (0.6 + sp) % 1.2) * size.height;
      tp.text = TextSpan(
        text: '♪',
        style: TextStyle(
          fontSize: 14 + ss * 14,
          color: const Color(0xFFFFFFFF)
              .withValues(alpha: 0.25 + 0.3 * (1 - sp)),
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(sx * size.width, y));
    }
  }

  @override
  bool shouldRepaint(_NoteRainPainter old) => old.progress != progress;
}
```

- [ ] **Step 4: Test PASS. Step 5: Deck wiring.** Trong `_handleSwipe`, thay khối `if (isMatch)`:

```dart
if ((dir == 'like' || dir == 'super') && isMatch && mounted) {
  final myName =
      ref.read(myProfileProvider).value?.displayName ?? 'Bạn';
  final matchId = await ref
      .read(discoveryRepositoryProvider)
      .getMatchIdWith(candidate.id);
  if (!mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MatchCelebration(
        otherName: candidate.displayName ?? '',
        myName: myName,
        sharedBaitu: candidate.sharedBaitu,
        onChat: () {
          Navigator.of(context).pop();
          if (matchId != null) {
            context.push(
                '/chat/$matchId?name=${Uri.encodeComponent(candidate.displayName ?? '')}');
          }
        },
        onContinue: () => Navigator.of(context).pop(),
      ),
    ),
  );
}
```
`_handleSwipe` đổi thành `Future<void> ... async` với `await` thay `.then` (giữ catchError tương đương qua try/catch). Import `go_router` + `profile_providers.dart`.

- [ ] **Step 6: analyze + full test + commit** (`feat(doi): match celebration v2 + nhan tin ngay vao chat`)

---

### Task 8: Verify trên emulator (checkpoint bắt buộc)

**Điều kiện:** Supabase local chạy, emulator `emulator-5554` boot, user test `900000001` + seed HN/SG (nếu db reset — nạp seed qua docker cp như Task 3 Step 5).

- [ ] **Step 1: Build + cài**

```powershell
cd 'C:\Users\Hwang Ming Hung\cung-hat'
$env:JAVA_TOOL_OPTIONS = "-Djdk.net.unixdomain.tmpdir=C:\nonexistent\" + ("a"*120)
flutter build apk --debug --dart-define-from-file=env/dev.emulator.json
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

- [ ] **Step 2: Seed dữ liệu match 2 chiều.** Chèn 1 swipe 'like' từ seed host a1 → user test (để khi user like lại sẽ MATCH ngay, test celebration):

```powershell
docker exec supabase_db_cung-hat psql -U postgres -d postgres -c "insert into public.swipes (swiper_id, target_type, target_id, direction) select 'a0000000-0000-4000-8000-0000000000a1','user', id::text, 'like' from auth.users where phone='84900000001' on conflict do nothing;"
```

- [ ] **Step 3: Chụp từng cảnh (adb, Bash tool cho screencap):**
  1. **Overlay giữa cú kéo:** `adb shell cmd input motionevent DOWN 540 1100` → vài `MOVE` sang phải (700, 850, 1000) → screencap (thấy stamp THÍCH nghiêng, mờ ~nửa) → `MOVE` về 540 → `UP` (nhả không swipe).
  2. **Action bar:** screencap deck — 4 nút tròn dưới deck.
  3. **Tap card → detail sheet:** tap giữa card → screencap sheet (tên/gu/bài tủ/2 nút).
  4. **Match:** tap nút tim (deck_like_btn) với candidate a1 → celebration hiện (2 bong bóng + Hợp cạ rồi!) → screencap → tap Nhắn tin ngay → vào ChatScreen đúng match.
  5. **Rewind free:** user test chưa Pro → tap rewind → ProUpsellSheet screencap.
  6. **Quota:** hạ tạm quota để test nhanh — seed 30 hàng `daily_like` cho user test (SQL như pgTAP) → like 1 phát → ProUpsellSheet "Hết lượt thích hôm nay" screencap → xoá seed rate_limits.
- [ ] **Step 4: `flutter analyze` + `flutter test` + `supabase test db` lần cuối, xanh hết**
- [ ] **Step 5: Commit screenshots-log** — cập nhật `docs/verify-doi-tinder-2026-07-03.md` ghi PASS/findings (screenshots để trong scratchpad, KHÔNG commit binary), commit (`docs: verify doi tinder upgrade`).

---

## Self-Review

- **Coverage vs spec:** overlay theo ngón tay ✓ (T1), action buttons + rewind ✓ (T2/T5), profile detail ✓ (T6, multi-photo defer có lý do), match celebration ✓ (T7), monetization: daily limit + super like quota + super priority ✓ (T3/T4), boost = defer đã khai báo. Emulator verify ✓ (T8).
- **Placeholder scan:** T3 Step 2 yêu cầu copy body 0008 + 2 diff chính xác — chấp nhận được vì file nguồn tồn tại trong repo và diff được cho nguyên văn; còn lại code đầy đủ. `rate_limits` schema có ghi chú kiểm tra 0007 trước khi chạy test.
- **Type consistency:** `_controller` (CardSwiperController) dùng ở T2/T5/T6; `discoverySwipeError`/`DiscoverySwipeError` T4/T5; `ProUpsellSheet.show(title:, subtitle:)` T4/T5; `MatchCelebration(otherName, myName, sharedBaitu, onChat, onContinue)` T7 test = impl; repo methods `undoLastSwipe()`/`getMatchIdWith(String)` T5/T7 khớp.
