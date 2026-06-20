# Cùng Hát — P4 Venues & Plan (Midpoint Music-Box Picker) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn a confirmed kèo (or 1-1 match) into a real outing: compute the **fair geographic midpoint of all members**, suggest the **nearest K-style music-box venues** to that point, let everyone confirm a plan, and wrap it with the offline-safety toolkit (share-plan link + "Tôi đã tới" check-in).

**Architecture:** Builds on P0–P3. Migration adds `venues` (+ seed for HCMC/HN/TN), a server-side **midpoint via `ST_GeometricMedian`** over members' (server-only) locations, and `nearest_venues_for_keo` returning sanitized venues ordered by distance to the midpoint. A second migration adds `plans` + `plan_confirmations` + `checkins` + `share_plans` with propose/confirm/checkin/share RPCs. **Google Places (New) ingestion** runs in an Edge Function that upserts real karaoke/music-box venues into the same `venues` table (`source='places'`) — the picker includes them automatically, no RPC change. Flutter adds a `plan` feature (venue picker + confirm state + safety toolkit).

> **Operational pre-req (Places):** a Google Maps Platform project with **billing enabled** and **Places API (New)** turned on; the key goes in Edge env `GOOGLE_PLACES_API_KEY` (never in the client). Seed venues (Task 1) work without it; Places ingestion (Task 6) needs it.

**Tech Stack:** PostGIS (`ST_GeometricMedian`, `ST_Collect`, KNN `<->`), SECURITY DEFINER RPCs, Riverpod 3, freezed, mocktail.

**Depends on:** P1 (`user_locations`, `dist_band`), P3 (`keo`, `keo_members`, `in_keo`, `assert_host`), P0 (RPC pattern). Privacy rule from spec: member coords never leave the server; only public venue data + bucketed distance are returned.

---

### Task 1: Migration 0014 — venues + seed + midpoint venue picker

**Files:**
- Create: `supabase/migrations/0014_venues.sql`, `supabase/tests/venues_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0014_venues.sql`:
```sql
create table public.venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null,
  city text not null check (city in ('HCM','HN','TN')),
  location geography(Point,4326) not null,        -- public business location (exposable)
  style_tag text not null default 'k_style' check (style_tag in ('k_style','family','bar_karaoke')),
  photos text[] not null default '{}',
  source text not null default 'seed' check (source in ('seed','places')),
  places_id text,
  is_active boolean not null default true
);
create index venues_geo_gix on public.venues using gist (location);
alter table public.venues enable row level security;
create policy venues_read on public.venues for select using (is_active);

-- Seed a few K-style boxes per launch city (replace with a fuller curated set pre-launch).
insert into public.venues (name, address, city, location, style_tag) values
  ('Kingdom Karaoke','Q1, TP.HCM','HCM', ST_SetSRID(ST_MakePoint(106.700,10.776),4326)::geography,'k_style'),
  ('Nnice Karaoke','Bình Thạnh, TP.HCM','HCM', ST_SetSRID(ST_MakePoint(106.712,10.804),4326)::geography,'k_style'),
  ('Kpop Karaoke','Cầu Giấy, Hà Nội','HN', ST_SetSRID(ST_MakePoint(105.795,21.030),4326)::geography,'k_style'),
  ('Idol Karaoke','Đống Đa, Hà Nội','HN', ST_SetSRID(ST_MakePoint(105.825,21.012),4326)::geography,'k_style'),
  ('Sao Mai Karaoke','TP. Thái Nguyên','TN', ST_SetSRID(ST_MakePoint(105.842,21.594),4326)::geography,'k_style'),
  ('Galaxy Karaoke','ĐH Thái Nguyên','TN', ST_SetSRID(ST_MakePoint(105.800,21.567),4326)::geography,'k_style');

-- Sanitized venue suggestion (public venue + bucketed distance to the group's midpoint).
create type public.venue_suggestion as (
  id uuid, name text, address text, style_tag text, photos text[], distance_band text
);

-- Fair midpoint = geometric median of confirmed members' points (minimizes total travel).
create or replace function public.nearest_venues_for_keo(p_keo uuid, p_limit int default 5)
returns setof public.venue_suggestion language plpgsql security definer set search_path='' as $$
declare mid geography;
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;
  select ST_GeometricMedian(ST_Collect(ul.location::geometry))::geography
    into mid
  from public.keo_members m
  join public.user_locations ul on ul.user_id = m.user_id
  where m.keo_id = p_keo and m.join_status='approved' and m.confirmed;

  return query
    select v.id, v.name, v.address, v.style_tag, v.photos,
           app_private.dist_band(ST_Distance(v.location, mid)) as distance_band
    from public.venues v
    where v.is_active
    order by v.location <-> mid          -- KNN nearest to the fair midpoint
    limit greatest(p_limit, 1);
end; $$;
revoke execute on function public.nearest_venues_for_keo(uuid,int) from public, anon;
grant execute on function public.nearest_venues_for_keo(uuid,int) to authenticated;
```

- [ ] **Step 2: Write a DB test (suggestion type carries no coords; seeds present)**

Create `supabase/tests/venues_test.sql`:
```sql
begin;
select plan(2);
select hasnt_column('public','venue_suggestion'::regtype::text,'location','venue_suggestion has no raw coords');
select ok((select count(*) from public.venues) >= 6, 'venue seed present');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean; assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0014_venues.sql supabase/tests/venues_test.sql
git commit -m "feat(p4): 0014 venues + seed + nearest_venues_for_keo (geometric-median midpoint)"
```

---

### Task 2: Migration 0015 — plans, confirmations, checkins, share links

**Files:**
- Create: `supabase/migrations/0015_plans.sql`, `supabase/tests/plans_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0015_plans.sql`:
```sql
create table public.plans (
  id uuid primary key default gen_random_uuid(),
  keo_id uuid not null references public.keo(id) on delete cascade,
  venue_id uuid not null references public.venues(id),
  scheduled_at timestamptz not null,
  status text not null default 'proposed' check (status in ('proposed','confirmed','done','cancelled')),
  created_at timestamptz not null default now()
);
alter table public.plans enable row level security;
create policy plans_member_read on public.plans for select using (app_private.in_keo(keo_id));

create table public.plan_confirmations (
  plan_id uuid references public.plans(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  confirmed_at timestamptz not null default now(),
  primary key (plan_id, user_id)
);
alter table public.plan_confirmations enable row level security;
create policy plan_conf_self on public.plan_confirmations for all
  using (auth.uid()=user_id) with check (auth.uid()=user_id);

create table public.checkins (
  plan_id uuid references public.plans(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  arrived_at timestamptz not null default now(),
  primary key (plan_id, user_id)
);
alter table public.checkins enable row level security;
create policy checkins_member on public.checkins for all
  using (exists (select 1 from public.plans p where p.id=plan_id and app_private.in_keo(p.keo_id)))
  with check (auth.uid()=user_id);

create table public.share_plans (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid references public.plans(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  share_token text not null unique default encode(gen_random_bytes(16),'hex'),
  expires_at timestamptz not null default (now() + interval '1 day')
);
alter table public.share_plans enable row level security;
create policy share_plans_owner on public.share_plans for all
  using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- Host proposes a plan (keo must be in planning); members then confirm.
create or replace function public.propose_keo_plan(p_keo uuid, p_venue uuid, p_when timestamptz)
returns uuid language plpgsql security definer set search_path='' as $$
declare pid uuid;
begin
  perform app_private.assert_host(p_keo);
  insert into public.plans(keo_id, venue_id, scheduled_at) values (p_keo, p_venue, p_when)
  returning id into pid;
  return pid;
end; $$;

-- A member confirms the plan; when all approved members confirmed → plan + keo 'confirmed'.
create or replace function public.confirm_keo_plan(p_plan uuid)
returns void language plpgsql security definer set search_path='' as $$
declare kid uuid; approved_n int; confirmed_n int;
begin
  select keo_id into kid from public.plans where id=p_plan;
  if not app_private.in_keo(kid) then raise exception 'not_in_keo' using errcode='check_violation'; end if;
  insert into public.plan_confirmations(plan_id, user_id) values (p_plan, auth.uid())
  on conflict do nothing;
  select count(*) filter (where m.join_status='approved'),
         (select count(*) from public.plan_confirmations c where c.plan_id=p_plan)
    into approved_n, confirmed_n
  from public.keo_members m where m.keo_id=kid;
  if approved_n >= 2 and confirmed_n >= approved_n then
    update public.plans set status='confirmed' where id=p_plan;
    update public.keo set status='confirmed' where id=kid;
  end if;
end; $$;

create or replace function public.checkin_arrived(p_plan uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.checkins(plan_id, user_id) values (p_plan, auth.uid())
  on conflict do nothing;
end; $$;

create or replace function public.create_share_link(p_plan uuid)
returns text language plpgsql security definer set search_path='' as $$
declare tok text;
begin
  insert into public.share_plans(plan_id, user_id) values (p_plan, auth.uid())
  returning share_token into tok;
  return tok;
end; $$;

revoke execute on function public.propose_keo_plan(uuid,uuid,timestamptz) from public, anon;
revoke execute on function public.confirm_keo_plan(uuid) from public, anon;
revoke execute on function public.checkin_arrived(uuid) from public, anon;
revoke execute on function public.create_share_link(uuid) from public, anon;
grant execute on function public.propose_keo_plan(uuid,uuid,timestamptz) to authenticated;
grant execute on function public.confirm_keo_plan(uuid) to authenticated;
grant execute on function public.checkin_arrived(uuid) to authenticated;
grant execute on function public.create_share_link(uuid) to authenticated;
```

- [ ] **Step 2: Write a DB test**

Create `supabase/tests/plans_test.sql`:
```sql
begin;
select plan(1);
select ok(exists(select 1 from pg_proc where proname='confirm_keo_plan'), 'confirm_keo_plan exists');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean; assertion passes (0001–0015 apply).

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0015_plans.sql supabase/tests/plans_test.sql
git commit -m "feat(p4): 0015 plans/confirmations/checkins/share links + RPCs"
```

---

### Task 3: Venue + Plan models, PlanRepository, providers

**Files:**
- Create: `lib/features/plan/domain/venue_suggestion.dart`, `lib/features/plan/data/plan_repository.dart`, `lib/features/plan/application/plan_providers.dart`
- Test: `test/features/plan/plan_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/plan/plan_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('nearestVenues maps suggestions', () async {
    final client = _MockClient();
    when(() => client.rpc('nearest_venues_for_keo', params: any(named: 'params')))
        .thenAnswer((_) async => [
              {'id': 'v1', 'name': 'Kingdom', 'address': 'Q1', 'style_tag': 'k_style',
               'photos': <String>[], 'distance_band': '1-3'},
            ]);
    final list = await PlanRepository(client).nearestVenues('k1');
    expect(list.single.name, 'Kingdom');
    expect(list.single.distanceBand, '1-3');
  });

  test('proposePlan calls propose_keo_plan', () async {
    final client = _MockClient();
    when(() => client.rpc('propose_keo_plan', params: any(named: 'params')))
        .thenAnswer((_) async => 'p1');
    final id = await PlanRepository(client).proposePlan('k1', 'v1', DateTime.utc(2026, 6, 21, 19));
    expect(id, 'p1');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/plan/plan_repository_test.dart`
Expected: FAIL — files not found.

- [ ] **Step 3: Implement model + repo + providers**

Create `lib/features/plan/domain/venue_suggestion.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'venue_suggestion.freezed.dart';
part 'venue_suggestion.g.dart';

@freezed
class VenueSuggestion with _$VenueSuggestion {
  const factory VenueSuggestion({
    required String id,
    required String name,
    required String address,
    @JsonKey(name: 'style_tag') @Default('k_style') String styleTag,
    @Default([]) List<String> photos,
    @JsonKey(name: 'distance_band') String? distanceBand,
  }) = _VenueSuggestion;
  factory VenueSuggestion.fromJson(Map<String, dynamic> j) => _$VenueSuggestionFromJson(j);
}
```

Create `lib/features/plan/data/plan_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/venue_suggestion.dart';

class PlanRepository {
  PlanRepository(this._client);
  final SupabaseClient _client;

  Future<List<VenueSuggestion>> nearestVenues(String keoId, {int limit = 5}) async {
    final rows = await _client.rpc('nearest_venues_for_keo',
        params: {'p_keo': keoId, 'p_limit': limit});
    return (rows as List).map((e) => VenueSuggestion.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<String> proposePlan(String keoId, String venueId, DateTime when) async {
    final id = await _client.rpc('propose_keo_plan',
        params: {'p_keo': keoId, 'p_venue': venueId, 'p_when': when.toUtc().toIso8601String()});
    return id as String;
  }

  Future<void> confirmPlan(String planId) =>
      _client.rpc('confirm_keo_plan', params: {'p_plan': planId});
  Future<void> checkInArrived(String planId) =>
      _client.rpc('checkin_arrived', params: {'p_plan': planId});
  Future<String> createShareLink(String planId) async =>
      await _client.rpc('create_share_link', params: {'p_plan': planId}) as String;
}
```

Create `lib/features/plan/application/plan_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/plan_repository.dart';
import '../domain/venue_suggestion.dart';

final planRepositoryProvider =
    Provider((ref) => PlanRepository(ref.watch(supabaseClientProvider)));
final nearestVenuesProvider = FutureProvider.family<List<VenueSuggestion>, String>(
    (ref, keoId) => ref.watch(planRepositoryProvider).nearestVenues(keoId));
```

- [ ] **Step 4: Generate + run test**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" pub run build_runner build --delete-conflicting-outputs
& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/plan/plan_repository_test.dart
```
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```
git add lib/features/plan/ test/features/plan/plan_repository_test.dart
git commit -m "feat(p4): VenueSuggestion model + PlanRepository (nearest/propose/confirm/checkin/share)"
```

---

### Task 4: Plan screen (midpoint venue picker + confirm) + route

**Files:**
- Create: `lib/features/plan/presentation/plan_screen.dart`
- Modify: `lib/app/router.dart` (`/keo/plan/:id`), `lib/features/keo/presentation/keo_detail_screen.dart` (host "Chốt quán" button when planning)
- Test: `test/features/plan/plan_screen_test.dart`

- [ ] **Step 1: Write the failing widget test (venues render + propose)**

Create `test/features/plan/plan_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/domain/venue_suggestion.dart';
import 'package:cung_hat/features/plan/presentation/plan_screen.dart';

class _MockRepo extends Mock implements PlanRepository {}

void main() {
  testWidgets('lists nearest venues with their distance band', (tester) async {
    final repo = _MockRepo();
    when(() => repo.nearestVenues('k1', limit: any(named: 'limit'))).thenAnswer((_) async =>
        const [VenueSuggestion(id: 'v1', name: 'Kingdom', address: 'Q1', distanceBand: '1-3')]);
    await tester.pumpWidget(ProviderScope(
      overrides: [planRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: PlanScreen(keoId: 'k1', isHost: true)),
    ));
    await tester.pump();
    expect(find.text('Kingdom'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/plan/plan_screen_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement PlanScreen + wire**

Create `lib/features/plan/presentation/plan_screen.dart` — a `ConsumerWidget(keoId, isHost)` watching `nearestVenuesProvider(keoId)`: lists venue suggestions (name + address + "gợi ý vì gần điểm cân bằng cả nhóm · cách {band} km"). If `isHost`, each venue has a "Chọn quán này" action + a time picker → `proposePlan`; for members, a "Đồng ý kế hoạch" button → `confirmPlan`. Add route `GoRoute(path:'/keo/plan/:id', builder:(_,s)=>PlanScreen(keoId:s.pathParameters['id']!, isHost: s.uri.queryParameters['host']=='1'))`. In `keo_detail_screen.dart`, when keo status is `planning` and the user is host, show a "Chốt quán" button → `/keo/plan/{id}?host=1`; for members show "Xem kế hoạch" → `/keo/plan/{id}`.

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/plan/plan_screen_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add lib/features/plan/presentation/plan_screen.dart lib/app/router.dart lib/features/keo/presentation/keo_detail_screen.dart test/features/plan/plan_screen_test.dart
git commit -m "feat(p4): plan screen (midpoint venue picker + propose/confirm) + wiring"
```

---

### Task 5: Safety toolkit (share plan + "Tôi đã tới") + acceptance

**Files:**
- Create: `lib/features/plan/presentation/safety_toolkit.dart`
- Modify: `pubspec.yaml` (share_plus), `lib/features/plan/presentation/plan_screen.dart` (toolkit on a confirmed plan)
- Test: `test/features/plan/safety_toolkit_test.dart`

- [ ] **Step 1: Add share_plus + write the failing test (check-in calls repo)**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" pub add share_plus`
Create `test/features/plan/safety_toolkit_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/plan/application/plan_providers.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';
import 'package:cung_hat/features/plan/presentation/safety_toolkit.dart';

class _MockRepo extends Mock implements PlanRepository {}

void main() {
  testWidgets('tapping "Tôi đã tới" calls checkInArrived', (tester) async {
    final repo = _MockRepo();
    when(() => repo.checkInArrived('p1')).thenAnswer((_) async {});
    await tester.pumpWidget(ProviderScope(
      overrides: [planRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: SafetyToolkit(planId: 'p1'))),
    ));
    await tester.tap(find.byKey(const Key('checkin_btn')));
    await tester.pump();
    verify(() => repo.checkInArrived('p1')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/plan/safety_toolkit_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement SafetyToolkit**

Create `lib/features/plan/presentation/safety_toolkit.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../application/plan_providers.dart';

class SafetyToolkit extends ConsumerWidget {
  const SafetyToolkit({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(planRepositoryProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FilledButton.tonalIcon(
          onPressed: () async {
            final token = await repo.createShareLink(planId);
            await Share.share('Mình đi hát, đây là kế hoạch: cunghat://plan/$token');
          },
          icon: const Icon(Icons.ios_share),
          label: const Text('Chia sẻ cho bạn bè'),
        ),
        FilledButton.icon(
          key: const Key('checkin_btn'),
          onPressed: () => repo.checkInArrived(planId),
          icon: const Icon(Icons.place),
          label: const Text('Tôi đã tới'),
        ),
      ],
    );
  }
}
```
In `plan_screen.dart`: when the plan status is `confirmed`, render `SafetyToolkit(planId: ...)`.

- [ ] **Step 4: Run test + full suite + analyze**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" test
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
```
Expected: all green; `No issues found!`.

- [ ] **Step 5: Acceptance — full plan loop**

With a kèo in `planning` (from P3 acceptance): host opens "Chốt quán" → sees venues ordered by nearness to the **group's geometric-median midpoint** with bucketed bands → picks one + a time → members tap "Đồng ý kế hoạch" → when all confirm, plan + keo flip to `confirmed`; the safety toolkit appears; "Chia sẻ cho bạn bè" creates a token link; "Tôi đã tới" inserts a check-in. Verify a non-member cannot call `nearest_venues_for_keo`/`confirm_keo_plan`.

- [ ] **Step 6: Commit**

```
git add pubspec.yaml pubspec.lock lib/features/plan/ test/features/plan/safety_toolkit_test.dart
git commit -m "feat(p4): safety toolkit (share plan + I've-arrived check-in) + P4 acceptance"
```

---

### Task 6: Google Places (New) venue ingestion (Edge Function)

**Files:**
- Create: `supabase/migrations/0016_venue_places.sql`, `supabase/functions/ingest-places-venues/index.ts`

- [ ] **Step 1: Migration — make `places_id` upsertable**

Create `supabase/migrations/0016_venue_places.sql`:
```sql
-- Partial unique index so the ingester can upsert on places_id.
create unique index if not exists venues_places_id_ux
  on public.venues (places_id) where places_id is not null;
```
Run: `supabase db reset` (applies 0001–0016 clean).

- [ ] **Step 2: Write the ingestion Edge Function (ops-only, secret-gated)**

Create `supabase/functions/ingest-places-venues/index.ts`:
```ts
import { createClient } from "jsr:@supabase/supabase-js@2";

// Ops-only: invoked manually per city. Secret-gated; NEVER exposed to the app.
Deno.serve(async (req) => {
  if (req.headers.get("x-ingest-secret") !== Deno.env.get("PLACES_INGEST_SECRET")) {
    return new Response("forbidden", { status: 403 });
  }
  const { city, lat, lng, radius_m = 5000, style_tag = "k_style" } = await req.json();
  const res = await fetch("https://places.googleapis.com/v1/places:searchNearby", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": Deno.env.get("GOOGLE_PLACES_API_KEY")!,
      "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location",
    },
    body: JSON.stringify({
      includedTypes: ["karaoke"],
      maxResultCount: 20,
      locationRestriction: { circle: { center: { latitude: lat, longitude: lng }, radius: radius_m } },
    }),
  });
  const data = await res.json();
  const places: any[] = data.places ?? [];
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  let upserted = 0;
  for (const p of places) {
    const row = {
      name: p.displayName?.text ?? "Karaoke",
      address: p.formattedAddress ?? "",
      city,
      location: `SRID=4326;POINT(${p.location.longitude} ${p.location.latitude})`, // EWKT → geography
      style_tag,
      source: "places",
      places_id: p.id,
      is_active: true,
    };
    const { error } = await sb.from("venues").upsert(row, { onConflict: "places_id" });
    if (!error) upserted++;
  }
  return new Response(JSON.stringify({ found: places.length, upserted }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

- [ ] **Step 3: Set secrets + serve**

Set local secrets (do NOT commit real keys): add to `supabase/functions/.env` (git-ignored) `GOOGLE_PLACES_API_KEY=...`, `PLACES_INGEST_SECRET=dev-secret`. Run: `supabase functions serve ingest-places-venues --env-file supabase/functions/.env`.

- [ ] **Step 4: Invoke per launch city + verify rows land**

For each city centre invoke (PowerShell `Invoke-RestMethod` or curl), e.g. HCM Q1:
```
curl -X POST http://127.0.0.1:54321/functions/v1/ingest-places-venues \
  -H "x-ingest-secret: dev-secret" -H "Content-Type: application/json" \
  -d '{"city":"HCM","lat":10.776,"lng":106.700,"radius_m":6000}'
```
Repeat for HN (21.030,105.795) and TN (21.594,105.842).
Expected: JSON `{found, upserted}` > 0; in Studio, `select count(*) from venues where source='places'` > 0; and `nearest_venues_for_keo` now returns Places venues mixed with seeds (no code change — it reads `venues`).

- [ ] **Step 5: Commit (code only; keys stay in the git-ignored .env)**

```
git add supabase/migrations/0016_venue_places.sql supabase/functions/ingest-places-venues/index.ts
git commit -m "feat(p4): Google Places (New) venue ingestion Edge Function (source='places')"
```

---

## Self-Review (completed by author)

- **Spec coverage:** nearest music-box **between members** via server-side **geometric-median midpoint** ✓ (T1 `nearest_venues_for_keo`); seeded venues for HCM/HN/TN ✓ (T1); **Google Places (New) ingestion** into the same `venues` table (`source='places'`, picker unchanged) ✓ (T6); propose → all-members-confirm plan ✓ (T2,T4); safety toolkit (share-plan link + "Tôi đã tới") ✓ (T2,T5); privacy preserved (member coords server-only, only public venues + bands returned) ✓ (T1). 1-1 plan reuse and the no-show rating UI are deferred (spec); P4 covers the kèo plan loop.
- **Placeholder scan:** none — every code step concrete. T4 Step 3 assembles defined providers/repo; `cunghat://plan/{token}` deep-link resolution is a P7 launch detail (the token + link generation ship here).
- **Type consistency:** RPC names identical across SQL and Dart — `nearest_venues_for_keo`, `propose_keo_plan`, `confirm_keo_plan`, `checkin_arrived`, `create_share_link`; `VenueSuggestion` JSON keys match the `venue_suggestion` type (`style_tag`, `distance_band`); reuses P3 `in_keo`/`assert_host`/`keo_members`, P1 `dist_band`/`user_locations`; `PlanRepository` method set consistent T3↔T4↔T5.

---

## Next plans (when we reach them)
- **P5** Compliance & moderation: reports queue + 24h/48h takedown, soft-delete/tombstone across UGC, audit log, consent management + data export/delete screens, Privacy/ToS.
- **P6** Monetization: store IAP (boost/see-likes/filters) + entitlements; MoMo/ZaloPay venue-booking commission (Edge Function + webhook).
- **P7** Launch: 3-city seeding, FCM push, deep-link (`cunghat://plan/{token}`) resolution, store submission.
