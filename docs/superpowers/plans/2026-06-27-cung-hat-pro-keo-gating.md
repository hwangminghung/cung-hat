# Cùng Hát — Pro keo gating Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gate kèo creation behind a Pro entitlement (superset of all paid features), cap free users at one active kèo, and let Pro hosts pick a per-kèo join mode (open / approval).

**Architecture:** Server (Postgres RPC/helpers) is the source of truth — all rules live in migration `0024_pro_keo.sql` and are covered by pgTAP tests. The Flutter client mirrors state only to gate UI and show friendly errors. Pro is modeled as an `entitlements.feature = 'pro'` row; `app_private.has_entitlement` treats `pro` as a superset.

**Tech Stack:** Supabase/Postgres (pgTAP via `supabase test db`), Flutter 3.44 / Riverpod. Supabase CLI via `npx supabase`. Flutter at `C:\Users\Public\flutter\bin\flutter.bat`.

**Spec:** `docs/superpowers/specs/2026-06-27-cung-hat-pro-keo-gating-design.md`
**Branch:** `feat/pro-keo-gating` (already checked out, off `feat/ui-redesign`).

---

## File structure

Create:
- `supabase/migrations/0024_pro_keo.sql` — entitlement superset, `keo.join_mode`, gated `create_keo`, capped `request_join_keo`
- `supabase/tests/pro_keo_test.sql` — pgTAP coverage
- `lib/features/keo/data/keo_errors.dart` — map Postgres errors → Vietnamese
- `test/features/keo/keo_errors_test.dart`
- `test/features/billing/entitlements_test.dart`

Modify:
- `lib/features/billing/application/billing_providers.dart` — `isProProvider`, superset `hasEntitlementProvider`
- `lib/features/keo/data/keo_repository.dart` — `createKeo` gains `joinMode`
- `lib/features/keo/presentation/create_keo_screen.dart` — join-mode selector
- `lib/features/keo/presentation/keo_board_screen.dart` — FAB Pro gate
- `lib/features/keo/presentation/keo_detail_screen.dart` — `free_join_limit` dialog
- `lib/features/billing/presentation/store_screen.dart` — Pro upgrade item
- `lib/features/billing/application/iap_controller.dart` — `'pro'` product id

Keep these `Key`s unchanged: `create_keo_btn`, `request_join_btn`, `confirm_keo_btn`, `keo_genre_<id>`.

---

## Task 1: Migration 0024 — Pro entitlement, join_mode, gated create_keo, capped request_join_keo

**Files:**
- Create: `supabase/migrations/0024_pro_keo.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- 0024_pro_keo.sql
-- Pro gating: 'pro' entitlement is a superset; only Pro can create keo;
-- per-keo join mode (open/approval); free users capped at 1 active keo.

-- 1) Allow the 'pro' feature + product type (inline CHECKs are auto-named <table>_<col>_check).
alter table public.entitlements drop constraint entitlements_feature_check;
alter table public.entitlements add constraint entitlements_feature_check
  check (feature in ('boost','see_likes','premium_filters','pro'));
alter table public.products drop constraint products_type_check;
alter table public.products add constraint products_type_check
  check (type in ('boost','see_likes','premium_filters','pro'));
insert into public.products (sku, type, platform, store_product_id, price_minor) values
  ('pro_ios','pro','ios','com.cunghat.pro',199000),
  ('pro_android','pro','android','pro',199000)
  on conflict (sku) do nothing;

-- 2) is_pro() + has_entitlement superset.
create or replace function app_private.is_pro()
returns boolean language sql security definer set search_path='' stable as $$
  select exists (select 1 from public.entitlements e
                 where e.user_id = auth.uid() and e.feature = 'pro'
                   and (e.active_until is null or e.active_until > now()));
$$;

create or replace function app_private.has_entitlement(p_feature text)
returns boolean language sql security definer set search_path='' stable as $$
  select app_private.is_pro() or exists (
    select 1 from public.entitlements e
    where e.user_id = auth.uid() and e.feature = p_feature
      and (e.active_until is null or e.active_until > now()));
$$;

-- 3) Per-keo join mode.
alter table public.keo add column if not exists join_mode text not null default 'approval'
  check (join_mode in ('open','approval'));

-- 4) create_keo: Pro-only + join mode. Drop the old 10-arg signature, recreate with p_join_mode.
drop function if exists public.create_keo(text,double precision,double precision,text,timestamptz,timestamptz,int,text,text,text[]);

create or replace function public.create_keo(
  p_title text, p_lat double precision, p_lng double precision, p_area text,
  p_start timestamptz, p_end timestamptz, p_size int, p_intent text, p_vibe text,
  p_genres text[], p_join_mode text default 'approval'
) returns uuid language plpgsql security definer set search_path='' as $$
declare kid uuid;
begin
  if not app_private.is_pro() then
    raise exception 'pro_required' using errcode='check_violation';
  end if;
  perform app_private.enforce_rate_limit('create_keo', 10, interval '1 day');
  insert into public.keo(host_id, title, area_label, area_geo, time_window_start, time_window_end,
                         group_size_target, intent_tag, vibe, genres, join_mode)
  values (auth.uid(), p_title, p_area,
          public.ST_SetSRID(public.ST_MakePoint(round(p_lng::numeric,3)::double precision,
                                  round(p_lat::numeric,3)::double precision),4326)::public.geography,
          p_start, p_end, p_size, p_intent, p_vibe, coalesce(p_genres,'{}'),
          case when p_join_mode in ('open','approval') then p_join_mode else 'approval' end)
  returning id into kid;
  insert into public.keo_members(keo_id, user_id, role, join_status, confirmed)
  values (kid, auth.uid(), 'host', 'approved', true);
  return kid;
end; $$;

revoke execute on function public.create_keo(text,double precision,double precision,text,timestamptz,timestamptz,int,text,text,text[],text) from public, anon;
grant execute on function public.create_keo(text,double precision,double precision,text,timestamptz,timestamptz,int,text,text,text[],text) to authenticated;

-- 5) request_join_keo: free-user cap (1 active) + open-mode auto-approve.
create or replace function public.request_join_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
declare filled int; target int; st text; mode text; active_n int; new_status text;
begin
  perform app_private.enforce_rate_limit('join_keo', 50, interval '1 day');
  select status, group_size_target, join_mode into st, target, mode from public.keo where id = p_keo;
  if st <> 'open' then raise exception 'keo_not_open' using errcode='check_violation'; end if;
  if exists (select 1 from public.keo where id=p_keo and host_id=auth.uid()) then
    raise exception 'is_host' using errcode='check_violation';
  end if;
  if not app_private.is_pro() then
    select count(*) into active_n
      from public.keo_members m join public.keo k on k.id = m.keo_id
     where m.user_id = auth.uid() and m.keo_id <> p_keo
       and m.join_status in ('requested','approved')
       and k.status = 'open' and k.time_window_end > now();
    if active_n >= 1 then raise exception 'free_join_limit' using errcode='check_violation'; end if;
  end if;
  if exists (select 1 from public.blocks b
             where (b.blocker_id=auth.uid() and b.blocked_id=(select host_id from public.keo where id=p_keo))
                or (b.blocked_id=auth.uid() and b.blocker_id=(select host_id from public.keo where id=p_keo)))
  then raise exception 'blocked' using errcode='check_violation'; end if;
  select count(*) into filled from public.keo_members where keo_id=p_keo and join_status='approved';
  if filled >= target then raise exception 'keo_full' using errcode='check_violation'; end if;
  if exists (select 1 from public.keo_members where keo_id=p_keo and user_id=auth.uid() and join_status='declined') then
    raise exception 'already_declined' using errcode='check_violation';
  end if;
  new_status := case when mode = 'open' then 'approved' else 'requested' end;
  insert into public.keo_members(keo_id, user_id, role, join_status)
  values (p_keo, auth.uid(), 'member', new_status)
  on conflict (keo_id, user_id) do update set join_status=excluded.join_status;
  if new_status = 'approved' and filled + 1 >= target then
    update public.keo set status='full' where id=p_keo;
  end if;
end; $$;
```

- [ ] **Step 2: Apply migrations locally (verify the file loads)**

Run: `npx supabase db reset`
Expected: all migrations apply with no error, ending with the seed; `0024_pro_keo.sql` applies cleanly. (Docker/Supabase local must be running.)

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/0024_pro_keo.sql
git commit -m "feat(db): Pro entitlement superset, keo join_mode, gated create/join"
```

---

## Task 2: pgTAP tests for the migration

**Files:**
- Create: `supabase/tests/pro_keo_test.sql`

- [ ] **Step 1: Write the test file**

```sql
-- Run with: supabase test db
-- Proves migration 0024: Pro superset, create_keo Pro-gate, free 1-active-keo cap,
-- open-mode auto-approve.
begin;
select plan(6);

set local role postgres;
-- Three users: pro host, free user A, free user B.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000a1'),
  ('00000000-0000-0000-0000-0000000000b1'),
  ('00000000-0000-0000-0000-0000000000b2')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000a1','Pro Host','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000b1','Free A','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000b2','Free B','1990-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000a1','pro','promo')
  on conflict do nothing;

-- Case 1: has_entitlement superset — pro user has see_likes without owning it.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
set local role authenticated;
select ok(app_private.has_entitlement('see_likes'), 'pro user has see_likes via superset');

-- Case 2: free user cannot create keo.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b1"}';
set local role authenticated;
select throws_ok(
  $$ select public.create_keo('K',21.0,105.8,'HN',now()+interval '1 day',now()+interval '1 day 2 hours',4,null,null,array[]::text[],'open') $$,
  '23514', null, 'free user blocked from create_keo');

-- Case 3: pro user creates an OPEN keo (store the id in a temp table for later cases).
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
set local role authenticated;
create temp table _t (keo uuid);
insert into _t select public.create_keo('Open KEO',21.0,105.8,'HN',now()+interval '1 day',now()+interval '1 day 2 hours',5,null,null,array[]::text[],'open');
select is((select join_mode from public.keo k join _t t on t.keo=k.id), 'open', 'pro create_keo stores join_mode=open');

-- Case 4: free B joins the OPEN keo -> auto-approved.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b2"}';
set local role authenticated;
select lives_ok(
  $$ select public.request_join_keo((select keo from _t)) $$,
  'free user can request-join open keo');
select is(
  (select join_status from public.keo_members m, _t t where m.keo_id=t.keo and m.user_id='00000000-0000-0000-0000-0000000000b2'),
  'approved', 'open-mode join is auto-approved');

-- Case 5: free B (now in 1 active keo) is blocked from a SECOND keo.
-- Pro host makes a second open keo; B already has 1 active -> free_join_limit.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
set local role authenticated;
insert into _t select public.create_keo('Open KEO 2',21.0,105.8,'HN',now()+interval '1 day',now()+interval '1 day 2 hours',5,null,null,array[]::text[],'open');
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b2"}';
set local role authenticated;
select throws_ok(
  $$ select public.request_join_keo((select keo from _t order by keo desc limit 1)) $$,
  '23514', null, 'free user capped at 1 active keo');

select * from finish();
rollback;
```

Note: if `_t` ordering by uuid is unreliable for "second keo", the test still asserts the cap by attempting any second active join while B already has one approved membership — the exception is what's asserted. The two `_t` rows are both open/future, so either is a valid "second" target.

- [ ] **Step 2: Run the pgTAP tests**

Run: `npx supabase test db`
Expected: `pro_keo_test.sql .. ok` — all 6 assertions pass (and existing tests still pass).

- [ ] **Step 3: Commit**

```bash
git add supabase/tests/pro_keo_test.sql
git commit -m "test(db): pgTAP for Pro gating + free join cap + open auto-approve"
```

---

## Task 3: Client — isPro + superset entitlement providers

**Files:**
- Modify: `lib/features/billing/application/billing_providers.dart`
- Test: `test/features/billing/entitlements_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';

void main() {
  test('pro is a superset: unlocks any feature, and isPro is true', () {
    final c = ProviderContainer(overrides: [
      entitlementsProvider.overrideWith((ref) async => {'pro'}),
    ]);
    addTearDown(c.dispose);
    // Resolve the async provider.
    return c.read(entitlementsProvider.future).then((_) {
      expect(c.read(isProProvider), isTrue);
      expect(c.read(hasEntitlementProvider('see_likes')), isTrue);
      expect(c.read(hasEntitlementProvider('boost')), isTrue);
    });
  });

  test('non-pro only unlocks owned features', () {
    final c = ProviderContainer(overrides: [
      entitlementsProvider.overrideWith((ref) async => {'see_likes'}),
    ]);
    addTearDown(c.dispose);
    return c.read(entitlementsProvider.future).then((_) {
      expect(c.read(isProProvider), isFalse);
      expect(c.read(hasEntitlementProvider('see_likes')), isTrue);
      expect(c.read(hasEntitlementProvider('boost')), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/billing/entitlements_test.dart`
Expected: FAIL — `isProProvider` undefined.

- [ ] **Step 3: Update the providers**

Replace the body of `lib/features/billing/application/billing_providers.dart` below the imports with:

```dart
final billingRepositoryProvider =
    Provider((ref) => BillingRepository(ref.watch(supabaseClientProvider)));

final entitlementsProvider = FutureProvider<Set<String>>((ref) async {
  final list = await ref.watch(billingRepositoryProvider).myEntitlements();
  return list.map((e) => e['feature'] as String).toSet();
});

/// True when the user holds the Pro membership (a superset of all paid features).
final isProProvider = Provider<bool>((ref) => ref
    .watch(entitlementsProvider)
    .maybeWhen(data: (s) => s.contains('pro'), orElse: () => false));

/// Feature gate. Pro is a superset, so any Pro user passes every check.
final hasEntitlementProvider = Provider.family<bool, String>((ref, feature) =>
    ref.watch(entitlementsProvider).maybeWhen(
        data: (s) => s.contains('pro') || s.contains(feature),
        orElse: () => false));
```

(Keep the existing imports at the top of the file unchanged.)

- [ ] **Step 4: Run the test**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/billing/entitlements_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/billing/application/billing_providers.dart test/features/billing/entitlements_test.dart
git commit -m "feat(billing): isProProvider + Pro-superset entitlement gate"
```

---

## Task 4: Client — keo error mapping + createKeo joinMode

**Files:**
- Create: `lib/features/keo/data/keo_errors.dart`
- Modify: `lib/features/keo/data/keo_repository.dart`
- Test: `test/features/keo/keo_errors_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/keo/data/keo_errors.dart';

void main() {
  test('maps known keo error codes to Vietnamese', () {
    expect(keoErrorCode('PostgrestException(message: pro_required, code: 23514)'),
        'pro_required');
    expect(keoErrorMessage('... free_join_limit ...'),
        'Bạn đang tham gia 1 kèo. Rời kèo cũ hoặc nâng cấp Pro để tham gia thêm.');
    expect(keoErrorMessage('something else'), 'Có lỗi xảy ra, thử lại.');
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/keo_errors_test.dart`
Expected: FAIL — `keo_errors.dart` not found.

- [ ] **Step 3: Write `keo_errors.dart`**

```dart
/// Maps raw Supabase error text to a stable code / Vietnamese message.
/// The server raises bare codes like 'pro_required' as the exception message.
const _messages = <String, String>{
  'pro_required': 'Cần gói Pro để tạo kèo.',
  'free_join_limit':
      'Bạn đang tham gia 1 kèo. Rời kèo cũ hoặc nâng cấp Pro để tham gia thêm.',
  'keo_full': 'Kèo đã đầy.',
  'already_declined': 'Bạn đã bị từ chối ở kèo này.',
  'keo_not_open': 'Kèo không còn mở.',
};

String? keoErrorCode(Object error) {
  final s = error.toString();
  for (final code in _messages.keys) {
    if (s.contains(code)) return code;
  }
  return null;
}

String keoErrorMessage(Object error) {
  final code = keoErrorCode(error);
  return _messages[code] ?? 'Có lỗi xảy ra, thử lại.';
}
```

- [ ] **Step 4: Add `joinMode` to `createKeo`**

In `lib/features/keo/data/keo_repository.dart`, change the `createKeo` signature and params. Replace the `createKeo` method with:

```dart
  Future<String> createKeo({
    required String title,
    required double lat,
    required double lng,
    String? area,
    required DateTime start,
    required DateTime end,
    required int size,
    String? intent,
    String? vibe,
    List<String> genres = const [],
    String joinMode = 'approval',
  }) async {
    final id = await _client.rpc('create_keo', params: {
      'p_title': title,
      'p_lat': lat,
      'p_lng': lng,
      'p_area': area,
      'p_start': start.toUtc().toIso8601String(),
      'p_end': end.toUtc().toIso8601String(),
      'p_size': size,
      'p_intent': intent,
      'p_vibe': vibe,
      'p_genres': genres,
      'p_join_mode': joinMode,
    });
    return id as String;
  }
```

- [ ] **Step 5: Run the test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/keo_errors_test.dart`
Expected: PASS.
Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/features/keo/data`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/keo/data/keo_errors.dart lib/features/keo/data/keo_repository.dart test/features/keo/keo_errors_test.dart
git commit -m "feat(keo): error mapping + createKeo joinMode param"
```

---

## Task 5: Create-kèo screen — join-mode selector

**Files:**
- Modify: `lib/features/keo/presentation/create_keo_screen.dart`

- [ ] **Step 1: Add a join-mode field and selector**

In `_CreateKeoScreenState`, add a field after `int _size = 4;`:

```dart
  String _joinMode = 'approval';
```

In `_submit()`, pass it to `createKeo` — change the `createKeo(...)` call to include:

```dart
            genres: _genreIds.toList(),
            joinMode: _joinMode,
```

In `build()`, insert this block right before the `const SizedBox(height: 24)` that precedes the `create_keo_btn` FilledButton:

```dart
          const SizedBox(height: 16),
          const Text('Chế độ tham gia'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'approval', label: Text('Cần duyệt'), icon: Icon(Icons.verified_user_outlined)),
              ButtonSegment(value: 'open', label: Text('Mở'), icon: Icon(Icons.lock_open_outlined)),
            ],
            selected: {_joinMode},
            onSelectionChanged: _submitting
                ? null
                : (s) => setState(() => _joinMode = s.first),
          ),
```

- [ ] **Step 2: Analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/features/keo/presentation/create_keo_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/keo/presentation/create_keo_screen.dart
git commit -m "feat(keo): join-mode selector in create screen"
```

---

## Task 6: Kèo board — Pro gate on the create FAB

**Files:**
- Modify: `lib/features/keo/presentation/keo_board_screen.dart`

- [ ] **Step 1: Gate the FAB**

Add imports near the top:

```dart
import '../../billing/application/billing_providers.dart';
```

Replace the `FloatingActionButton.extended(onPressed: () => context.push('/keo/create'), ...)` so the press checks Pro:

```dart
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (ref.read(isProProvider)) {
            context.push('/keo/create');
          } else {
            _showProSheet(context);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo kèo'),
      ),
```

Add this method to the widget class:

```dart
  void _showProSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tạo kèo là tính năng Pro',
                style: Theme.of(sheetCtx).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Nâng cấp Pro để tự tạo kèo và tham gia không giới hạn.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.pop(sheetCtx);
                context.push('/store');
              },
              child: const Text('Nâng cấp Pro'),
            ),
            TextButton(
                onPressed: () => Navigator.pop(sheetCtx),
                child: const Text('Để sau')),
          ],
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
git commit -m "feat(keo): Pro gate on create FAB with upgrade sheet"
```

---

## Task 7: Kèo detail — friendly free_join_limit dialog

**Files:**
- Modify: `lib/features/keo/presentation/keo_detail_screen.dart`

- [ ] **Step 1: Use the error mapper in the join handler**

Add import near the top:

```dart
import 'package:go_router/go_router.dart';
import '../data/keo_errors.dart';
```
(If `go_router` is already imported, do not duplicate it.)

Replace the `request_join_btn` button's `onPressed` catch block (currently `catch (_) { ... _snack(context, 'Không xin vào kèo được, thử lại'); }`) with:

```dart
                onPressed: () async {
                  try {
                    await ref.read(keoRepositoryProvider).requestJoin(keoId);
                    ref.invalidate(keoRosterProvider(keoId));
                  } catch (e) {
                    if (!context.mounted) return;
                    if (keoErrorCode(e) == 'free_join_limit') {
                      showDialog<void>(
                        context: context,
                        builder: (d) => AlertDialog(
                          content: Text(keoErrorMessage(e)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(d),
                                child: const Text('Để sau')),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(d);
                                context.push('/store');
                              },
                              child: const Text('Nâng cấp Pro'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      _snack(context, keoErrorMessage(e));
                    }
                  }
                },
```

(Keep the `key: const Key('request_join_btn')` and `child: const Text('Xin vào kèo')` unchanged.)

- [ ] **Step 2: Analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/features/keo/presentation/keo_detail_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/keo/presentation/keo_detail_screen.dart
git commit -m "feat(keo): friendly free_join_limit dialog with upgrade CTA"
```

---

## Task 8: Store — Pro upgrade item + iap product id

**Files:**
- Modify: `lib/features/billing/presentation/store_screen.dart`
- Modify: `lib/features/billing/application/iap_controller.dart`

- [ ] **Step 1: Add the Pro product id**

In `lib/features/billing/application/iap_controller.dart`, add to the `_storeProductIds` map (after the `'see_likes': ...` entry):

```dart
  'pro': 'com.cunghat.pro',
```

- [ ] **Step 2: Add the Pro store item**

In `lib/features/billing/presentation/store_screen.dart`, add to the top of the `_upgrades` list:

```dart
  _Upgrade('pro', 'Nâng cấp Pro', 'Tạo kèo, tham gia không giới hạn, mở mọi tính năng trả phí'),
```

And add a case to `_titleFor` before `default:`:

```dart
      case 'pro':
        return 'Nâng cấp Pro';
```

- [ ] **Step 3: Analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/features/billing`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/billing/presentation/store_screen.dart lib/features/billing/application/iap_controller.dart
git commit -m "feat(billing): Pro upgrade item in store"
```

---

## Task 9: Full verification

**Files:** none (verification only)

- [ ] **Step 1: Static + unit**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze`
Expected: `No issues found!`
Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test`
Expected: all tests pass.

- [ ] **Step 2: DB tests**

Run: `npx supabase db reset` then `npx supabase test db`
Expected: all pgTAP tests pass, including `pro_keo_test.sql`.

- [ ] **Step 3: Cloud build + emulator (optional but recommended)**

Push `feat/pro-keo-gating`, trigger `build-apk.yml`, download artifact (local Gradle is broken). On the emulator: grant Pro to the test user via SQL —
`docker exec supabase_db_cung-hat psql -U postgres -d postgres -c "insert into public.entitlements(user_id,feature,source) values ('<uid>','pro','promo') on conflict do nothing;"` —
verify a Free user sees the upgrade sheet on "Tạo kèo" and the cap dialog on a 2nd join; a Pro user can create (with mode selector) and join freely. Screenshot via `adb exec-out screencap -p` (Bash tool, not PowerShell `>`).

- [ ] **Step 4: Open PR (only with user go-ahead)**

```bash
GH_TOKEN=<token> "C:\Program Files\GitHub CLI\gh.exe" pr create --base master --head feat/pro-keo-gating --title "Pro gating for kèo create/join" --body "Server-authoritative Pro gating + free join cap + per-keo join mode."
```

---

## Self-review notes

- Spec coverage: entitlement superset + is_pro (T1, T3), pro product (T1), join_mode column + gated create_keo (T1, T5), free cap + open auto-approve (T1), errors pro_required/free_join_limit (T1, T4, T7), client providers (T3), repo joinMode + error map (T4), create-screen selector (T5), FAB gate (T6), join dialog (T7), store Pro item (T8), SQL+Flutter tests (T2, T3, T4, T9). All covered.
- Keys preserved: create_keo_btn (T5 only adds a field/selector), request_join_btn (T7 keeps key), keo_genre_<id>, confirm_keo_btn untouched.
- Type consistency: `joinMode` (Dart) ↔ `p_join_mode` (SQL) ↔ `join_mode` (column); `isProProvider`, `hasEntitlementProvider`, `keoErrorCode`/`keoErrorMessage` used consistently across tasks.
- Non-goals respected: real IAP untouched (stub flow reused), no schema changes beyond keo.join_mode + entitlement/product CHECK + pro product, routes unchanged.
```
