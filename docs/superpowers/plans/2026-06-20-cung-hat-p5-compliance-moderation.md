# Cùng Hát — P5 Compliance & Moderation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the app launch-legal for Vietnam: a role-gated moderation console (reports queue → 24h/48h takedown with soft-delete + tombstone + audit log, per Decree 147), plus PDPL user-rights surfaces — consent management (view/withdraw), data export, and account+data deletion — and Privacy/ToS screens.

**Architecture:** Builds on P0–P4. Migration adds `admins` + `moderation_audit` + an `is_admin` helper + admin RPCs that act on existing `reports` and soft-delete/tombstone the target (`messages`/`keo`/`profiles` already carry the columns). A second migration adds `export_my_data` + `request_account_deletion`. Flutter adds an `admin` moderation screen (role-gated, runs on web) and `settings` surfaces for consent/export/delete + static Privacy/ToS.

**Tech Stack:** SECURITY DEFINER RPCs + role gating, Supabase, Riverpod 3, mocktail.

**Depends on:** P1 (`reports`, `blocks`), P0.3 (`consents`, `record_consent`), P0 (`profiles` soft_delete/tombstone), P3 (`keo`), P2 (`messages`).

---

### Task 1: Migration 0017 — admins, moderation audit, admin RPCs

**Files:**
- Create: `supabase/migrations/0017_moderation.sql`, `supabase/tests/moderation_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0017_moderation.sql`:
```sql
create table public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security; -- no client policy; checked in RPCs

create or replace function app_private.is_admin()
returns boolean language sql security definer set search_path='' stable as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

create table public.moderation_audit (
  id uuid primary key default gen_random_uuid(),
  actor uuid not null references auth.users(id),
  action text not null check (action in ('hide','remove','restore','dismiss')),
  target_type text not null,
  target_id text not null,
  reason text,
  created_at timestamptz not null default now()
);
alter table public.moderation_audit enable row level security; -- admin-only via RPC

-- Reports queue for the console (admin only).
create or replace function public.admin_list_reports(p_status text default 'open')
returns setof public.reports language sql security definer set search_path='' as $$
  select r.* from public.reports r
  where app_private.is_admin() and (p_status is null or r.status = p_status)
  order by r.created_at asc;
$$;

-- Take action: hide/remove the target (soft-delete + tombstone) or dismiss; always audit.
create or replace function public.admin_action_report(p_report uuid, p_action text, p_reason text default null)
returns void language plpgsql security definer set search_path='' as $$
declare r public.reports;
begin
  if not app_private.is_admin() then raise exception 'not_admin' using errcode='check_violation'; end if;
  select * into r from public.reports where id = p_report;
  if not found then raise exception 'no_report'; end if;

  if p_action in ('hide','remove') then
    if r.target_type = 'message' then
      update public.messages set hidden=true,
        soft_deleted_at = case when p_action='remove' then now() else soft_deleted_at end
        where id = r.target_id::uuid;
    elsif r.target_type = 'keo' then
      update public.keo set soft_deleted_at = now(), status='cancelled' where id = r.target_id::uuid;
    elsif r.target_type = 'profile' then
      update public.profiles set soft_deleted_at = now() where id = r.target_id::uuid;
      update public.profiles set report_risk = report_risk + 1 where id = r.target_id::uuid;
    end if;
    update public.reports set status='actioned' where id = p_report;
  elsif p_action = 'dismiss' then
    update public.reports set status='dismissed' where id = p_report;
  end if;

  insert into public.moderation_audit(actor, action, target_type, target_id, reason)
  values (auth.uid(), p_action, r.target_type, r.target_id, p_reason);
end; $$;

revoke execute on function public.admin_list_reports(text) from public, anon;
revoke execute on function public.admin_action_report(uuid,text,text) from public, anon;
grant execute on function public.admin_list_reports(text) to authenticated;     -- gated by is_admin inside
grant execute on function public.admin_action_report(uuid,text,text) to authenticated;
```

- [ ] **Step 2: Write a DB test (non-admin denied)**

Create `supabase/tests/moderation_test.sql`:
```sql
begin;
select plan(2);
select ok(exists(select 1 from pg_proc where proname='admin_action_report'), 'admin RPC exists');
set local role authenticated;
select throws_ok(
  $$ select public.admin_action_report('00000000-0000-0000-0000-000000000000'::uuid,'dismiss') $$,
  'check_violation', null, 'non-admin cannot moderate');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean; assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0017_moderation.sql supabase/tests/moderation_test.sql
git commit -m "feat(p5): 0017 admins + moderation audit + report queue/action RPCs (soft-delete/tombstone)"
```

---

### Task 2: Migration 0018 — data export + account deletion (PDPL)

**Files:**
- Create: `supabase/migrations/0018_pdpl.sql`, `supabase/tests/pdpl_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0018_pdpl.sql`:
```sql
-- Export everything the user owns as one JSON document.
create or replace function public.export_my_data()
returns jsonb language sql security definer set search_path='' as $$
  select jsonb_build_object(
    'profile', (select to_jsonb(p) - 'report_risk' from public.profiles p where p.id = auth.uid()),
    'genres',  (select coalesce(jsonb_agg(genre_id), '[]'::jsonb) from public.user_genres where user_id = auth.uid()),
    'artists', (select coalesce(jsonb_agg(artist_id),'[]'::jsonb) from public.user_artists where user_id = auth.uid()),
    'baitu',   (select coalesce(jsonb_agg(song_id),  '[]'::jsonb) from public.user_baitu where user_id = auth.uid()),
    'consents',(select coalesce(jsonb_agg(to_jsonb(c)),'[]'::jsonb) from public.consents c where c.user_id = auth.uid())
  );
$$;

-- Soft-delete now (immediate UX), tombstone for the retention window; a scheduled
-- Edge Function (P7) performs the hard delete + auth.users removal after the window.
create or replace function public.request_account_deletion()
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.profiles
    set soft_deleted_at = now(), tombstone = true,
        display_name = 'Người dùng đã rời', full_name = null, bio = null
    where id = auth.uid();
  update public.keo set status='cancelled', soft_deleted_at=now() where host_id = auth.uid() and status <> 'done';
  update public.keo_members set join_status='left' where user_id = auth.uid();
  update public.matches set status='unmatched', unmatched_at=now() where user_a=auth.uid() or user_b=auth.uid();
end; $$;

revoke execute on function public.export_my_data() from public, anon;
revoke execute on function public.request_account_deletion() from public, anon;
grant execute on function public.export_my_data() to authenticated;
grant execute on function public.request_account_deletion() to authenticated;
```

- [ ] **Step 2: Write a DB test**

Create `supabase/tests/pdpl_test.sql`:
```sql
begin;
select plan(2);
select ok(exists(select 1 from pg_proc where proname='export_my_data'), 'export_my_data exists');
select ok(exists(select 1 from pg_proc where proname='request_account_deletion'), 'deletion RPC exists');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean (0001–0018); assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0018_pdpl.sql supabase/tests/pdpl_test.sql
git commit -m "feat(p5): 0018 PDPL export_my_data + request_account_deletion"
```

---

### Task 3: Moderation repository + admin reports screen (role-gated)

**Files:**
- Create: `lib/features/admin/data/moderation_repository.dart`, `lib/features/admin/application/admin_providers.dart`, `lib/features/admin/presentation/moderation_screen.dart`
- Modify: `lib/app/router.dart` (`/admin`)
- Test: `test/features/admin/moderation_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/admin/moderation_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/admin/data/moderation_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('listReports calls admin_list_reports', () async {
    final client = _MockClient();
    when(() => client.rpc('admin_list_reports', params: any(named: 'params')))
        .thenAnswer((_) async => [
              {'id': 'r1', 'target_type': 'profile', 'target_id': 'u2', 'reason': 'spam', 'status': 'open'},
            ]);
    final list = await ModerationRepository(client).listReports();
    expect(list.single.id, 'r1');
  });

  test('action calls admin_action_report', () async {
    final client = _MockClient();
    when(() => client.rpc('admin_action_report', params: any(named: 'params')))
        .thenAnswer((_) async => null);
    await ModerationRepository(client).action('r1', 'remove', reason: 'abuse');
    verify(() => client.rpc('admin_action_report',
        params: {'p_report': 'r1', 'p_action': 'remove', 'p_reason': 'abuse'})).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/admin/moderation_repository_test.dart`
Expected: FAIL — files not found.

- [ ] **Step 3: Implement repo + providers + screen + route**

Create `lib/features/admin/data/moderation_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class Report {
  Report({required this.id, required this.targetType, required this.targetId, this.reason, required this.status});
  final String id; final String targetType; final String targetId; final String? reason; final String status;
  factory Report.fromJson(Map<String, dynamic> j) => Report(
    id: j['id'] as String, targetType: j['target_type'] as String,
    targetId: j['target_id'] as String, reason: j['reason'] as String?, status: j['status'] as String);
}

class ModerationRepository {
  ModerationRepository(this._client);
  final SupabaseClient _client;

  Future<List<Report>> listReports({String status = 'open'}) async {
    final rows = await _client.rpc('admin_list_reports', params: {'p_status': status});
    return (rows as List).map((e) => Report.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> action(String reportId, String action, {String? reason}) =>
      _client.rpc('admin_action_report',
          params: {'p_report': reportId, 'p_action': action, 'p_reason': reason});
}
```

Create `lib/features/admin/application/admin_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/moderation_repository.dart';

final moderationRepositoryProvider =
    Provider((ref) => ModerationRepository(ref.watch(supabaseClientProvider)));
final openReportsProvider = FutureProvider<List<Report>>(
    (ref) => ref.watch(moderationRepositoryProvider).listReports());
```

Create `lib/features/admin/presentation/moderation_screen.dart` — a `ConsumerWidget` watching `openReportsProvider`: a list of reports each with reason + target + buttons "Ẩn" (`action(id,'hide')`), "Gỡ" (`action(id,'remove')`), "Bỏ qua" (`action(id,'dismiss')`), invalidating the list after each. Add route `GoRoute(path:'/admin', builder:(_, __) => const ModerationScreen())`. (Access is RPC-gated by `is_admin`; non-admins get empty/permission errors. Bootstrap an admin once via SQL: `insert into public.admins(user_id) values ('<uid>');`.)

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/admin/moderation_repository_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add lib/features/admin/ lib/app/router.dart test/features/admin/moderation_repository_test.dart
git commit -m "feat(p5): moderation console (reports queue + hide/remove/dismiss), role-gated"
```

---

### Task 4: PDPL settings — consent management + export + delete

**Files:**
- Create: `lib/features/settings/data/settings_repository.dart`, `lib/features/settings/presentation/settings_screen.dart`
- Modify: `lib/app/home_shell.dart` (tab 3 "Hồ sơ" → add a Settings entry) or add `/settings` route
- Test: `test/features/settings/settings_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/settings/settings_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('exportMyData calls export_my_data', () async {
    final client = _MockClient();
    when(() => client.rpc('export_my_data')).thenAnswer((_) async => {'profile': {}});
    final data = await SettingsRepository(client).exportMyData();
    expect(data.containsKey('profile'), isTrue);
  });

  test('withdrawConsent calls record_consent with granted=false', () async {
    final client = _MockClient();
    when(() => client.rpc('record_consent', params: any(named: 'params')))
        .thenAnswer((_) async => null);
    await SettingsRepository(client).withdrawConsent('marketing');
    verify(() => client.rpc('record_consent', params: {
      'p_purpose': 'marketing', 'p_granted': false, 'p_policy_version': 'v1',
    })).called(1);
  });

  test('deleteAccount calls request_account_deletion', () async {
    final client = _MockClient();
    when(() => client.rpc('request_account_deletion')).thenAnswer((_) async => null);
    await SettingsRepository(client).deleteAccount();
    verify(() => client.rpc('request_account_deletion')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/settings/settings_repository_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement repo + screen + route**

Create `lib/features/settings/data/settings_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

const kPolicyVersion = 'v1';

class SettingsRepository {
  SettingsRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> exportMyData() async {
    final res = await _client.rpc('export_my_data');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<void> withdrawConsent(String purpose) => _client.rpc('record_consent',
      params: {'p_purpose': purpose, 'p_granted': false, 'p_policy_version': kPolicyVersion});

  Future<void> grantConsent(String purpose) => _client.rpc('record_consent',
      params: {'p_purpose': purpose, 'p_granted': true, 'p_policy_version': kPolicyVersion});

  Future<void> deleteAccount() => _client.rpc('request_account_deletion');
}
```

Create `lib/features/settings/presentation/settings_screen.dart` — a `ConsumerWidget` (route `/settings`) with sections: **Quyền riêng tư** (consent switches reusing `consentPurposes`/labels → grant/withdraw), **Dữ liệu của tôi** ("Tải dữ liệu" → `exportMyData` then share/save the JSON via share_plus), **Tài khoản** ("Xoá tài khoản" with a confirm dialog → `deleteAccount` then `signOut`), **Pháp lý** (links to Privacy/ToS — Task 5), language toggle. Add `/settings` route and a gear entry on the "Hồ sơ" tab.

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/settings/settings_repository_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add lib/features/settings/ lib/app/router.dart lib/app/home_shell.dart test/features/settings/settings_repository_test.dart
git commit -m "feat(p5): PDPL settings (consent mgmt + data export + account deletion)"
```

---

### Task 5: Privacy Policy + ToS screens (VI) + l10n + acceptance

**Files:**
- Create: `lib/features/legal/presentation/legal_screen.dart`, `assets/legal/privacy_vi.md`, `assets/legal/tos_vi.md`
- Modify: `pubspec.yaml` (assets), `lib/l10n/*.arb`

- [ ] **Step 1: Add VI legal copy as bundled assets**

Create `assets/legal/privacy_vi.md` and `assets/legal/tos_vi.md` with the v1 Vietnamese policy text (must state: data controller, data stored at **Supabase Singapore (cross-border transfer)**, what is collected, purposes, user rights export/withdraw/delete, retention, contact). Register `assets/legal/` under `flutter: assets:` in `pubspec.yaml`.

- [ ] **Step 2: Implement the viewer + routes**

Create `lib/features/legal/presentation/legal_screen.dart` — loads the bundled markdown by `rootBundle.loadString` and renders it scrollably. Add routes `/legal/privacy` and `/legal/tos`; link them from the onboarding consent step (P0.3) and Settings (Task 4). Add l10n keys `privacyTitle`, `tosTitle`, `settingsTitle`, `exportData`, `deleteAccount`, `deleteConfirm` to both ARBs + `gen-l10n`.

- [ ] **Step 3: Full suite + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test` then `... analyze`
Expected: all green; `No issues found!`.

- [ ] **Step 4: Acceptance — moderation + PDPL round-trips**

Bootstrap an admin (`insert into public.admins(user_id) values ('<your uid>')`). Report a profile (P1 report sheet) → it appears in `/admin` → tap "Gỡ" → target `soft_deleted_at` set + `moderation_audit` row + report `actioned`. In Settings: "Tải dữ liệu" returns the JSON export; withdraw a consent → `consents.granted=false`; "Xoá tài khoản" soft-deletes the profile + signs out. Privacy/ToS render from assets.

- [ ] **Step 5: Commit**

```
git add lib/features/legal/ assets/legal/ pubspec.yaml lib/l10n/
git commit -m "feat(p5): Privacy/ToS screens (VI) + legal l10n + P5 acceptance"
```

---

## Self-Review (completed by author)

- **Spec coverage:** moderation console + reports queue ✓ (T1,T3); 24h/48h takedown via hide/remove with **soft-delete + tombstone + audit log** ✓ (T1); consent management view/withdraw ✓ (T2,T4); data export ✓ (T2,T4); account+data deletion ✓ (T2,T4); Privacy/ToS surfaced ✓ (T5); cross-border disclosure in the privacy text ✓ (T5). The scheduled **hard-delete** Edge Function (after the retention window) and full SLA timers are P7 launch hardening; P5 ships the legal-required user-facing rights + moderation actions.
- **Placeholder scan:** none — every code step is concrete; T3/T4/T5 screens assemble already-defined repos/providers and reuse P0.3 `consentPurposes`/labels and `record_consent`. No undefined symbols.
- **Type consistency:** RPC names identical across SQL and Dart — `admin_list_reports`, `admin_action_report`, `export_my_data`, `request_account_deletion`, `record_consent` (reused from P0.3 with `p_purpose/p_granted/p_policy_version`); `kPolicyVersion='v1'` matches P0.3's onboarding policy version; `is_admin` gate reused by both admin RPCs; soft-delete columns (`soft_deleted_at`, `tombstone`, `hidden`) already defined in P0/P1/P3 migrations.

---

## Next plans (when we reach them)
- **P6** Monetization: store IAP (boost/see-likes/filters) + `entitlements` after server-side receipt validation; MoMo/ZaloPay **venue-booking commission** via Edge Function + gateway webhook (store-policy split: digital goods = IAP only; real-world service = local gateway).
- **P7** Launch: scheduled hard-delete Edge Function, 3-city seeding + Places ingestion run, FCM push, deep-link (`cunghat://plan/{token}`) resolution, store submission.
