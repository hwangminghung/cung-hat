# Tinder-parity cho tab Đôi — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đưa tab Đôi lên chuẩn Tinder VN: paywall theo ngữ cảnh, mở rộng bán kính khi hết deck, card UX (tap đổi ảnh + action bar sync + chip xoay), interleave card Kèo, prompts hỏi-đáp, thanh hoàn thiện hồ sơ, pill "Đến lượt bạn", deck chủ đề nhạc, fix OTP tràn.

**Architecture:** Flutter (Riverpod manual providers, freezed models, go_router) + Supabase (SECURITY DEFINER RPCs, composite types, RLS-no-write pattern). Mọi thay đổi composite dùng `alter type ... add attribute ... cascade` (pattern 20260704100000_photos.sql) + recreate MỌI function trả composite đó. Spec: `docs/superpowers/specs/2026-07-06-tinder-parity-design.md`.

**Tech Stack:** Flutter 3.44.1/Dart 3.12.1, Riverpod 3.3.2, flutter_card_swiper 7.2.0, supabase_flutter 2.15.0, freezed 3.2.6-dev.1, pgTAP.

---

## ⚠️ BẮT BUỘC ĐỌC — môi trường & điều phối

- **Worktree:** làm tại `C:\Users\Hwang Ming Hung\cung-hat-photos-wt`, nhánh `feat/tinder-parity`. TUYỆT ĐỐI không đổi branch/sửa file ở `C:\Users\Hwang Ming Hung\cung-hat` (master — Codex agents song song).
- **Flutter:** gọi `C:\Users\Public\flutter\bin\flutter.bat` (home path có space). `build_runner` CHỈ chạy ở task có sửa freezed model (T3, T4, T6); sau đó `git checkout --` các file codegen chỉ đổi line-ending.
- **DB local:** áp migration bằng `npx supabase migration up` (KHÔNG `db reset` — DB đang có data test). `psql` qua `docker exec supabase_db_cung-hat psql -U postgres -d postgres`. SQL có tiếng Việt nạp bằng `docker cp file.sql supabase_db_cung-hat:/tmp/` + `docker exec -e PGCLIENTENCODING=UTF8 ... psql -f /tmp/file.sql` (Bash tool escape `//tmp/...`). KHÔNG rename `supabase/tests/chat_media_test.sql.pending`.
- **pgTAP:** `npx supabase test db` — 2 fail pre-existing (chat_test/locations_test, thiếu grant `authenticated` local) KHÔNG phải lỗi của đợt này; các file test khác phải xanh.
- **Gates mỗi task:** `flutter.bat test` + `flutter.bat analyze` xanh (+ `npx supabase test db` khi đụng DB). Commit cuối mỗi task.
- **⚠️ Chuỗi recreate `get_discovery_candidates`:** T2 (clamp) → T3 (bio) → T6 (prompts) → T9 (p_genre). Mỗi migration sau COPY từ migration MỚI NHẤT trong repo lúc đó (không copy từ `20260704110000_boost.sql`). `who_liked_me` cũng trả `setof discovery_candidate` → T3 và T6 phải recreate cả nó, nếu không nó vỡ runtime vì thiếu attribute.
- **Không đụng:** StoreScreen, validate-iap, bảng products, pricing (vùng nhánh `codex/pro-pricing-keo-boost`); onboarding flow.
- **Mock harness test:** `test/support/supabase_mocks.dart` — stub RPC bằng `rpcOk(value)` qua `thenAnswer`, KHÔNG `thenReturn`. Widget test đụng `myProfileProvider`/`signedUrlsProvider`/`openKeosProvider` phải override trong `ProviderScope`.

---

### Task 1: Paywall theo ngữ cảnh (ProUpsellVariant)

**Files:**
- Rewrite: `lib/shared/widgets/pro_upsell_sheet.dart`
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart` (4 call sites: boost/rewind/likeLimit/superLimit)
- Modify: `lib/features/keo/presentation/keo_board_screen.dart` (`_showProSheet`)
- Modify: `lib/features/keo/presentation/keo_detail_screen.dart` (dialog `free_join_limit` → sheet)
- Modify: `lib/app/home_shell.dart` (tile 'Ai đã thích bạn' khi chưa unlock → sheet seeLikes thay vì push /store thẳng)
- Test: `test/shared/pro_upsell_sheet_test.dart` (mới)

**KHÔNG số giá, không đọc products, không đụng /store nội bộ.** CTA vẫn `context.push('/store')`.

- [ ] **Step 1: Viết test fail** — `test/shared/pro_upsell_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cung_hat/shared/widgets/pro_upsell_sheet.dart';

void main() {
  Widget host(ProUpsellVariant variant) {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Builder(
          builder: (context) => TextButton(
            onPressed: () => ProUpsellSheet.show(context, variant: variant),
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(path: '/store', builder: (_, __) => const Text('STORE')),
    ]);
    return MaterialApp.router(routerConfig: router);
  }

  for (final (variant, headline) in [
    (ProUpsellVariant.boost, 'Boost hồ sơ của bạn'),
    (ProUpsellVariant.rewind, 'Rút lại lượt vuốt'),
    (ProUpsellVariant.seeLikes, 'Xem ai đã thích bạn'),
    (ProUpsellVariant.keoCreate, 'Tự tạo kèo của riêng bạn'),
    (ProUpsellVariant.keoJoinLimit, 'Tham gia nhiều kèo cùng lúc'),
    (ProUpsellVariant.likeQuota, 'Hết lượt thích hôm nay'),
    (ProUpsellVariant.superQuota, 'Hết lượt Siêu thích hôm nay'),
  ]) {
    testWidgets('variant $variant: đúng headline, không giá, CTA về store',
        (tester) async {
      await tester.pumpWidget(host(variant));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(headline), findsOneWidget);
      // Không hardcode giá — vùng pricing thuộc nhánh Codex.
      expect(find.textContaining('₫'), findsNothing);
      expect(find.textContaining('.000'), findsNothing);
      expect(find.byKey(const Key('upsell_cta_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('upsell_cta_btn')));
      await tester.pumpAndSettle();
      expect(find.text('STORE'), findsOneWidget);
    });
  }
}
```

- [ ] **Step 2: Chạy test, xác nhận FAIL** — `flutter.bat test test/shared/pro_upsell_sheet_test.dart` → fail: `ProUpsellVariant` chưa tồn tại / `show` thiếu param `variant`.

- [ ] **Step 3: Rewrite `pro_upsell_sheet.dart`** — giữ layout hiện có (icon tròn + headline + text + FilledButton + TextButton 'Để sau'), thay title/subtitle bằng variant + 3 bullet:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Paywall theo ngữ cảnh: mỗi tính năng bị chặn mở đúng biến thể của nó
/// (học Tinder — headline khớp tính năng vừa bấm). KHÔNG hiện số giá ở đây:
/// giá thuộc /store (nhánh pricing riêng đang xây catalog server-side).
enum ProUpsellVariant { boost, rewind, seeLikes, keoCreate, keoJoinLimit, likeQuota, superQuota }

class _VariantData {
  const _VariantData(this.icon, this.headline, this.bullets);
  final IconData icon;
  final String headline;
  final List<String> bullets;
}

const _variantData = <ProUpsellVariant, _VariantData>{
  ProUpsellVariant.boost: _VariantData(
    Icons.bolt_rounded,
    'Boost hồ sơ của bạn',
    ['1 lần Boost 30 phút mỗi ngày', 'Lên đầu deck của mọi người quanh đây', 'Kèm mọi quyền lợi Pro khác'],
  ),
  ProUpsellVariant.rewind: _VariantData(
    Icons.replay_rounded,
    'Rút lại lượt vuốt',
    ['Lỡ tay bỏ qua? Rút lại ngay lượt gần nhất', 'Không giới hạn số lần rút lại', 'Kèm mọi quyền lợi Pro khác'],
  ),
  ProUpsellVariant.seeLikes: _VariantData(
    Icons.favorite_rounded,
    'Xem ai đã thích bạn',
    ['Mở danh sách người đã thả tim bạn', 'Match ngay không cần vuốt trúng', 'Kèm mọi quyền lợi Pro khác'],
  ),
  ProUpsellVariant.keoCreate: _VariantData(
    Icons.mic_external_on_rounded,
    'Tự tạo kèo của riêng bạn',
    ['Làm chủ kèo: chọn quán, giờ, thành viên', 'Kèo mở hoặc cần duyệt — bạn quyết', 'Kèm mọi quyền lợi Pro khác'],
  ),
  ProUpsellVariant.keoJoinLimit: _VariantData(
    Icons.groups_rounded,
    'Tham gia nhiều kèo cùng lúc',
    ['Miễn phí chỉ được 1 kèo đang hoạt động', 'Pro tham gia không giới hạn kèo', 'Kèm mọi quyền lợi Pro khác'],
  ),
  ProUpsellVariant.likeQuota: _VariantData(
    Icons.favorite_border_rounded,
    'Hết lượt thích hôm nay',
    ['Pro thích không giới hạn mỗi ngày', '5 Siêu thích mỗi ngày', 'Kèm mọi quyền lợi Pro khác'],
  ),
  ProUpsellVariant.superQuota: _VariantData(
    Icons.star_rounded,
    'Hết lượt Siêu thích hôm nay',
    ['Pro có 5 Siêu thích mỗi ngày', 'Siêu thích giúp bạn nổi bật gấp 3 lần', 'Kèm mọi quyền lợi Pro khác'],
  ),
};

/// Bottom sheet mời nâng cấp Pro — dùng chung cho mọi gate ở Kèo và Đôi.
class ProUpsellSheet extends StatelessWidget {
  const ProUpsellSheet({super.key, required this.variant});

  final ProUpsellVariant variant;

  static Future<void> show(BuildContext context, {required ProUpsellVariant variant}) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => ProUpsellSheet(variant: variant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _variantData[variant]!;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(data.icon, color: AppColors.primaryDark, size: 30),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(data.headline,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              for (final bullet in data.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(bullet,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                key: const Key('upsell_cta_btn'),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/store');
                },
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Nâng cấp Pro'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Để sau'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Migrate call sites.** Trong `doi_deck_screen.dart`:
  - `_handleBoost` nhánh !isPro → `ProUpsellSheet.show(context, variant: ProUpsellVariant.boost);`
  - `_handleRewind` nhánh !isPro → `variant: ProUpsellVariant.rewind`
  - `likeLimit` case → `ProUpsellSheet.show(context, variant: ProUpsellVariant.likeQuota).whenComplete(() => _upsellShowing = false);`
  - `superLimit` case: thay SnackBar bằng sheet có guard `_upsellShowing` (giữ nguyên phần `_controller.undo(); _lastSwiped = null;`):

```dart
        case DiscoverySwipeError.superLimit:
          if (!_upsellShowing) {
            _upsellShowing = true;
            ProUpsellSheet.show(context, variant: ProUpsellVariant.superQuota)
                .whenComplete(() => _upsellShowing = false);
          }
          if (mounted) {
            _controller.undo();
            _lastSwiped = null;
          }
```

  Trong `keo_board_screen.dart`: `_showProSheet` body → `ProUpsellSheet.show(context, variant: ProUpsellVariant.keoCreate);`
  Trong `keo_detail_screen.dart`: nhánh `free_join_limit` thay `showDialog` bằng `ProUpsellSheet.show(context, variant: ProUpsellVariant.keoJoinLimit);` (import `../../../shared/widgets/pro_upsell_sheet.dart`; xoá dialog cũ).
  Trong `home_shell.dart` tile 'Ai đã thích bạn':

```dart
            onTap: () {
              final unlocked = ref.read(hasEntitlementProvider('see_likes'));
              if (unlocked) {
                context.push('/likes');
              } else {
                ProUpsellSheet.show(context, variant: ProUpsellVariant.seeLikes);
              }
            },
```

  (import `../shared/widgets/pro_upsell_sheet.dart` vào home_shell.)

- [ ] **Step 5: Chạy full gate** — `flutter.bat test` + `flutter.bat analyze`. Các test cũ assert text sheet cũ (vd 'Hết lượt thích hôm nay' vẫn khớp headline mới; test nào assert subtitle cũ thì sửa expectation theo variant mới — đọc fail message, sửa test cho khớp UI mới, KHÔNG sửa UI theo test cũ).

- [ ] **Step 6: Commit** — `git add -A && git commit -m "feat(billing): paywall theo ngu canh — ProUpsellVariant 7 bien the, khong gia"`

---

### Task 2: Mở rộng bán kính khi hết deck (server toggle + clamp)

**Files:**
- Create: `supabase/migrations/20260706100000_discovery_prefs.sql`
- Create: `supabase/tests/discovery_prefs_test.sql`
- Modify: `lib/features/discovery/data/discovery_repository.dart`
- Modify: `lib/features/discovery/application/discovery_providers.dart`
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart`
- Test: `test/features/discovery/discovery_radius_test.dart` (mới)

- [ ] **Step 1: Viết migration** `20260706100000_discovery_prefs.sql`:

```sql
-- Mo rong ban kinh khi het deck (Tinder-parity muc 2).
-- discovery_prefs: 1 dong/user, auto_expand = tu dong tim 100km khi 50km rong.
create table public.discovery_prefs (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  auto_expand boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table public.discovery_prefs enable row level security;
create policy discovery_prefs_read_self on public.discovery_prefs
  for select using (auth.uid() = user_id);
-- writes chi qua RPC (khong co write policy)
-- grant tuong minh: local DB tung thieu default grant cho authenticated
-- (chat_test/locations_test fail vi ly do nay).
grant select on public.discovery_prefs to authenticated;

create or replace function public.set_discovery_auto_expand(p_on boolean)
returns void language sql security definer set search_path='' as $$
  insert into public.discovery_prefs (user_id, auto_expand, updated_at)
  values (auth.uid(), p_on, now())
  on conflict (user_id) do update set auto_expand = excluded.auto_expand, updated_at = now();
$$;
create or replace function public.get_discovery_auto_expand()
returns boolean language sql security definer set search_path='' as $$
  select coalesce((select auto_expand from public.discovery_prefs where user_id = auth.uid()), false);
$$;
revoke execute on function public.set_discovery_auto_expand(boolean) from public, anon;
revoke execute on function public.get_discovery_auto_expand() from public, anon;
grant execute on function public.set_discovery_auto_expand(boolean) to authenticated;
grant execute on function public.get_discovery_auto_expand() to authenticated;

-- get_discovery_candidates: clamp ban kinh 1..100km server-side (khong tin client).
-- COPY VERBATIM tu 20260704110000_boost.sql, thay DUY NHAT dong ST_DWithin.
create or replace function public.get_discovery_candidates(p_limit int default 20, p_radius_km int default 50)
returns setof public.discovery_candidate
language sql security definer set search_path='' as $$
  with me as (
    select l.location as loc,
      (select array_agg(genre_id) from public.user_genres where user_id = auth.uid()) as genres,
      (select array_agg(song_id) from public.user_baitu where user_id = auth.uid()) as songs
    from public.user_locations l where l.user_id = auth.uid()
  ),
  cand as (
    select p.id, p.display_name, p.dob, p.verified_badge as verified, p.last_active,
           coalesce(p.report_risk, 0) as report_risk,
           public.ST_Distance(ul.location, me.loc) as dist_m,
           (select array_agg(g.genre_id) from public.user_genres g
              where g.user_id = p.id and g.genre_id = any(me.genres)) as shared_g,
           (select array_agg(s.song_id) from public.user_baitu s
              where s.user_id = p.id and s.song_id = any(me.songs)) as shared_s
    from public.profiles p
    join public.user_locations ul on ul.user_id = p.id
    cross join me
    where p.id <> auth.uid()
      and p.soft_deleted_at is null
      and public.ST_DWithin(ul.location, me.loc, least(greatest(p_radius_km, 1), 100) * 1000)
      and not exists (select 1 from public.blocks b
                        where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
                           or (b.blocker_id = p.id and b.blocked_id = auth.uid()))
      and not exists (select 1 from public.swipes sw
                        where sw.swiper_id = auth.uid() and sw.target_type = 'user' and sw.target_id = p.id::text)
  )
  select c.id, c.display_name,
         extract(year from age(c.dob))::int as age,
         app_private.dist_band(c.dist_m) as distance_band,
         coalesce(c.shared_g, '{}') as shared_genres,
         coalesce(c.shared_s, '{}') as shared_baitu,
         c.verified, (c.last_active > now() - interval '1 day') as active_today
  from cand c
  order by (
      (select weight from public.ranking_weights where key='music') * coalesce(array_length(c.shared_g,1),0)
    + (select weight from public.ranking_weights where key='nearness') * (1.0 / (1 + c.dist_m/1000))
    + (select weight from public.ranking_weights where key='activity') * (case when c.last_active > now() - interval '1 day' then 1 else 0 end)
    - (select weight from public.ranking_weights where key='report_risk') * c.report_risk
    + case when exists (
        select 1 from public.swipes ss
        where ss.swiper_id = c.id and ss.target_type = 'user'
          and ss.target_id = auth.uid()::text and ss.direction = 'super'
      ) then 5.0 else 0 end
    + case when exists (
        select 1 from public.boosts b
        where b.user_id = c.id and b.expires_at > now()
      ) then 3.0 else 0 end
  ) desc
  limit greatest(p_limit, 1);
$$;
```

- [ ] **Step 2: Viết pgTAP test** `supabase/tests/discovery_prefs_test.sql` (pattern uid-fake của repo; SQLSTATE 5 ký tự):

```sql
begin;
select plan(5);

-- seed 2 user
insert into auth.users (id, aud, role, email) values
  ('11111111-1111-1111-1111-111111111111','authenticated','authenticated','a@t.vn'),
  ('22222222-2222-2222-2222-222222222222','authenticated','authenticated','b@t.vn')
  on conflict do nothing;
insert into public.profiles (id, display_name, dob, age_verified) values
  ('11111111-1111-1111-1111-111111111111','A','1995-01-01',true),
  ('22222222-2222-2222-2222-222222222222','B','1995-01-01',true)
  on conflict do nothing;

set local role authenticated;
set local request.jwt.claims to '{"sub":"11111111-1111-1111-1111-111111111111"}';

select is(public.get_discovery_auto_expand(), false, 'mac dinh false khi chua co dong prefs');
select lives_ok($$select public.set_discovery_auto_expand(true)$$, 'set on chay duoc');
select is(public.get_discovery_auto_expand(), true, 'doc lai ra true');

-- self-only: B khong thay dong cua A
set local request.jwt.claims to '{"sub":"22222222-2222-2222-2222-222222222222"}';
select is(
  (select count(*)::int from public.discovery_prefs),
  0, 'RLS: B khong select duoc prefs cua A');
select is(public.get_discovery_auto_expand(), false, 'B van mac dinh false');

select * from finish();
rollback;
```

- [ ] **Step 3: Áp migration + chạy pgTAP** — `npx supabase migration up` rồi `npx supabase test db`. Expected: discovery_prefs_test 5/5 pass (chat/locations fail pre-existing bỏ qua).

- [ ] **Step 4: Viết test Dart fail** `test/features/discovery/discovery_radius_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import '../../support/supabase_mocks.dart';

void main() {
  test('getCandidates truyền p_radius_km', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_discovery_candidates',
            params: {'p_limit': 20, 'p_radius_km': 100}))
        .thenAnswer((_) => rpcOk(<dynamic>[]));
    final repo = DiscoveryRepository(client);
    final res = await repo.getCandidates(radiusKm: 100);
    expect(res, isEmpty);
    verify(() => client.rpc('get_discovery_candidates',
        params: {'p_limit': 20, 'p_radius_km': 100})).called(1);
  });

  test('get/setAutoExpand gọi đúng RPC', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('get_discovery_auto_expand'))
        .thenAnswer((_) => rpcOk(true));
    when(() => client.rpc('set_discovery_auto_expand',
            params: {'p_on': true}))
        .thenAnswer((_) => rpcOk(null));
    final repo = DiscoveryRepository(client);
    expect(await repo.getAutoExpand(), isTrue);
    await repo.setAutoExpand(true);
    verify(() => client.rpc('set_discovery_auto_expand',
        params: {'p_on': true})).called(1);
  });
}
```

- [ ] **Step 5: Chạy fail rồi implement repository + providers.** `discovery_repository.dart`:

```dart
  Future<List<Candidate>> getCandidates({int limit = 20, int radiusKm = 50}) async {
    final rows = await _client.rpc('get_discovery_candidates',
        params: {'p_limit': limit, 'p_radius_km': radiusKm});
    return (rows as List)
        .map((e) => Candidate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<bool> getAutoExpand() async =>
      await _client.rpc('get_discovery_auto_expand') == true;

  Future<void> setAutoExpand(bool on) async {
    await _client.rpc('set_discovery_auto_expand', params: {'p_on': on});
  }
```

`discovery_providers.dart` thêm:

```dart
/// Bán kính deck hiện tại (km). 50 mặc định; 100 khi user mở rộng — reset
/// mỗi phiên app (server chỉ lưu auto_expand, không lưu bán kính).
final deckRadiusProvider = StateProvider<int>((ref) => 50);

final autoExpandProvider = FutureProvider<bool>(
    (ref) => ref.watch(discoveryRepositoryProvider).getAutoExpand());
```

và sửa `candidatesProvider`:

```dart
final candidatesProvider = FutureProvider<List<Candidate>>((ref) => ref
    .watch(discoveryRepositoryProvider)
    .getCandidates(radiusKm: ref.watch(deckRadiusProvider)));
```

- [ ] **Step 6: UI màn hết deck** trong `doi_deck_screen.dart`, thay nhánh `candidates.isEmpty` bằng:

```dart
            if (candidates.isEmpty) {
              final radius = ref.watch(deckRadiusProvider);
              final autoExpand = ref.watch(autoExpandProvider).value ?? false;
              // Auto-expand: 50km rỗng + user đã bật → tự lên 100km 1 lần.
              if (radius == 50 && autoExpand) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ref.read(deckRadiusProvider.notifier).state = 100;
                  }
                });
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Skeleton(
                      width: double.infinity, height: double.infinity, radius: 28),
                );
              }
              return _EmptyDeck(
                radius: radius,
                autoExpand: autoExpand,
                onExpand: () =>
                    ref.read(deckRadiusProvider.notifier).state = 100,
                onToggleAutoExpand: (on) async {
                  await ref.read(discoveryRepositoryProvider).setAutoExpand(on);
                  ref.invalidate(autoExpandProvider);
                },
                onRefresh: _refreshDeck,
              );
            }
```

và thêm widget cuối file (dùng `EmptyState` icon/title hiện có làm phần trên):

```dart
class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({
    required this.radius,
    required this.autoExpand,
    required this.onExpand,
    required this.onToggleAutoExpand,
    required this.onRefresh,
  });

  final int radius;
  final bool autoExpand;
  final VoidCallback onExpand;
  final ValueChanged<bool> onToggleAutoExpand;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.music_note_rounded,
              size: 56, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            radius >= 100
                ? 'Đã tìm hết trong 100 km'
                : 'Chưa có bạn hát quanh đây',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (radius < 100)
            FilledButton.icon(
              key: const Key('expand_radius_btn'),
              onPressed: onExpand,
              icon: const Icon(Icons.travel_explore_rounded),
              label: const Text('Mở rộng tìm quanh 100 km'),
            )
          else
            OutlinedButton.icon(
              key: const Key('deck_retry_btn'),
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Làm mới gợi ý'),
            ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            key: const Key('auto_expand_switch'),
            title: const Text('Tự mở rộng khi hết người'),
            subtitle: const Text('Tự động tìm quanh 100 km khi 50 km đã hết'),
            value: autoExpand,
            onChanged: onToggleAutoExpand,
          ),
        ],
      ),
    );
  }
}
```

Header deck (trong Column data) thêm chip khi radius 100, ngay dưới subtitle `'Gợi ý hợp gu nhạc...'`:

```dart
                            if (ref.watch(deckRadiusProvider) == 100)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.xs),
                                child: Text('Đang tìm trong 100 km',
                                    key: const Key('radius_chip'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: AppColors.primaryDark)),
                              ),
```

- [ ] **Step 7: Widget test empty-deck** — thêm vào `discovery_radius_test.dart` (override `candidatesProvider` trả `[]`, `autoExpandProvider` trả false, `myProfileProvider` như pattern test deck hiện có — xem `test/features/discovery/doi_deck_screen_test.dart` để copy danh sách override): pump `DoiDeckScreen`, expect `expand_radius_btn` + `auto_expand_switch` hiện; tap expand → verify `deckRadiusProvider` == 100.

- [ ] **Step 8: Full gate + commit** — `flutter.bat test`, `flutter.bat analyze`, `npx supabase test db`. `git add -A && git commit -m "feat(discovery): mo rong ban kinh khi het deck — toggle server + clamp 100km"`

---

### Task 3: Card UX pack (tap đổi ảnh + action bar sync + chip xoay theo ảnh)

**Files:**
- Create: `supabase/migrations/20260706110000_candidate_bio.sql`
- Modify: `supabase/tests/` (thêm `candidate_bio_test.sql`)
- Modify: `lib/features/discovery/domain/candidate.dart` (+ build_runner)
- Modify: `lib/features/photos/presentation/photo_carousel.dart` (tap-nav + onPageChanged)
- Modify: `lib/features/discovery/presentation/candidate_card.dart` (stateful, chip xoay, nút ⓘ)
- Modify: `lib/features/discovery/presentation/deck_action_bar.dart` (progress sync)
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart` (bỏ onTap detail, wire progress + nút ⓘ)
- Test: `test/features/discovery/candidate_card_test.dart`, `test/features/discovery/deck_action_bar_test.dart`

- [ ] **Step 1: Migration bio** `20260706110000_candidate_bio.sql`. ⚠️ `who_liked_me` cũng trả `discovery_candidate` nên PHẢI recreate cùng lúc:

```sql
-- Chip xoay theo anh (Tinder-parity muc 3c): card can bio cua candidate.
do $$
begin
  alter type public.discovery_candidate add attribute bio text cascade;
exception
  when duplicate_column then null;
end $$;

-- Recreate get_discovery_candidates: COPY VERBATIM tu 20260706100000_discovery_prefs.sql
-- + them p.bio vao CTE cand va c.bio vao SELECT cuoi (sau active_today).
-- [DÁN NGUYÊN VĂN function từ 20260706100000, với 2 thay đổi:
--   dòng cand:  ... coalesce(p.report_risk, 0) as report_risk, p.bio,
--   dòng select cuối: ... c.verified, (c.last_active > now() - interval '1 day') as active_today, c.bio ]

-- Recreate who_liked_me: COPY VERBATIM tu 0020_monetization.sql + them p.bio cuoi SELECT.
create or replace function public.who_liked_me(p_limit int default 20)
returns setof public.discovery_candidate language plpgsql security definer set search_path='' as $$
begin
  if not app_private.has_entitlement('see_likes') then
    raise exception 'entitlement_required' using errcode='check_violation';
  end if;
  return query
    with me as (select location as loc from public.user_locations where user_id=auth.uid())
    select p.id, p.display_name, extract(year from age(p.dob))::int,
           app_private.dist_band(public.ST_Distance(ul.location, me.loc)),
           '{}'::text[], '{}'::text[], p.verified_badge,
           (p.last_active > now() - interval '1 day'),
           p.bio
    from public.swipes s
    join public.profiles p on p.id = s.swiper_id
    join public.user_locations ul on ul.user_id = p.id
    cross join me
    where s.target_type='user' and s.target_id = auth.uid()::text
      and s.direction in ('like','super') and p.soft_deleted_at is null
      and not exists (select 1 from public.matches m
        where (m.user_a=least(auth.uid(),p.id) and m.user_b=greatest(auth.uid(),p.id)))
    limit greatest(p_limit,1);
end; $$;
```

pgTAP `candidate_bio_test.sql`: seed 2 user co-located (copy pattern seed từ file test discovery sẵn có trong `supabase/tests/` — `ls` để lấy tên đúng; seed gồm auth.users + profiles + user_locations HN 105.854/21.028), user B có `bio='Hát ballad về đêm'`; A gọi `get_discovery_candidates()` → `results_eq` cột bio khớp. `plan(1)`+.

- [ ] **Step 2: Áp migration + pgTAP xanh** — `npx supabase migration up` && `npx supabase test db`.

- [ ] **Step 3: Candidate model + regen.** `candidate.dart` thêm `String? bio,` sau `activeToday`. Chạy `flutter.bat pub run build_runner build --delete-conflicting-outputs`; sau đó `git status` — file codegen nào CHỈ đổi line-ending thì `git checkout -- <file>`.

- [ ] **Step 4: Test fail chip xoay + tap nav** `test/features/discovery/candidate_card_test.dart` (override `signedUrlsProvider` — `FutureProvider.autoDispose.family<List<String>, String>` trong `lib/features/photos/application/photo_providers.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/candidate_card.dart';
import 'package:cung_hat/features/photos/application/photo_providers.dart';

const _cand = Candidate(
  id: 'u1',
  displayName: 'Linh',
  age: 24,
  distanceBand: '1-3',
  sharedGenres: ['ballad', 'kpop'],
  sharedBaitu: ['s1', 's2'],
  bio: 'Hát ballad về đêm',
);

Widget host({List<String> urls = const ['u1.jpg', 'u2.jpg', 'u3.jpg']}) {
  return ProviderScope(
    overrides: [
      signedUrlsProvider.overrideWith((ref, userId) async => urls),
    ],
    child: MaterialApp(
      home: Scaffold(body: CandidateCard(candidate: _cand, onOpenDetail: () {})),
    ),
  );
}

void main() {
  testWidgets('ảnh 1: chip khoảng cách + bài tủ; tap phải → ảnh 2: genres; tiếp → bio',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.textContaining('Cách 1-3 km'), findsOneWidget);
    expect(find.textContaining('cùng 2 bài tủ'), findsOneWidget);
    expect(find.text('#ballad'), findsNothing);

    // Tap nửa phải ảnh → trang 2 → genres
    final photoArea = find.byKey(const Key('card_photo_area'));
    final rect = tester.getRect(photoArea);
    await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('#ballad'), findsOneWidget);
    expect(find.textContaining('Cách 1-3 km'), findsNothing);

    // Tap phải lần nữa → trang 3 → bio
    await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Hát ballad về đêm'), findsOneWidget);

    // Tap nửa trái → quay lại trang 2
    await tester.tapAt(Offset(rect.left + 20, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('#ballad'), findsOneWidget);
  });

  testWidgets('nút ⓘ mở detail (callback)', (tester) async {
    var opened = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        signedUrlsProvider.overrideWith((ref, userId) async => ['u1.jpg']),
      ],
      child: MaterialApp(
        home: Scaffold(
            body: CandidateCard(
                candidate: _cand, onOpenDetail: () => opened = true)),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('card_detail_btn')));
    expect(opened, isTrue);
  });

  testWidgets('<2 ảnh: chip gộp như cũ (distance + baitu + genres)', (tester) async {
    await tester.pumpWidget(host(urls: ['u1.jpg']));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cách 1-3 km'), findsOneWidget);
    expect(find.text('#ballad'), findsOneWidget);
  });
}
```

Lưu ý: `Image.network` trong test fail-load → errorBuilder monogram, KHÔNG sao — test chỉ đụng chip/tap zones. Nếu HTTP block gây exception, dùng `mocktail_image_network` KHÔNG có trong repo → thay bằng: chấp nhận errorBuilder (ảnh fallback vẫn giữ PageView với itemCount=N nên tap-nav/dots vẫn hoạt động).

- [ ] **Step 5: Implement PhotoCarousel tap-nav.** Thêm params `onPageChanged` + tap zones khi `swipeable == false`:

```dart
  const PhotoCarousel({
    super.key,
    required this.userId,
    required this.monogram,
    this.radius,
    this.swipeable = true,
    this.onPageChanged,
    this.fallbackDecorations = const [],
  });
  ...
  /// Card mode: báo trang hiện tại lên cha (chip xoay theo ảnh).
  final ValueChanged<int>? onPageChanged;
```

Truyền xuống `_Pager(onPageChanged: onPageChanged)`. Trong `_PagerState`:
- luôn gọi `widget.onPageChanged?.call(i)` trong `onPageChanged` của PageView (cả 2 mode; card mode đổi trang qua `_go`)
- thêm method:

```dart
  void _go(int delta) {
    final next = (_current + delta).clamp(0, widget.urls.length - 1);
    if (next == _current) return;
    _controller.jumpToPage(next);
    setState(() => _current = next);
    widget.onPageChanged?.call(next);
  }
```

- khi `!widget.swipeable`, bọc Stack bằng tap zones (giữ PageView NeverScrollable; **bỏ hành vi "khoá trang 0"** — card giờ đổi trang bằng tap):

```dart
        if (!widget.swipeable)
          Positioned.fill(
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  key: const Key('photo_tap_left'),
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _go(-1),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  key: const Key('photo_tap_right'),
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _go(1),
                ),
              ),
            ]),
          ),
```

(đặt SAU PageView + dots trong Stack để nhận tap; dots vẫn vẽ vì `onPageChanged`/`_go` setState cập nhật `_current`).

- [ ] **Step 6: Implement CandidateCard chip xoay + nút ⓘ.** Đổi thành `StatefulWidget` với `int _photoIndex = 0`, `int _photoCount = 0` (cập nhật count qua `signedUrlsProvider` — CandidateCard là ConsumerStatefulWidget, watch provider như PhotoCarousel để biết N ảnh). Thêm param `required VoidCallback onOpenDetail`. Photo Stack: bọc key `Key('card_photo_area')`, `PhotoCarousel(..., swipeable: false, onPageChanged: (i) => setState(() => _photoIndex = i))`. Nút ⓘ Positioned bottom-right TRÊN vùng ảnh:

```dart
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: IconButton.filledTonal(
                    key: const Key('card_detail_btn'),
                    tooltip: 'Xem hồ sơ',
                    onPressed: onOpenDetail,
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                ),
```

Phần chips dưới title thay bằng switch theo trang (chỉ khi `_photoCount >= 2`, ngược lại giữ layout gộp cũ):

```dart
                if (_photoCount < 2) ...[
                  // layout gộp như hiện tại: 2 _Badge + genres wrap
                ] else if (_photoIndex == 0) ...[
                  // 2 _Badge: distance + bài tủ (như dòng Wrap hiện tại)
                ] else if (_photoIndex == 1) ...[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final genre in candidate.sharedGenres.take(5))
                        _GenreChip(label: genre),
                    ],
                  ),
                ] else ...[
                  Text(
                    candidate.bio?.trim().isNotEmpty == true
                        ? candidate.bio!.trim()
                        : 'Chưa có giới thiệu — hỏi thử khi match nhé!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
```

(genres rỗng ở trang 1 → hiện Text 'Chưa chung thể loại nào' cùng style bio-fallback.)

- [ ] **Step 7: Wire doi_deck_screen.** Bỏ `GestureDetector(onTap: ...)` bọc card trong `cardBuilder`; truyền `onOpenDetail`:

```dart
                      cardBuilder: (context, index, h, v) {
                        _scheduleProgress(h / 100, v / 100);
                        return SwipeOverlays(
                          hProgress: h / 100,
                          vProgress: v / 100,
                          child: CandidateCard(
                            candidate: candidates[index],
                            onOpenDetail: () => CandidateDetailSheet.show(
                              context,
                              candidate: candidates[index],
                              onPass: () =>
                                  _controller.swipe(CardSwiperDirection.left),
                              onLike: () =>
                                  _controller.swipe(CardSwiperDirection.right),
                            ),
                          ),
                        );
                      },
```

Progress notifier trong `_DoiDeckScreenState`:

```dart
  /// Tiến độ kéo hiện tại cho action bar. Cập nhật post-frame vì cardBuilder
  /// chạy TRONG build — notify ngay sẽ setState-during-build.
  final ValueNotifier<(double, double)> _dragProgress =
      ValueNotifier((0.0, 0.0));

  void _scheduleProgress(double h, double v) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dragProgress.value = (h, v);
    });
  }
```

(dispose `_dragProgress` trong `dispose()`; reset về `(0,0)` trong `onSwipe` và `onEnd` qua `_scheduleProgress(0,0)`). DeckActionBar bọc:

```dart
                  child: ValueListenableBuilder<(double, double)>(
                    valueListenable: _dragProgress,
                    builder: (context, prog, _) => DeckActionBar(
                      rewindEnabled: ref.watch(isProProvider),
                      hProgress: prog.$1,
                      vProgress: prog.$2,
                      onRewind: _handleRewind,
                      onPass: () => _controller.swipe(CardSwiperDirection.left),
                      onSuperLike: () =>
                          _controller.swipe(CardSwiperDirection.top),
                      onLike: () => _controller.swipe(CardSwiperDirection.right),
                    ),
                  ),
```

- [ ] **Step 8: DeckActionBar nhận progress.** Thêm `this.hProgress = 0, this.vProgress = 0` (double). Từng nút tính hệ số: pass = `(-hProgress).clamp(0,1)`, like = `hProgress.clamp(0,1)`, super = `(-vProgress).clamp(0,1)`, rewind = 0. `_RoundButton` thêm param `double emphasis` (0..1):

```dart
    return Transform.scale(
      scale: 1 + 0.15 * emphasis,
      child: Material(
        color: Color.lerp(
            AppColors.surface, color.withValues(alpha: 0.18), emphasis)!,
        shape: CircleBorder(
          side: BorderSide(
              color: color.withValues(alpha: 0.35 + 0.65 * emphasis),
              width: 1.5 + emphasis),
        ),
        ...
```

Test `deck_action_bar_test.dart`: pump DeckActionBar với `hProgress: 0.8` → tìm `Transform.scale` của nút like có `scale > 1.1` (dò bằng `tester.widget<Transform>` theo descendant của `Key('deck_like_btn')`); với progress 0 → scale == 1.

- [ ] **Step 9: Full gate.** `flutter.bat test` (sửa các test deck cũ vỡ vì bỏ GestureDetector onTap — test mở detail giờ tap `card_detail_btn`), `flutter.bat analyze`, `npx supabase test db`.

- [ ] **Step 10: Commit** — `git commit -m "feat(discovery): card UX pack — tap doi anh, action bar sync keo, chip xoay theo anh (+bio)"`

---

### Task 4: Interleave card Kèo vào deck Đôi

**Files:**
- Create: `supabase/migrations/20260706120000_keo_card_is_mine.sql`
- Create: `supabase/tests/keo_is_mine_test.sql`
- Modify: `lib/features/keo/domain/keo.dart` (+ regen)
- Create: `lib/features/discovery/domain/deck_item.dart`
- Create: `lib/features/discovery/presentation/keo_promo_card.dart`
- Modify: `lib/features/discovery/application/discovery_providers.dart` (deckItemsProvider)
- Modify: `lib/features/discovery/presentation/swipe_overlays.dart` (nhãn theo loại card)
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart`
- Test: `test/features/discovery/deck_interleave_test.dart`

- [ ] **Step 1: Migration is_mine.** `keo_card` được tạo lại lần cuối ở `0024_pro_keo.sql` (có join_mode). Composite `keo_card` chỉ được `list_open_keos` dùng → alter + recreate:

```sql
-- Interleave card Keo vao deck Doi (muc 13): can loai keo cua chinh minh.
do $$
begin
  alter type public.keo_card add attribute is_mine boolean cascade;
exception
  when duplicate_column then null;
end $$;

-- Recreate list_open_keos: COPY VERBATIM tu 0024_pro_keo.sql (ban co join_mode)
-- + them 1 cot cuoi:
--   exists (select 1 from public.keo_members m3
--             where m3.keo_id = k.id and m3.user_id = auth.uid()
--               and m3.join_status in ('requested','approved'))
--   or k.host_id = auth.uid()  as is_mine
-- [DÁN NGUYÊN VĂN function từ 0024 + cột trên, giữ nguyên where/order/grant]
```

pgTAP `keo_is_mine_test.sql` (`plan(3)`, copy seed host+member+bystander co-located HN từ `supabase/tests/keo_test.sql`): host thấy kèo mình `is_mine=true`; member đã `requested` → `is_mine=true`; bystander → `is_mine=false`.

- [ ] **Step 2: Áp migration + pgTAP xanh.** `npx supabase migration up` && `npx supabase test db`.

- [ ] **Step 3: Keo model** thêm `@JsonKey(name: 'is_mine') @Default(false) bool isMine,` + build_runner + checkout file CRLF-noise.

- [ ] **Step 4: Test fail interleave thuần.** `deck_interleave_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/domain/deck_item.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';

Candidate c(String id) => Candidate(id: id);
Keo k(String id, {bool mine = false}) =>
    Keo(id: id, title: 'Kèo $id', isMine: mine);

void main() {
  test('chèn 1 kèo sau mỗi 5 candidate, tối đa 2, bỏ kèo của mình', () {
    final items = interleaveDeck(
      candidates: [for (var i = 0; i < 12; i++) c('$i')],
      keos: [k('a', mine: true), k('b'), k('c'), k('d')],
    );
    // 12 candidate + 2 promo = 14; promo tại index 5 và 11
    expect(items.length, 14);
    expect(items[5], isA<KeoPromoItem>());
    expect((items[5] as KeoPromoItem).keo.id, 'b'); // 'a' là của mình → bỏ
    expect(items[11], isA<KeoPromoItem>());
    expect((items[11] as KeoPromoItem).keo.id, 'c');
    expect(items.whereType<KeoPromoItem>().length, 2);
  });

  test('deck ngắn hơn 5 hoặc không có kèo → không promo', () {
    expect(
        interleaveDeck(candidates: [c('1'), c('2')], keos: [k('b')])
            .whereType<KeoPromoItem>(),
        isEmpty);
    expect(
        interleaveDeck(
                candidates: [for (var i = 0; i < 8; i++) c('$i')], keos: [])
            .whereType<KeoPromoItem>(),
        isEmpty);
  });
}
```

- [ ] **Step 5: Implement `deck_item.dart`:**

```dart
import '../../keo/domain/keo.dart';
import 'candidate.dart';

/// Deck Đôi giờ trộn 2 loại thẻ: ứng viên thật và thẻ quảng bá Kèo.
sealed class DeckItem {
  const DeckItem();
}

class CandidateItem extends DeckItem {
  const CandidateItem(this.candidate);
  final Candidate candidate;
}

class KeoPromoItem extends DeckItem {
  const KeoPromoItem(this.keo);
  final Keo keo;
}

/// Chèn 1 thẻ Kèo sau mỗi [every] ứng viên, tối đa [maxPromos] thẻ/deck.
/// Kèo của chính mình (host/đã xin vào) không quảng bá lại cho mình.
List<DeckItem> interleaveDeck({
  required List<Candidate> candidates,
  required List<Keo> keos,
  int every = 5,
  int maxPromos = 2,
}) {
  final promos = keos.where((k) => !k.isMine).take(maxPromos).toList();
  final items = <DeckItem>[];
  var promoIdx = 0;
  for (var i = 0; i < candidates.length; i++) {
    if (i > 0 && i % every == 0 && promoIdx < promos.length) {
      items.add(KeoPromoItem(promos[promoIdx++]));
    }
    items.add(CandidateItem(candidates[i]));
  }
  // Promo sau nhóm 5 cuối nếu vừa đủ chẵn (12 cand → promo tại 5 và 11).
  if (candidates.length >= every &&
      candidates.length % every == 0 &&
      promoIdx < promos.length) {
    items.add(KeoPromoItem(promos[promoIdx++]));
  }
  return items;
}
```

⚠️ Chạy test Step 4 và ĐỐI CHIẾU expectation (promo tại index 5, 11 với 12 candidate): nếu lệch, sửa vòng lặp cho khớp semantics "sau mỗi 5 candidate" (5 cand → 1 promo → 5 cand → 1 promo → 2 cand) — expectation của test là chuẩn.

- [ ] **Step 6: deckItemsProvider** trong `discovery_providers.dart` (import keo providers):

```dart
final deckItemsProvider = FutureProvider<List<DeckItem>>((ref) async {
  final candidates = await ref.watch(candidatesProvider.future);
  // Kèo lỗi/chưa tải không được chặn deck chính — nuốt lỗi, coi như rỗng.
  List<Keo> keos = const [];
  try {
    keos = await ref.watch(openKeosProvider.future);
  } catch (_) {}
  return interleaveDeck(candidates: candidates, keos: keos);
});
```

(`openKeosProvider` ở `lib/features/keo/application/keo_providers.dart` — kiểm tra tên chính xác khi implement.)

- [ ] **Step 7: KeoPromoCard** (`keo_promo_card.dart`) — khổ card deck, style KeoCard board:

```dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../keo/domain/keo.dart';

/// Thẻ quảng bá Kèo trộn trong deck Đôi. Vuốt phải = xem chi tiết,
/// vuốt trái = bỏ qua — không quota, không rewind.
class KeoPromoCard extends StatelessWidget {
  const KeoPromoCard({super.key, required this.keo});

  final Keo keo;

  String _hhmm(String? iso) {
    if (iso == null) return '?';
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '?';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text('🎤 Kèo gần bạn',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.onPrimary)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(keo.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppColors.onPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${keo.slotsFilled}/${keo.sizeTarget} chỗ · ${_hhmm(keo.timeWindowStart)}'
            '${keo.distanceBand != null ? ' · cách ${keo.distanceBand} km' : ''}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.9)),
          ),
          if (keo.genres.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(keo.genres.take(3).map((g) => '#$g').join('  '),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.onPrimary)),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('Vuốt phải để xem kèo →',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: SwipeOverlays nhãn theo card.** Thêm params `this.likeLabel = 'THÍCH', this.nopeLabel = 'BỎ QUA', this.showSuper = true`; `_likeContent/_nopeContent/_superContent` chuyển từ `static final` sang cache map `static final Map<String, Widget> _stampCache = {}` với helper `_stamp(String label, Color color)` memoize theo label (giữ nguyên kỷ luật build-1-lần); stamp SIÊU THÍCH chỉ vẽ khi `showSuper`.

- [ ] **Step 9: doi_deck_screen chuyển sang DeckItem.** `candidatesAsync` → `ref.watch(deckItemsProvider)`; biến `candidates` → `items` (List<DeckItem>); `cardBuilder` switch:

```dart
                      cardBuilder: (context, index, h, v) {
                        _scheduleProgress(h / 100, v / 100);
                        final item = items[index];
                        return switch (item) {
                          CandidateItem(:final candidate) => SwipeOverlays(
                              hProgress: h / 100,
                              vProgress: v / 100,
                              child: CandidateCard(
                                candidate: candidate,
                                onOpenDetail: () => CandidateDetailSheet.show(
                                  context,
                                  candidate: candidate,
                                  onPass: () => _controller
                                      .swipe(CardSwiperDirection.left),
                                  onLike: () => _controller
                                      .swipe(CardSwiperDirection.right),
                                ),
                              ),
                            ),
                          KeoPromoItem(:final keo) => SwipeOverlays(
                              hProgress: h / 100,
                              vProgress: v / 100,
                              likeLabel: 'XEM KÈO',
                              showSuper: false,
                              child: KeoPromoCard(keo: keo),
                            ),
                        };
                      },
```

`onSwipe`:

```dart
                      onSwipe: (previousIndex, currentIndex, direction) {
                        final item = items[previousIndex];
                        switch (item) {
                          case CandidateItem(:final candidate):
                            final dir = _directionToSwipe(direction);
                            if (dir != null) {
                              _lastSwiped = candidate;
                              _handleSwipe(candidate, dir);
                            }
                          case KeoPromoItem(:final keo):
                            // Promo: không quota, không record_swipe, không
                            // rewind — null _lastSwiped để rewind sau promo
                            // no-op thay vì undo nhầm swipe thật cũ hơn.
                            _lastSwiped = null;
                            if (direction == CardSwiperDirection.right) {
                              context.push('/keo/${keo.id}');
                            }
                        }
                        return true;
                      },
```

(`_handleSwipe` giữ nguyên nhận Candidate. Empty-state của T2 dùng `items.whereType<CandidateItem>().isEmpty` làm điều kiện rỗng — promo không tính. `_refreshDeck` invalidate cả `candidatesProvider` lẫn không cần đụng openKeos.)

- [ ] **Step 10: Widget test promo trong deck** (thêm vào `deck_interleave_test.dart`): override `candidatesProvider` 6 candidate + `openKeosProvider` 1 kèo (isMine=false) + overrides sẵn của deck test cũ → pump DoiDeckScreen: swipe card đến index 5 (hoặc override `deckItemsProvider` trực tiếp trả `[KeoPromoItem(k('b'))]`) → expect text 'Kèo gần bạn'; simulate vuốt phải (drag card offset (400,0)) → verify router push '/keo/b' bằng GoRouter test harness của repo (xem test keo_board hiện có).

- [ ] **Step 11: Full gate + commit** — 3 gates xanh. `git commit -m "feat(discovery): interleave the Keo vao deck Doi — vuot phai xem keo, khong quota/rewind"`

---

### Task 5: Fix ô OTP thứ 6 tràn 10px màn hẹp

**Files:**
- Modify: `lib/shared/widgets/otp_input.dart:44` (min-clamp 40 → co giãn)
- Test: `test/shared/otp_input_test.dart` (mới)

- [ ] **Step 1: Test fail** — tái hiện đúng lỗi Realme (available < 6×40+5×8=280):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/shared/widgets/otp_input.dart';

void main() {
  testWidgets('6 ô không overflow trong bề ngang 270', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 270,
            child: OtpInput(onChanged: (_) {}),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Chạy xác nhận FAIL** — RenderFlex overflow → takeException non-null.

- [ ] **Step 3: Fix** — `otp_input.dart` dòng 44: `.clamp(40.0, 46.0)` → `.clamp(24.0, 46.0)` (ô co tới 24 vẫn gõ được; 6×24+5×8=184 lọt mọi màn thực tế).

- [ ] **Step 4: Test pass + full gate + commit** — `git commit -m "fix(auth): o OTP co gian theo man hep — het tran 10px tren Realme"`

---

### Task 6: Thẻ hỏi-đáp karaoke (prompts)

**Files:**
- Create: `lib/features/profile/domain/karaoke_prompts.dart`
- Create: `supabase/migrations/20260706130000_profile_prompts.sql`
- Create: `supabase/tests/profile_prompts_test.sql`
- Modify: `lib/features/profile/domain/profile.dart` + `lib/features/discovery/domain/candidate.dart` (+ regen)
- Modify: `lib/features/profile/data/profile_repository.dart` (setMyPrompts)
- Create: `lib/features/profile/presentation/prompt_editor_sheet.dart`
- Modify: `lib/app/home_shell.dart` (tile mới)
- Modify: `lib/features/discovery/presentation/candidate_detail_sheet.dart` (render prompt cards)
- Test: `test/features/profile/prompt_editor_test.dart`, mở rộng `test/features/discovery/candidate_detail_sheet_test.dart` nếu có

- [ ] **Step 1: Catalog câu hỏi** `karaoke_prompts.dart`:

```dart
/// Catalog câu hỏi-đáp karaoke (id ổn định — server lưu id + answer).
/// KHÔNG đổi id đã phát hành; thêm câu mới thì thêm id mới.
class KaraokePrompt {
  const KaraokePrompt(this.id, this.question);
  final String id;
  final String question;
}

const karaokePrompts = <KaraokePrompt>[
  KaraokePrompt('p1', 'Bài mình luôn giành mic là…'),
  KaraokePrompt('p2', 'Thể loại mình hát khi buồn…'),
  KaraokePrompt('p3', 'Đi hát, mình là kiểu người…'),
  KaraokePrompt('p4', 'Combo song ca lý tưởng của mình…'),
  KaraokePrompt('p5', 'Điểm 10 của mình khi cầm mic…'),
  KaraokePrompt('p6', 'Bài "ruột" mà ai nghe cũng bất ngờ…'),
];

String? karaokePromptQuestion(String id) {
  for (final p in karaokePrompts) {
    if (p.id == id) return p.question;
  }
  return null;
}

/// Tối đa số thẻ một hồ sơ được chọn (khớp CHECK server).
const maxPrompts = 3;
```

- [ ] **Step 2: Migration** `20260706130000_profile_prompts.sql`:

```sql
-- The hoi-dap karaoke (Tinder-parity muc 4).
create table public.profile_prompts (
  user_id uuid not null references public.profiles(id) on delete cascade,
  prompt_id text not null,
  answer text not null check (char_length(answer) between 1 and 120),
  position int not null default 0,
  primary key (user_id, prompt_id)
);
alter table public.profile_prompts enable row level security;
create policy profile_prompts_read_self on public.profile_prompts
  for select using (auth.uid() = user_id);
-- writes chi qua RPC; nguoi khac doc qua discovery_candidate (sanitized)
grant select on public.profile_prompts to authenticated;

create or replace function public.set_my_prompts(p_prompts jsonb)
returns void language plpgsql security definer set search_path='' as $$
begin
  if jsonb_array_length(coalesce(p_prompts, '[]'::jsonb)) > 3 then
    raise exception 'too_many_prompts' using errcode='check_violation';
  end if;
  delete from public.profile_prompts where user_id = auth.uid();
  insert into public.profile_prompts (user_id, prompt_id, answer, position)
  select auth.uid(), e->>'prompt_id', e->>'answer', ord - 1
  from jsonb_array_elements(coalesce(p_prompts, '[]'::jsonb)) with ordinality as t(e, ord);
end; $$;
revoke execute on function public.set_my_prompts(jsonb) from public, anon;
grant execute on function public.set_my_prompts(jsonb) to authenticated;

-- prompts vao my_profile (pattern photos: alter type + recreate 2 functions).
do $$
begin
  alter type public.my_profile add attribute prompts jsonb cascade;
exception
  when duplicate_column then null;
end $$;

-- helper dung chung cho cac projection duoi
create or replace function app_private.prompts_json(p_user uuid)
returns jsonb language sql security definer set search_path='' as $$
  select coalesce(
    (select jsonb_agg(jsonb_build_object('prompt_id', prompt_id, 'answer', answer)
                      order by position)
     from public.profile_prompts where user_id = p_user),
    '[]'::jsonb);
$$;

-- Recreate get_my_profile + upsert_my_profile: COPY VERBATIM tu
-- 20260704100000_photos.sql, them app_private.prompts_json(p.id) / (auth.uid())
-- lam cot CUOI moi SELECT ... into/return.
-- [DÁN NGUYÊN VĂN 2 function, mỗi SELECT thêm cột prompts cuối]

-- prompts vao discovery_candidate.
do $$
begin
  alter type public.discovery_candidate add attribute prompts jsonb cascade;
exception
  when duplicate_column then null;
end $$;

-- Recreate get_discovery_candidates: COPY VERBATIM tu 20260706110000_candidate_bio.sql
-- (ban da co bio + clamp) + them app_private.prompts_json(c.id) as prompts CUOI select.
-- Recreate who_liked_me: COPY VERBATIM tu 20260706110000 + them
-- app_private.prompts_json(p.id) CUOI select.
-- [DÁN NGUYÊN VĂN 2 function + cột mới]
```

- [ ] **Step 3: pgTAP** `profile_prompts_test.sql` (`plan(5)`, seed như discovery_prefs_test): (1) `lives_ok` set 2 prompts; (2) `get_my_profile()` prompts có 2 phần tử đúng thứ tự; (3) `throws_ok` 4 prompts → `'23514'`; (4) `throws_ok` answer 121 ký tự → `'23514'`; (5) set lại 1 prompt → replace-all còn 1. Áp migration + test xanh.

- [ ] **Step 4: Models.** `profile.dart` thêm:

```dart
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> prompts,
```

(giữ jsonb thô — YAGNI, khỏi freezed submodel; đọc `p['prompt_id']`/`p['answer']`). `candidate.dart` thêm y hệt. build_runner + checkout CRLF-noise.

- [ ] **Step 5: Repository** `profile_repository.dart` thêm:

```dart
  Future<void> setMyPrompts(List<Map<String, String>> prompts) async {
    await _client.rpc('set_my_prompts', params: {'p_prompts': prompts});
  }
```

Test repo (pattern rpcOk) trong `prompt_editor_test.dart`.

- [ ] **Step 6: PromptEditorSheet** — bottom sheet `isScrollControlled` (pattern PhotoManagerSheet): ListView 6 câu từ `karaokePrompts`; mỗi câu là ExpansionTile/tap → TextField answer (maxLength 120); đã trả lời → hiện answer + nút xoá; chọn quá 3 → SnackBar 'Tối đa 3 thẻ'; nút 'Lưu' (Key `save_prompts_btn`) → `setMyPrompts` (thứ tự = thứ tự chọn) → `ref.invalidate(myProfileProvider)` → pop. Initial state từ `myProfileProvider.value?.prompts`. Widget test: pump sheet với override myProfileProvider (2 prompts sẵn) → thấy 2 answer; nhập câu 3, bấm Lưu → verify rpc mock được gọi với 3 phần tử.

- [ ] **Step 7: home_shell tile** (sau tile 'Ảnh hồ sơ'):

```dart
          _ProfileTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Thẻ hỏi-đáp',
            subtitle: 'Chọn tối đa 3 câu để hồ sơ có chuyện mà bắt',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusSheet)),
              ),
              builder: (_) => const PromptEditorSheet(),
            ),
          ),
```

- [ ] **Step 8: CandidateDetailSheet render** — sau Wrap chips (dòng ~128), thêm card cho từng prompt:

```dart
            for (final p in candidate.prompts)
              if (karaokePromptQuestion(p['prompt_id'] as String? ?? '') != null)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        karaokePromptQuestion(p['prompt_id'] as String)!,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('${p['answer']}',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
```

- [ ] **Step 9: Full gate + commit** — 3 gates. `git commit -m "feat(profile): the hoi-dap karaoke — 6 cau, toi da 3, hien trong detail sheet"`

---

### Task 7: Thanh hoàn thiện hồ sơ + thưởng định lượng

**Files:**
- Create: `lib/features/profile/domain/profile_completion.dart`
- Modify: `lib/features/profile/data/profile_repository.dart` (getMyTaste)
- Modify: `lib/features/profile/application/profile_providers.dart` (myTasteProvider)
- Modify: `lib/app/home_shell.dart` (card completion dưới header)
- Test: `test/features/profile/profile_completion_test.dart`

- [ ] **Step 1: Test fail công thức** (table-driven):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/profile/domain/profile_completion.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

void main() {
  const empty = Profile(id: 'u');
  test('hồ sơ trống = 0%, đủ = 100%', () {
    expect(profileCompletion(empty, const TasteCounts(0, 0, 0)).percent, 0);
    final full = empty.copyWith(
      bio: 'x',
      photoPaths: ['a', 'b', 'c'],
      prompts: [
        {'prompt_id': 'p1', 'answer': 'a'},
        {'prompt_id': 'p2', 'answer': 'b'},
      ],
    );
    expect(profileCompletion(full, const TasteCounts(3, 1, 3)).percent, 100);
  });
  test('1 ảnh + bio = 35%', () {
    final p = empty.copyWith(bio: 'x', photoPaths: ['a']);
    expect(profileCompletion(p, const TasteCounts(0, 0, 0)).percent, 35);
  });
  test('gợi ý kế tiếp: thiếu ảnh đứng đầu', () {
    final r = profileCompletion(empty, const TasteCounts(0, 0, 0));
    expect(r.nextSteps.first, contains('ảnh'));
    expect(r.nextSteps.length, lessThanOrEqualTo(2));
  });
}
```

- [ ] **Step 2: Implement:**

```dart
import 'profile.dart';

class TasteCounts {
  const TasteCounts(this.genres, this.artists, this.baitu);
  final int genres;
  final int artists;
  final int baitu;
}

class CompletionResult {
  const CompletionResult(this.percent, this.nextSteps);
  final int percent;
  final List<String> nextSteps; // tối đa 2 gợi ý, ưu tiên điểm to nhất
}

/// Trọng số cố định (tổng 100): ảnh≥1=20, ảnh≥3=+10, bio=15,
/// genres≥3=15, artists≥1=10, bài tủ≥3=15, prompts≥2=15.
CompletionResult profileCompletion(Profile p, TasteCounts taste) {
  var percent = 0;
  final missing = <(int, String)>[];

  void item(bool done, int weight, String suggestion) {
    if (done) {
      percent += weight;
    } else {
      missing.add((weight, suggestion));
    }
  }

  final photos = p.photoPaths.length;
  item(photos >= 1, 20, 'Thêm ảnh đầu tiên → được thấy nhiều hơn hẳn');
  item(photos >= 3, 10, 'Đủ 3 ảnh → x2 lượt được thấy');
  item(p.bio?.trim().isNotEmpty == true, 15, 'Viết bio → +25% match');
  item(taste.genres >= 3, 15, 'Chọn đủ 3 thể loại → gợi ý chuẩn gu hơn');
  item(taste.artists >= 1, 10, 'Thêm nghệ sĩ yêu thích');
  item(taste.baitu >= 3, 15, 'Thêm 3 bài tủ → dễ vào kèo hơn');
  item(p.prompts.length >= 2, 15, 'Trả lời 2 thẻ hỏi-đáp → có chuyện mà bắt');

  missing.sort((a, b) => b.$1.compareTo(a.$1));
  return CompletionResult(
      percent, [for (final m in missing.take(2)) m.$2]);
}
```

(Nếu test '1 ảnh + bio = 35%' fail vì kỳ vọng khác — đối chiếu 20+15=35: đúng.)

- [ ] **Step 3: Taste plumbing.** `profile_repository.dart`:

```dart
  Future<TasteCounts> getMyTasteCounts() async {
    final j = await _client.rpc('get_my_taste');
    final m = Map<String, dynamic>.from(j as Map);
    int n(String k) => (m[k] as List?)?.length ?? 0;
    return TasteCounts(n('genres'), n('artists'), n('baitu'));
  }
```

`profile_providers.dart`: `final myTasteCountsProvider = FutureProvider<TasteCounts>((ref) => ref.watch(profileRepositoryProvider).getMyTasteCounts());` (kiểm tra tên repo provider thật trong file).

- [ ] **Step 4: UI card** trong `_ProfileTab` ngay sau Container header (trước tile đầu):

```dart
          const SizedBox(height: AppSpacing.md),
          _CompletionCard(),
```

```dart
class _CompletionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;
    final taste = ref.watch(myTasteCountsProvider).value;
    if (profile == null || taste == null) return const SizedBox.shrink();
    final r = profileCompletion(profile, taste);
    if (r.percent >= 100) return const SizedBox.shrink();
    return Container(
      key: const Key('completion_card'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text('Hồ sơ hoàn thiện ${r.percent}%',
                    style: Theme.of(context).textTheme.titleMedium)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
                value: r.percent / 100, minHeight: 8),
          ),
          for (final step in r.nextSteps)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(children: [
                const Icon(Icons.arrow_circle_up_rounded,
                    size: 16, color: AppColors.primaryDark),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                    child: Text(step,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary))),
              ]),
            ),
        ],
      ),
    );
  }
}
```

Widget test: override `myProfileProvider` (profile 1 ảnh + bio) + `myTasteCountsProvider` (0,0,0) → thấy 'Hồ sơ hoàn thiện 35%' + 2 gợi ý; override full → `completion_card` biến mất. Lưu ý home_shell_test hiện có: tab Hồ sơ giờ watch thêm `myTasteCountsProvider` → thêm override vào ProviderScope của test đó.

- [ ] **Step 5: Full gate + commit** — `git commit -m "feat(profile): thanh hoan thien ho so + thuong dinh luong"`

---

### Task 8: Pill "Đến lượt bạn" trong inbox

**Files:**
- Create: `supabase/migrations/20260706140000_inbox_turn_pill.sql`
- Create: `supabase/tests/inbox_turn_test.sql`
- Modify: `lib/features/chat/data/match_inbox.dart` (MatchSummary.lastSenderId)
- Modify: `lib/features/chat/presentation/inbox_screen.dart` (pill)
- Test: `test/features/chat/inbox_turn_pill_test.dart`

**Phần Kèo-chờ-confirm DEFER** (kèo status 'full' không còn trên board; cần surface "Kèo của tôi" riêng — ghi vào backlog sau đợt).

- [ ] **Step 1: Migration:**

```sql
-- Pill "Den luot ban" (Tinder-parity muc 7): inbox can biet ai nhan cuoi.
do $$
begin
  alter type public.match_summary add attribute last_sender_id uuid cascade;
exception
  when duplicate_column then null;
end $$;

-- Recreate get_my_matches: COPY VERBATIM tu 0011_inbox.sql + them cot cuoi:
--   (select msg.sender_id from public.messages msg
--      where msg.thread_type='match' and msg.thread_id = m.id
--      order by msg.created_at desc limit 1) as last_sender_id
-- [DÁN NGUYÊN VĂN function + cột trên]
```

- [ ] **Step 2: pgTAP** `inbox_turn_test.sql` (`plan(3)`, seed match A-B pattern `supabase/tests/chat_*` seed hoặc inbox test cũ): (1) chưa có tin → `last_sender_id` null; (2) A gửi (insert messages trực tiếp as postgres) → A đọc inbox thấy `last_sender_id = A`; (3) B đọc thấy `last_sender_id = A`. Áp + xanh.

- [ ] **Step 3: MatchSummary** thêm `this.lastSenderId` (String?, từ `j['last_sender_id']`).

- [ ] **Step 4: Test fail pill** `inbox_turn_pill_test.dart`: override `inboxProvider` với 3 match: (a) lastSenderId null → pill 'Nhắn trước đi'; (b) lastSenderId = other → pill 'Đến lượt bạn'; (c) lastSenderId = mình → không pill. Cần uid của mình: dùng `myProfileProvider` override (id 'me') — inbox so sánh `match.lastSenderId != myId`.

- [ ] **Step 5: Implement pill.** `InboxScreen` watch `myProfileProvider` lấy `myId`; `_InboxTile` thêm param `turnLabel String?`:

```dart
    final myId = ref.watch(myProfileProvider).value?.id;
    ...
              String? turnLabel;
              if (match.lastSenderId == null) {
                turnLabel = 'Nhắn trước đi';
              } else if (myId != null && match.lastSenderId != myId) {
                turnLabel = 'Đến lượt bạn';
              }
```

Trong `_InboxTile`, subtitle thay bằng:

```dart
        subtitle: turnLabel != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  key: const Key('turn_pill'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(turnLabel,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              color: AppColors.secondaryDark,
                              fontWeight: FontWeight.w800)),
                ),
              ])
            : const Text('Sẵn sàng rủ đi hát'),
```

(kiểm tra `AppColors.secondaryDark` tồn tại — nếu không, dùng `AppColors.textPrimary`.)

- [ ] **Step 6: Full gate + commit** — `git commit -m "feat(chat): pill 'Den luot ban' / 'Nhan truoc di' trong inbox"`

---

### Task 9: Deck chủ đề nhạc (mini-Khám Phá)

**Files:**
- Create: `supabase/migrations/20260706150000_theme_decks.sql`
- Create: `supabase/tests/theme_decks_test.sql`
- Create: `lib/features/discovery/domain/music_themes.dart`
- Modify: `lib/features/discovery/data/discovery_repository.dart` (genre param + counts)
- Modify: `lib/features/discovery/application/discovery_providers.dart` (family theo genre)
- Create: `lib/features/discovery/presentation/theme_board_screen.dart`
- Modify: `lib/features/discovery/presentation/doi_deck_screen.dart` (param genre + entry Khám phá)
- Modify: `lib/app/router.dart` (routes /explore, /explore/:genre — kiểm tra path file router thật)
- Test: `test/features/discovery/theme_decks_test.dart`

- [ ] **Step 1: Migration.** ⚠️ Đổi signature function → PHẢI drop trước (create or replace với default mới sẽ tạo OVERLOAD 2-arg/3-arg):

```sql
-- Deck chu de nhac (Tinder-parity muc 6).
drop function public.get_discovery_candidates(int, int);

-- Tao lai 3 THAM SO: COPY VERBATIM body tu 20260706130000_profile_prompts.sql
-- (ban co bio + prompts + clamp) voi:
--   signature: (p_limit int default 20, p_radius_km int default 50, p_genre text default null)
--   them vao WHERE cua CTE cand:
--     and (p_genre is null or exists (select 1 from public.user_genres ug
--            where ug.user_id = p.id and ug.genre_id = p_genre))
-- [DÁN NGUYÊN VĂN function]
revoke execute on function public.get_discovery_candidates(int,int,text) from public, anon;
grant execute on function public.get_discovery_candidates(int,int,text) to authenticated;

-- Dem nguoi "live" moi chu de trong ban kinh 50km (chi con so, khong identity
-- → khong lo privacy; van loai tai khoan xoa mem).
create or replace function public.get_theme_deck_counts(p_genres text[])
returns table (genre_id text, live_count int)
language sql security definer set search_path='' as $$
  with me as (select location as loc from public.user_locations where user_id = auth.uid())
  select g.genre_id,
         -- Subquery tuong quan thay vi LEFT JOIN + WHERE: genre 0-nguoi van
         -- tra ve hang voi live_count = 0 (WHERE ngoai se nuot mat hang).
         (select count(*)::int
            from public.user_genres ug
            join public.profiles p on p.id = ug.user_id
            join public.user_locations ul on ul.user_id = p.id
            cross join me
           where ug.genre_id = g.genre_id
             and p.id <> auth.uid()
             and p.soft_deleted_at is null
             and p.last_active > now() - interval '7 days'
             and public.ST_DWithin(ul.location, me.loc, 50000)) as live_count
  from unnest(p_genres) as g(genre_id);
$$;
revoke execute on function public.get_theme_deck_counts(text[]) from public, anon;
grant execute on function public.get_theme_deck_counts(text[]) to authenticated;
```

- [ ] **Step 2: pgTAP** `theme_decks_test.sql` (`plan(4)`, seed 3 user HN co-located: A caller; B genre ballad active hôm nay; C genre rap_vn nhưng `last_active` 30 ngày trước): (1) `get_theme_deck_counts(array['ballad','rap_vn','bolero'])` → ballad=1; (2) rap_vn=0 (C không active 7 ngày); (3) bolero=0 (không ai — hàng vẫn tồn tại); (4) `get_discovery_candidates(20, 50, 'ballad')` chỉ trả B, `p_genre='bolero'` trả 0 hàng. Áp + xanh.

- [ ] **Step 3: Themes const** `music_themes.dart` (genre id khớp seed `0003_music_ref.sql`: vpop/ballad/bolero/rap_vn/kpop/us_uk):

```dart
class MusicTheme {
  const MusicTheme(this.genreId, this.title, this.subtitle, this.emoji);
  final String genreId;
  final String title;
  final String subtitle;
  final String emoji;
}

const musicThemes = <MusicTheme>[
  MusicTheme('ballad', 'Đêm Ballad', 'Chậm rãi, tình cảm', '🌙'),
  MusicTheme('rap_vn', 'Hội Rap', 'Bắn rap không cần beat', '🔥'),
  MusicTheme('bolero', 'Bolero chill', 'Trữ tình sâu lắng', '🍵'),
  MusicTheme('kpop', 'Đêm K-Pop', 'Quẩy hết mình', '✨'),
  MusicTheme('vpop', 'V-Pop party', 'Hit Việt mọi thế hệ', '🎉'),
];
```

- [ ] **Step 4: Repository + providers.** `getCandidates` thêm `String? genre` → params thêm `'p_genre': genre` (LUÔN gửi, null ok). `getThemeDeckCounts(List<String> ids)` → rpc trả List rows `{genre_id, live_count}` → `Map<String,int>`. Providers — **đổi `candidatesProvider` thành family** (breaking: mọi chỗ watch phải thêm arg):

```dart
final candidatesProvider =
    FutureProvider.family<List<Candidate>, String?>((ref, genre) => ref
        .watch(discoveryRepositoryProvider)
        .getCandidates(radiusKm: ref.watch(deckRadiusProvider), genre: genre));

final deckItemsProvider =
    FutureProvider.family<List<DeckItem>, String?>((ref, genre) async {
  final candidates = await ref.watch(candidatesProvider(genre).future);
  List<Keo> keos = const [];
  if (genre == null) {
    // Promo Kèo chỉ trộn ở deck chính.
    try {
      keos = await ref.watch(openKeosProvider.future);
    } catch (_) {}
  }
  return interleaveDeck(candidates: candidates, keos: keos);
});

final themeDeckCountsProvider = FutureProvider<Map<String, int>>((ref) =>
    ref.watch(discoveryRepositoryProvider).getThemeDeckCounts(
        [for (final t in musicThemes) t.genreId]));
```

Sửa mọi call site: `DoiDeckScreen` nhận `this.genre` (String?, default null) → `deckItemsProvider(widget.genre)`, `candidatesProvider(widget.genre)` (cả `_refreshDeck` + initState invalidate); test cũ đổi `candidatesProvider.overrideWith(...)` → family override.

- [ ] **Step 5: ThemeBoardScreen** — grid 2 cột card gradient: emoji + title + subtitle + `'N người đang hát'` (từ `themeDeckCountsProvider`, fallback '—' khi loading); tap → `context.push('/explore/${t.genreId}')`. AppBar 'Khám Phá theo gu nhạc'.

- [ ] **Step 6: Routes + entry.** Router thêm (cạnh các route con hiện có, kiểm tra file `lib/app/router.dart`):

```dart
      GoRoute(path: '/explore', builder: (_, __) => const ThemeBoardScreen()),
      GoRoute(
          path: '/explore/:genre',
          builder: (_, state) =>
              Scaffold(body: DoiDeckScreen(genre: state.pathParameters['genre']))),
```

Header Đôi (trong Row cạnh boost btn) thêm:

```dart
                      IconButton.filledTonal(
                        key: const Key('explore_btn'),
                        tooltip: 'Khám Phá theo gu nhạc',
                        onPressed: () => context.push('/explore'),
                        icon: const Icon(Icons.explore_rounded),
                      ),
                      const SizedBox(width: AppSpacing.xs),
```

Khi `widget.genre != null`: header title = theme.title (lookup `musicThemes`), ẩn boost/explore btn, thêm BackButton (deck trong route push nên AppBar-less Scaffold cần nút back — bọc `SafeArea` sẵn, thêm `IconButton(Icons.arrow_back)` đầu Row gọi `context.pop()`).

- [ ] **Step 7: Tests.** Repo test: rpc params có `p_genre`. Widget test board: override `themeDeckCountsProvider` `{'ballad': 12, ...}` → thấy 'Đêm Ballad' + '12 người đang hát'; tap card ballad → router đến '/explore/ballad'. Deck-family test: override `deckItemsProvider('ballad')` → DoiDeckScreen(genre:'ballad') hiện card + không có `explore_btn`.

- [ ] **Step 8: Full gate + commit** — 3 gates (chú ý sửa hết test vỡ vì candidatesProvider thành family). `git commit -m "feat(discovery): deck chu de nhac — board Kham Pha + filter genre + so nguoi live"`

---

### Task 10 (chốt đợt): Final holistic review + verify thiết bị

- [ ] **Step 1:** Đọc lại toàn diff `git diff 0d605939..HEAD` — đối chiếu spec từng mục (T1-T9), tìm mâu thuẫn cross-task (đặc biệt: chuỗi 4 bản `get_discovery_candidates` — bản CUỐI trong DB phải có đủ clamp + bio + prompts + p_genre; ai còn gọi `ProUpsellSheet.show(title:...)` cũ; `candidatesProvider` family đã sửa hết call site chưa).
- [ ] **Step 2:** `flutter.bat test` + `flutter.bat analyze` + `npx supabase test db` toàn bộ xanh (trừ 2 fail pre-existing đã ghi chú).
- [ ] **Step 3:** Build + verify emulator: `flutter.bat build apk --debug --dart-define-from-file=env/dev.emulator.json` (AF_UNIX flag đã trong gradle.properties; check mtime APK trước khi install); boot `C:\Users\Public\AndroidSDK\emulator\emulator.exe -avd cunghat_test -no-snapshot -no-audio -no-boot-anim -gpu swiftshader_indirect`; login `900000001`/OTP `123456`. Checklist verify: paywall variants (bấm boost/rewind khi free), empty deck + mở rộng 100km, tap đổi ảnh + chip xoay + nút ⓘ, action bar phồng khi kéo, card Kèo trong deck (cần seed kèo + candidate — seed qua docker cp nếu DB thiếu), OTP 6 ô màn hẹp (resize emulator hoặc device thật), thẻ hỏi-đáp end-to-end, completion bar %, pill inbox, Khám Phá board + deck ballad.
- [ ] **Step 4:** Điện thoại thật Realme (serial `2783ff85`): `adb reverse tcp:54321 tcp:54321` + build `--dart-define-from-file=env/dev.device.json`; verify OTP fix + vài mục chính.
- [ ] **Step 5:** Ghi `docs/verify-tinder-parity-2026-07-XX.md` (log + screenshots pattern các file verify cũ) + commit.
- [ ] **Step 6:** DỪNG — báo user kết quả + chờ quyết định merge/PR (PR #3 feat/pro-keo-gating→master đang mở; nhánh này stack lên nó).
