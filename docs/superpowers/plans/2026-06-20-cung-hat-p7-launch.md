# Cùng Hát — P7 Launch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship to the three launch cities: FCM push, the PDPL scheduled hard-delete, share-plan deep-link resolution, a repeatable 3-city seeding + Places-ingestion run, app icon/splash, and a store-submission checklist.

**Architecture:** Builds on P0–P6. Migration adds `device_tokens` + `register_device_token`, and a `pg_cron` job that calls a `purge-deleted` Edge Function for retention hard-deletes. A `push-fanout` Edge Function sends FCM on key DB events. Flutter wires `firebase_messaging`, resolves `cunghat://plan/{token}` deep links to a read-only plan view, and adds the launcher icon/splash.

**Tech Stack:** Supabase `pg_cron` + `pg_net` + Edge Functions, Firebase Cloud Messaging (`firebase_messaging`), `app_links`/deep-linking, `flutter_launcher_icons` + `flutter_native_splash`.

**Depends on:** P2/P3 (chat events), P4 (`plans`/`share_plans`/Places ingest), P5 (soft-delete/tombstone), P6 (bookings). **Operational pre-reqs:** Firebase project + FCM service account (Edge env); Google Maps billing (P4); store accounts (P6); per-city seed content + founding cohort.

---

### Task 1: Migration 0020 — device tokens + retention purge schedule

**Files:**
- Create: `supabase/migrations/0020_launch.sql`, `supabase/tests/launch_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0020_launch.sql`:
```sql
create extension if not exists pg_cron;
create extension if not exists pg_net;

create table public.device_tokens (
  user_id uuid references auth.users(id) on delete cascade,
  fcm_token text not null,
  platform text not null check (platform in ('ios','android')),
  updated_at timestamptz not null default now(),
  primary key (user_id, fcm_token)
);
alter table public.device_tokens enable row level security;
create policy device_tokens_self on public.device_tokens for all
  using (auth.uid()=user_id) with check (auth.uid()=user_id);

create or replace function public.register_device_token(p_token text, p_platform text)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.device_tokens(user_id, fcm_token, platform)
  values (auth.uid(), p_token, p_platform)
  on conflict (user_id, fcm_token) do update set updated_at = now();
end; $$;
revoke execute on function public.register_device_token(text,text) from public, anon;
grant execute on function public.register_device_token(text,text) to authenticated;

-- Daily retention hard-delete: profiles tombstoned > 30 days ago are purged from auth.users
-- (cascades remove their data). Runs as a SECURITY DEFINER routine invoked by pg_cron.
create or replace function app_private.purge_expired_accounts()
returns void language plpgsql security definer set search_path='' as $$
begin
  delete from auth.users u
  using public.profiles p
  where p.id = u.id and p.tombstone and p.soft_deleted_at < now() - interval '30 days';
end; $$;

select cron.schedule('purge-deleted-daily', '0 3 * * *', $$ select app_private.purge_expired_accounts(); $$);
```

- [ ] **Step 2: Write a DB test**

Create `supabase/tests/launch_test.sql`:
```sql
begin;
select plan(2);
select ok(exists(select 1 from pg_proc where proname='register_device_token'), 'register_device_token exists');
select ok(exists(select 1 from cron.job where jobname='purge-deleted-daily'), 'purge cron scheduled');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean (0001–0020); assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0020_launch.sql supabase/tests/launch_test.sql
git commit -m "feat(p7): 0020 device_tokens + register RPC + daily retention purge (pg_cron)"
```

---

### Task 2: Edge Function `push-fanout` (FCM on key events)

**Files:**
- Create: `supabase/functions/push-fanout/index.ts`

- [ ] **Step 1: Write the function**

Create `supabase/functions/push-fanout/index.ts`:
```ts
import { createClient } from "jsr:@supabase/supabase-js@2";

// Invoked (by DB trigger via pg_net, or directly) with {user_ids, title, body, data}.
// Looks up FCM tokens (service role) and sends via FCM HTTP v1. Secrets Edge-only.
Deno.serve(async (req) => {
  if (req.headers.get("x-fanout-secret") !== Deno.env.get("PUSH_FANOUT_SECRET")) {
    return new Response("forbidden", { status: 403 });
  }
  const { user_ids, title, body, data } = await req.json();
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: tokens } = await admin.from("device_tokens")
    .select("fcm_token").in("user_id", user_ids ?? []);
  // TODO(prod): obtain an OAuth access token from GOOGLE_FCM_SA_JSON and POST to
  // https://fcm.googleapis.com/v1/projects/<project>/messages:send for each token.
  const sent = (tokens ?? []).length;
  console.log(`[push-fanout] would send "${title}" to ${sent} tokens`, { data });
  return new Response(JSON.stringify({ sent }), { headers: { "Content-Type": "application/json" } });
});
```

- [ ] **Step 2: Add DB triggers that fan out (new message / join request / approval / plan confirm)**

Create `supabase/migrations/0021_push_triggers.sql` — `AFTER INSERT` triggers (SECURITY DEFINER) on `messages` (notify thread participants except sender), `keo_members` requested (notify host), approval update (notify member), and `plans`/`plan_confirmations` (notify members) that call `net.http_post(...)` to the `push-fanout` URL with the `x-fanout-secret`. Keep payloads minimal (ids + a localized-key, not message bodies). Run `supabase db reset` to apply.

- [ ] **Step 3: Serve + smoke**

Run: `supabase functions serve push-fanout --env-file supabase/functions/.env`; insert a test message and confirm the function logs the intended send count. (Real FCM send wired when the service account exists.)

- [ ] **Step 4: Commit**

```
git add supabase/functions/push-fanout/index.ts supabase/migrations/0021_push_triggers.sql
git commit -m "feat(p7): push-fanout Edge Function + DB triggers (messages/joins/plans)"
```

---

### Task 3: FCM client wiring

**Files:**
- Modify: `pubspec.yaml` (firebase_core, firebase_messaging), `lib/main.dart`
- Create: `lib/core/push/push_service.dart`
- Test: `test/core/push_service_test.dart`

- [ ] **Step 1: Add packages + write the failing test (register forwards token)**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" pub add firebase_core firebase_messaging`
Create `test/core/push_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/core/push/push_service.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('registerToken calls register_device_token RPC', () async {
    final client = _MockClient();
    when(() => client.rpc('register_device_token', params: any(named: 'params')))
        .thenAnswer((_) async => null);
    await PushService(client).registerToken('tok', 'android');
    verify(() => client.rpc('register_device_token',
        params: {'p_token': 'tok', 'p_platform': 'android'})).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/core/push_service_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement PushService + init**

Create `lib/core/push/push_service.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PushService {
  PushService(this._client);
  final SupabaseClient _client;
  Future<void> registerToken(String token, String platform) =>
      _client.rpc('register_device_token', params: {'p_token': token, 'p_platform': platform});
}
```
In `main.dart`: after sign-in, `Firebase.initializeApp()` (guarded so tests/dev without `google-services.json` skip), request notification permission, get the FCM token, and call `PushService.registerToken`; listen to `onTokenRefresh`. Wrap in try/catch so a missing Firebase config never crashes dev.

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/core/push_service_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add pubspec.yaml pubspec.lock lib/core/push/ lib/main.dart test/core/push_service_test.dart
git commit -m "feat(p7): FCM client wiring (register device token, guarded init)"
```

---

### Task 4: Share-plan deep link resolution

**Files:**
- Create: `supabase/migrations/0022_share_resolve.sql`, `lib/features/plan/presentation/shared_plan_screen.dart`
- Modify: `pubspec.yaml` (app_links), `lib/app/router.dart`, `lib/main.dart`
- Test: `test/features/plan/share_resolve_test.dart`

- [ ] **Step 1: Migration — token resolver RPC**

Create `supabase/migrations/0022_share_resolve.sql`:
```sql
-- Public-by-token read of a shared plan (venue + time only; no member identities).
create type public.shared_plan_view as (venue_name text, address text, scheduled_at timestamptz, expired boolean);
create or replace function public.resolve_share_plan(p_token text)
returns public.shared_plan_view language sql security definer set search_path='' as $$
  select v.name, v.address, pl.scheduled_at, (sp.expires_at < now())
  from public.share_plans sp
  join public.plans pl on pl.id = sp.plan_id
  join public.venues v on v.id = pl.venue_id
  where sp.share_token = p_token;
$$;
-- Resolvable without login (a friend may not have the app) → grant to anon too.
grant execute on function public.resolve_share_plan(text) to anon, authenticated;
```
Run `supabase db reset`.

- [ ] **Step 2: Add app_links + write the failing test (repo resolves token)**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" pub add app_links`
Create `test/features/plan/share_resolve_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('resolveShare calls resolve_share_plan', () async {
    final client = _MockClient();
    when(() => client.rpc('resolve_share_plan', params: any(named: 'params')))
        .thenAnswer((_) async => {'venue_name': 'Kingdom', 'address': 'Q1',
          'scheduled_at': '2026-06-21T19:00:00Z', 'expired': false});
    final v = await PlanRepository(client).resolveShare('tok');
    expect(v['venue_name'], 'Kingdom');
  });
}
```

- [ ] **Step 3: Implement repo method + screen + deep-link handling**

Append to `plan_repository.dart`:
```dart
  Future<Map<String, dynamic>> resolveShare(String token) async {
    final res = await _client.rpc('resolve_share_plan', params: {'p_token': token});
    return Map<String, dynamic>.from(res as Map);
  }
```
Create `lib/features/plan/presentation/shared_plan_screen.dart` — takes a token, calls `resolveShare`, shows venue + address + time (or "link hết hạn"). Add route `/plan/shared/:token`. In `main.dart`, use `app_links` to map incoming `cunghat://plan/{token}` (and an https universal link) to `context.go('/plan/shared/$token')`.

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/plan/share_resolve_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add supabase/migrations/0022_share_resolve.sql pubspec.yaml pubspec.lock lib/features/plan/ lib/app/router.dart lib/main.dart test/features/plan/share_resolve_test.dart
git commit -m "feat(p7): share-plan deep link resolution (cunghat://plan/{token})"
```

---

### Task 5: 3-city seeding script + Places ingestion run

**Files:**
- Create: `scripts/seed_launch.sql`, `scripts/run_places_ingest.sh`, `docs/LAUNCH.md`

- [ ] **Step 1: Author the per-city seed**

Create `scripts/seed_launch.sql` — inserts a small set of **curated K-style venues** and **founding host-created kèo** for HN, HCM, TN (so each city's board is alive on day one). Idempotent (`on conflict do nothing`).

- [ ] **Step 2: Author the Places ingestion runner**

Create `scripts/run_places_ingest.sh` — calls the P4 `ingest-places-venues` function for each city centre (HCM 10.776,106.700 · HN 21.030,105.795 · TN 21.594,105.842) with the ops secret. Document required env in `docs/LAUNCH.md`.

- [ ] **Step 3: Run + verify board liquidity**

Apply `scripts/seed_launch.sql` (psql / Studio) + run `scripts/run_places_ingest.sh` against the target project. Verify each city: `list_open_keos` returns ≥ a few kèo and `nearest_venues_for_keo` returns venues.

- [ ] **Step 4: Commit**

```
git add scripts/seed_launch.sql scripts/run_places_ingest.sh docs/LAUNCH.md
git commit -m "feat(p7): 3-city launch seeding + Places ingestion runner"
```

---

### Task 6: App icon + splash + store submission checklist

**Files:**
- Modify: `pubspec.yaml` (flutter_launcher_icons, flutter_native_splash), `assets/` (icon)
- Create: `docs/STORE_SUBMISSION.md`

- [ ] **Step 1: Brand assets**

Add `flutter_launcher_icons` + `flutter_native_splash` (dev deps); add a brand icon `assets/icon/cung_hat.png`; configure both in `pubspec.yaml` (magenta→violet brand). Generate:
```
& "C:\Users\Public\flutter\bin\flutter.bat" pub run flutter_launcher_icons
& "C:\Users\Public\flutter\bin\flutter.bat" pub run flutter_native_splash:create
```

- [ ] **Step 2: Store checklist doc**

Create `docs/STORE_SUBMISSION.md` covering: bundle ids, App Store/Play listing copy (VI+EN), age rating 18+, privacy nutrition labels / Data Safety form (location, contacts-none, account, cross-border), IAP products + tax/banking, Decree-147 license status note, content-moderation contact, screenshots, and the deep-link/universal-link association files (`apple-app-site-association`, `assetlinks.json`).

- [ ] **Step 3: Final full-suite gate**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze` and `... test`
Expected: `No issues found!`; all tests green across P0–P7.

- [ ] **Step 4: Acceptance — release candidate**

A clean `supabase db reset` applies all migrations (0001–0022) + `supabase test db` passes; the app boots, full happy path works (signup → taste → Đôi match → chat → Kèo → plan/venue → booking + safety), push registers a token, a shared link resolves, and the moderation console + PDPL surfaces work. Tag `v1-rc1`.

- [ ] **Step 5: Commit + tag**

```
git add pubspec.yaml pubspec.lock android/ ios/ assets/ docs/STORE_SUBMISSION.md
git commit -m "feat(p7): app icon/splash + store submission checklist + v1-rc"
git tag v1-rc1
```

---

## Self-Review (completed by author)

- **Spec coverage:** FCM push (matches/joins/messages/plans) ✓ (T2,T3); PDPL scheduled hard-delete after retention ✓ (T1); share-plan deep-link resolution ✓ (T4); 3-city seeding + Places ingestion run ✓ (T5); app icon/splash + store submission checklist ✓ (T6). The Decree-147 license + entity paperwork and PDPL TIA dossier remain **operational** (tracked in spec §15) — not code; this plan ships the technical launch surface + the checklist that references them.
- **Placeholder scan:** `TODO(prod)` markers are limited to the external FCM send (needs the FCM service account) and any provider calls — explicitly labelled. Seed/checklist docs are content the operator fills with real venues/listing copy. No undefined Dart symbols.
- **Type consistency:** RPC names `register_device_token`/`resolve_share_plan` identical SQL↔Dart; Edge fn names `push-fanout`/`ingest-places-venues` (reused from P4) match dirs; `cunghat://plan/{token}` identical in P4 `create_share_link` output, P7 router route, and the deep-link handler; reuses P4 `share_plans`/`plans`/`venues`, P5 soft-delete/tombstone for the purge, P3 `keo`/`list_open_keos` for board liquidity checks.

---

## Done — P0→P7 plans complete.
All eight implementation plans (P0, P0.2, P0.3, P1–P7) cover the full spec. Recommended execution: subagent-driven-development, phase by phase, with `flutter analyze` + `flutter test` + `supabase db reset`/`supabase test db` green gates between phases.
