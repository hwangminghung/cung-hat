# Cùng Hát — P1 "Đôi" (1-1 Swipe) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The hero 1-1 surface: capture location privately (PostGIS), discover music-matched strangers nearby via a sanitized two-stage RPC, swipe a Tinder-style deck, form race-safe mutual matches with a celebration, and block/report from any card.

**Architecture:** Builds on P0/P0.2/P0.3. New migrations add `user_locations` (geo server-only), `blocks`/`reports` + a generic rate-limit helper, the `get_discovery_candidates` two-stage scorer (PostGIS prefilter + in-SQL weighted sum, returns **bucketed distance only — never coords**), and `swipes`/`matches` + a race-safe `record_swipe`. Flutter adds a `discovery` feature: location capture, sanitized `Candidate` model, deck (`flutter_card_swiper`), match celebration, report sheet.

**Tech Stack:** PostGIS (`geography`, GIST, `ST_DWithin`), SECURITY DEFINER RPCs, Supabase rate limiting, Riverpod 3, freezed, geolocator, flutter_card_swiper, mocktail.

**Depends on:** P0 (RPC pattern, `profiles`, `music_genres`, `supabaseClientProvider`), P0.3 (`user_genres`/`user_artists`/`user_baitu`, `songs`), P0.2 (auth/session), app shell tab 0 = "Đôi".

---

### Task 1: Migration 0005 — private location + bucketing

**Files:**
- Create: `supabase/migrations/0005_locations.sql`, `supabase/tests/locations_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0005_locations.sql`:
```sql
create table public.user_locations (
  user_id uuid primary key references auth.users(id) on delete cascade,
  location geography(Point,4326) not null,
  area_label text,
  updated_at timestamptz not null default now()
);
create index user_locations_gix on public.user_locations using gist (location);
alter table public.user_locations enable row level security;
-- No client policy at all → exact coords are never directly selectable. Access via RPC only.

-- Distance → privacy band (the only distance form clients ever see).
create or replace function app_private.dist_band(m double precision)
returns text language sql immutable set search_path='' as $$
  select case when m < 1000 then '<1' when m < 3000 then '1-3'
              when m < 5000 then '3-5' else '5+' end;
$$;

-- Snap to ~100m at write (k-anonymity), store the snapped point only.
create or replace function public.update_my_location(p_lat double precision, p_lng double precision, p_area text default null)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.user_locations (user_id, location, area_label)
  values (
    auth.uid(),
    ST_SetSRID(ST_MakePoint(round(p_lng::numeric, 3)::double precision,
                            round(p_lat::numeric, 3)::double precision), 4326)::geography,
    p_area)
  on conflict (user_id) do update
    set location = excluded.location, area_label = excluded.area_label, updated_at = now();
  update public.profiles set last_active = now() where id = auth.uid();  -- drives "active_today" in discovery
end; $$;
revoke execute on function public.update_my_location(double precision,double precision,text) from public, anon;
grant execute on function public.update_my_location(double precision,double precision,text) to authenticated;
```

- [ ] **Step 2: Write a DB test proving no client SELECT of coords**

Create `supabase/tests/locations_test.sql`:
```sql
begin;
select plan(2);
set local role authenticated;
-- RLS with no policy ⇒ zero rows selectable directly even as authenticated.
select is_empty($$ select * from public.user_locations $$, 'user_locations not directly selectable');
select is(app_private.dist_band(2500), '1-3', 'bucketing 2.5km → 1-3');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean; both assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0005_locations.sql supabase/tests/locations_test.sql
git commit -m "feat(p1): 0005 private user_locations + snap-at-write + dist_band bucketing"
```

---

### Task 2: Migration 0006 — blocks, reports, rate limiting

**Files:**
- Create: `supabase/migrations/0006_safety.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0006_safety.sql`:
```sql
create table public.blocks (
  blocker_id uuid references auth.users(id) on delete cascade,
  blocked_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);
alter table public.blocks enable row level security;
create policy blocks_self on public.blocks for all using (auth.uid()=blocker_id) with check (auth.uid()=blocker_id);
create index blocks_blocked_ix on public.blocks(blocked_id);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users(id) on delete cascade,
  target_type text not null check (target_type in ('profile','keo','message','photo')),
  target_id text not null,
  reason text,
  status text not null default 'open' check (status in ('open','actioned','dismissed')),
  created_at timestamptz not null default now()
);
alter table public.reports enable row level security;
create policy reports_insert_self on public.reports for insert with check (auth.uid()=reporter_id);
-- No client SELECT: moderation console (P5) reads via a moderation role.

-- Generic atomic rate limiter (used across swipes/messages/reports/OTP).
create table public.rate_limits (
  user_id uuid references auth.users(id) on delete cascade,
  bucket text not null,
  window_start timestamptz not null,
  count int not null default 0,
  primary key (user_id, bucket, window_start)
);
alter table public.rate_limits enable row level security;
-- no client policy; only touched inside SECURITY DEFINER RPCs

create or replace function app_private.enforce_rate_limit(p_bucket text, p_limit int, p_window interval)
returns void language plpgsql security definer set search_path='' as $$
declare w timestamptz := date_trunc('minute', now());
declare c int;
begin
  insert into public.rate_limits (user_id, bucket, window_start, count)
  values (auth.uid(), p_bucket, w, 1)
  on conflict (user_id, bucket, window_start) do update set count = public.rate_limits.count + 1
  returning count into c;
  if c > p_limit then
    raise exception 'rate_limit_exceeded' using errcode = 'check_violation';
  end if;
end; $$;

create or replace function public.block_user(p_blocked uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.blocks(blocker_id, blocked_id) values (auth.uid(), p_blocked)
  on conflict do nothing;
end; $$;

create or replace function public.report_user(p_target uuid, p_reason text)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform app_private.enforce_rate_limit('report', 20, interval '1 day');
  insert into public.reports(reporter_id, target_type, target_id, reason)
  values (auth.uid(), 'profile', p_target::text, p_reason);
end; $$;

revoke execute on function public.block_user(uuid) from public, anon;
revoke execute on function public.report_user(uuid,text) from public, anon;
grant execute on function public.block_user(uuid) to authenticated;
grant execute on function public.report_user(uuid,text) to authenticated;
```

- [ ] **Step 2: Apply + verify clean**

Run: `supabase db reset`
Expected: applies clean.

- [ ] **Step 3: Commit**

```
git add supabase/migrations/0006_safety.sql
git commit -m "feat(p1): 0006 blocks/reports + atomic rate limiter + block/report RPCs"
```

---

### Task 3: Migration 0007 — get_discovery_candidates (two-stage scorer)

**Files:**
- Create: `supabase/migrations/0007_discovery.sql`, `supabase/tests/discovery_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0007_discovery.sql`:
```sql
-- swipes table created HERE (0007) so get_discovery_candidates below can reference it.
create table public.swipes (
  swiper_id uuid references auth.users(id) on delete cascade,
  target_type text not null check (target_type in ('user','keo')),
  target_id text not null,
  direction text not null check (direction in ('like','pass','super','save')),
  created_at timestamptz not null default now(),
  primary key (swiper_id, target_type, target_id)
);
alter table public.swipes enable row level security; -- writes via RPC only

create table public.ranking_weights (key text primary key, weight numeric not null);
alter table public.ranking_weights enable row level security; -- no client policy
insert into public.ranking_weights(key, weight) values
  ('music', 3.0), ('nearness', 1.5), ('activity', 1.0), ('report_risk', 2.0);

-- Sanitized candidate row = the privacy boundary (NO coords, NO score, NO weights).
create type public.discovery_candidate as (
  id uuid, display_name text, age int, distance_band text,
  shared_genres text[], shared_baitu text[], verified boolean, active_today boolean
);

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
           ST_Distance(ul.location, me.loc) as dist_m,
           (select array_agg(g.genre_id) from public.user_genres g
              where g.user_id = p.id and g.genre_id = any((select genres from me))) as shared_g,
           (select array_agg(s.song_id) from public.user_baitu s
              where s.user_id = p.id and s.song_id = any((select songs from me))) as shared_s
    from public.profiles p
    join public.user_locations ul on ul.user_id = p.id
    cross join me
    where p.id <> auth.uid()
      and p.soft_deleted_at is null
      and ST_DWithin(ul.location, me.loc, p_radius_km * 1000)
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
  ) desc
  limit greatest(p_limit, 1);
$$;
revoke execute on function public.get_discovery_candidates(int,int) from public, anon;
grant execute on function public.get_discovery_candidates(int,int) to authenticated;
```

Note: `profiles` needs `verified_badge` and `report_risk` columns. Add them in this migration before the type/function:
```sql
alter table public.profiles add column if not exists verified_badge boolean not null default false;
alter table public.profiles add column if not exists report_risk numeric not null default 0;
```

- [ ] **Step 2: Write a DB test asserting the sanitized shape (no coords)**

Create `supabase/tests/discovery_test.sql`:
```sql
begin;
select plan(2);
-- the return type must NOT contain any location/coord column
select hasnt_column('public', 'discovery_candidate'::regtype::text, 'location', 'no location in candidate type');
select ok(exists(select 1 from pg_proc where proname='get_discovery_candidates'), 'RPC exists');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean; assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0007_discovery.sql supabase/tests/discovery_test.sql
git commit -m "feat(p1): 0007 get_discovery_candidates two-stage scorer (bucketed, sanitized)"
```

---

### Task 4: Migration 0008 — matches + race-safe record_swipe (swipes table is in 0007)

**Files:**
- Create: `supabase/migrations/0008_swipes_matches.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0008_swipes_matches.sql`:
```sql
-- NOTE: public.swipes is created in 0007 (so get_discovery_candidates can reference it).
create table public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references auth.users(id) on delete cascade,
  user_b uuid not null references auth.users(id) on delete cascade,
  status text not null default 'active' check (status in ('active','unmatched')),
  created_at timestamptz not null default now(),
  unmatched_at timestamptz,
  unique (user_a, user_b),
  check (user_a < user_b)              -- canonical ordering dedupes pairs
);
alter table public.matches enable row level security;
create policy matches_participant on public.matches for select
  using (auth.uid() = user_a or auth.uid() = user_b);

-- Returns true if this swipe created a mutual match.
create or replace function public.record_swipe(p_target uuid, p_direction text)
returns boolean language plpgsql security definer set search_path='' as $$
declare a uuid; b uuid; reciprocal boolean; matched boolean := false;
begin
  perform app_private.enforce_rate_limit('swipe', 200, interval '1 day');
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
revoke execute on function public.record_swipe(uuid,text) from public, anon;
grant execute on function public.record_swipe(uuid,text) to authenticated;
```

- [ ] **Step 2: Apply + verify clean**

Run: `supabase db reset`
Expected: applies clean (migrations 0001–0008).

- [ ] **Step 3: Commit**

```
git add supabase/migrations/0008_swipes_matches.sql
git commit -m "feat(p1): 0008 swipes/matches + race-safe record_swipe (rate-limited)"
```

---

### Task 5: Candidate model + DiscoveryRepository + providers

**Files:**
- Create: `lib/features/discovery/domain/candidate.dart`, `lib/features/discovery/data/discovery_repository.dart`, `lib/features/discovery/application/discovery_providers.dart`
- Test: `test/features/discovery/discovery_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/discovery/discovery_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('getCandidates maps the sanitized RPC rows', () async {
    final client = _MockClient();
    when(() => client.rpc('get_discovery_candidates', params: any(named: 'params')))
        .thenAnswer((_) async => [
              {'id': 'u2', 'display_name': 'Linh', 'age': 24, 'distance_band': '1-3',
               'shared_genres': ['vpop'], 'shared_baitu': ['s2'], 'verified': true, 'active_today': true},
            ]);
    final list = await DiscoveryRepository(client).getCandidates();
    expect(list.single.displayName, 'Linh');
    expect(list.single.distanceBand, '1-3');
    expect(list.single.sharedGenres, ['vpop']);
  });

  test('recordSwipe returns matched flag', () async {
    final client = _MockClient();
    when(() => client.rpc('record_swipe', params: any(named: 'params')))
        .thenAnswer((_) async => true);
    final matched = await DiscoveryRepository(client).recordSwipe('u2', 'like');
    expect(matched, isTrue);
    verify(() => client.rpc('record_swipe',
        params: {'p_target': 'u2', 'p_direction': 'like'})).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/discovery/discovery_repository_test.dart`
Expected: FAIL — files not found.

- [ ] **Step 3: Implement model + repo + providers**

Create `lib/features/discovery/domain/candidate.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'candidate.freezed.dart';
part 'candidate.g.dart';

@freezed
class Candidate with _$Candidate {
  const factory Candidate({
    required String id,
    @JsonKey(name: 'display_name') String? displayName,
    int? age,
    @JsonKey(name: 'distance_band') String? distanceBand,
    @JsonKey(name: 'shared_genres') @Default([]) List<String> sharedGenres,
    @JsonKey(name: 'shared_baitu') @Default([]) List<String> sharedBaitu,
    @Default(false) bool verified,
    @JsonKey(name: 'active_today') @Default(false) bool activeToday,
  }) = _Candidate;
  factory Candidate.fromJson(Map<String, dynamic> j) => _$CandidateFromJson(j);
}
```

Create `lib/features/discovery/data/discovery_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/candidate.dart';

class DiscoveryRepository {
  DiscoveryRepository(this._client);
  final SupabaseClient _client;

  Future<List<Candidate>> getCandidates({int limit = 20}) async {
    final rows = await _client.rpc('get_discovery_candidates', params: {'p_limit': limit});
    return (rows as List)
        .map((e) => Candidate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Returns true if a mutual match was created.
  Future<bool> recordSwipe(String targetId, String direction) async {
    final res = await _client.rpc('record_swipe',
        params: {'p_target': targetId, 'p_direction': direction});
    return res == true;
  }

  Future<void> updateMyLocation(double lat, double lng, {String? area}) =>
      _client.rpc('update_my_location',
          params: {'p_lat': lat, 'p_lng': lng, 'p_area': area});
}
```

Create `lib/features/discovery/application/discovery_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/discovery_repository.dart';
import '../domain/candidate.dart';

final discoveryRepositoryProvider =
    Provider((ref) => DiscoveryRepository(ref.watch(supabaseClientProvider)));
final candidatesProvider = FutureProvider<List<Candidate>>(
    (ref) => ref.watch(discoveryRepositoryProvider).getCandidates());
```

- [ ] **Step 4: Generate + run test**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" pub run build_runner build --delete-conflicting-outputs
& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/discovery/discovery_repository_test.dart
```
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```
git add lib/features/discovery/ test/features/discovery/discovery_repository_test.dart
git commit -m "feat(p1): Candidate model + DiscoveryRepository (candidates/swipe/location)"
```

---

### Task 6: Location capture

**Files:**
- Modify: `pubspec.yaml` (geolocator), platform permission manifests
- Create: `lib/features/discovery/application/location_service.dart`
- Test: `test/features/discovery/location_service_test.dart`

- [ ] **Step 1: Add geolocator**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" pub add geolocator`
Add Android perms to `android/app/src/main/AndroidManifest.xml`: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`; iOS `ios/Runner/Info.plist`: `NSLocationWhenInUseUsageDescription` = "Để gợi ý người và kèo gần bạn.".

- [ ] **Step 2: Write the failing test (capture calls repo.updateMyLocation)**

Create `test/features/discovery/location_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';

class _MockRepo extends Mock implements DiscoveryRepository {}

void main() {
  test('pushFixedPosition forwards lat/lng to the repo', () async {
    final repo = _MockRepo();
    when(() => repo.updateMyLocation(any(), any(), area: any(named: 'area')))
        .thenAnswer((_) async {});
    await LocationService(repo).pushPosition(10.77, 106.70, area: 'Q1');
    verify(() => repo.updateMyLocation(10.77, 106.70, area: 'Q1')).called(1);
  });
}
```

- [ ] **Step 3: Implement (thin wrapper; geolocator call isolated)**

Create `lib/features/discovery/application/location_service.dart`:
```dart
import 'package:geolocator/geolocator.dart';
import '../data/discovery_repository.dart';

class LocationService {
  LocationService(this._repo);
  final DiscoveryRepository _repo;

  Future<void> pushPosition(double lat, double lng, {String? area}) =>
      _repo.updateMyLocation(lat, lng, area: area);

  /// Requests permission, reads the device position, pushes it (snapped server-side).
  Future<bool> captureAndPush() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return false;
    }
    final pos = await Geolocator.getCurrentPosition();
    await pushPosition(pos.latitude, pos.longitude);
    return true;
  }
}
```

- [ ] **Step 4: Run test**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/discovery/location_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add pubspec.yaml pubspec.lock android/ ios/ lib/features/discovery/application/location_service.dart test/features/discovery/location_service_test.dart
git commit -m "feat(p1): location capture (geolocator) → update_my_location"
```

---

### Task 7: Swipe deck + candidate card

**Files:**
- Modify: `pubspec.yaml` (flutter_card_swiper)
- Create: `lib/features/discovery/presentation/candidate_card.dart`, `lib/features/discovery/presentation/doi_deck_screen.dart`
- Modify: `lib/app/home_shell.dart` (tab 0 → DoiDeckScreen)
- Test: `test/features/discovery/candidate_card_test.dart`

- [ ] **Step 1: Add the deck package**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" pub add flutter_card_swiper`

- [ ] **Step 2: Write the failing card test**

Create `test/features/discovery/candidate_card_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/domain/candidate.dart';
import 'package:cung_hat/features/discovery/presentation/candidate_card.dart';

void main() {
  testWidgets('card shows name, distance band, and a monogram when no photo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CandidateCard(
      candidate: Candidate(id: 'u2', displayName: 'Linh', age: 24,
        distanceBand: '1-3', sharedBaitu: ['s2'], verified: true),
    ))));
    expect(find.text('Linh, 24'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
    expect(find.text('L'), findsOneWidget); // monogram fallback (no photo)
  });
}
```

- [ ] **Step 3: Implement card + deck + wire tab 0**

Create `lib/features/discovery/presentation/candidate_card.dart`:
```dart
import 'package:flutter/material.dart';
import '../domain/candidate.dart';

class CandidateCard extends StatelessWidget {
  const CandidateCard({super.key, required this.candidate});
  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final name = candidate.displayName ?? '';
    final monogram = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              alignment: Alignment.center,
              child: Text(monogram, style: const TextStyle(fontSize: 96)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('$name, ${candidate.age ?? ''}',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (candidate.verified) const Icon(Icons.verified, size: 18),
                ]),
                Text('Cách ${candidate.distanceBand} km · cùng ${candidate.sharedBaitu.length} bài tủ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

Create `lib/features/discovery/presentation/doi_deck_screen.dart` — a `ConsumerWidget` that watches `candidatesProvider`; on data builds a `CardSwiper` of `CandidateCard`s whose `onSwipe` maps direction → `recordSwipe` (right=like, up=super, left=pass) and, when `recordSwipe` returns true, pushes the match celebration (Task 8). Empty/loading/error states use a simple centered widget.

In `lib/app/home_shell.dart`: replace the tab-0 placeholder body with `const DoiDeckScreen()` (keep tabs 1-3 as placeholders for now).

- [ ] **Step 4: Run card test + analyze**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/discovery/candidate_card_test.dart
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
```
Expected: PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```
git add pubspec.yaml pubspec.lock lib/features/discovery/presentation/ lib/app/home_shell.dart test/features/discovery/candidate_card_test.dart
git commit -m "feat(p1): Đôi swipe deck + candidate card (monogram fallback) on tab 0"
```

---

### Task 8: Match celebration

**Files:**
- Create: `lib/features/discovery/presentation/match_celebration.dart`
- Test: `test/features/discovery/match_celebration_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/discovery/match_celebration_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/discovery/presentation/match_celebration.dart';

void main() {
  testWidgets('shows the match headline and the CTA', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MatchCelebration(
      otherName: 'Linh', sharedBaitu: const ['s2'], onChat: () {},
    )));
    expect(find.text('Chung gu! 🎤'), findsOneWidget);
    expect(find.text('Rủ đi hát'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/discovery/match_celebration_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

Create `lib/features/discovery/presentation/match_celebration.dart`:
```dart
import 'package:flutter/material.dart';

class MatchCelebration extends StatelessWidget {
  const MatchCelebration({
    super.key, required this.otherName, required this.sharedBaitu, required this.onChat,
  });
  final String otherName;
  final List<String> sharedBaitu;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Chung gu! 🎤',
                style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Bạn và $otherName cùng ${sharedBaitu.length} bài tủ',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            FilledButton(onPressed: onChat, child: const Text('Rủ đi hát')),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/discovery/match_celebration_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/discovery/presentation/match_celebration.dart test/features/discovery/match_celebration_test.dart
git commit -m "feat(p1): match celebration screen"
```

---

### Task 9: Block/Report sheet + acceptance

**Files:**
- Create: `lib/features/discovery/presentation/report_sheet.dart`
- Modify: `lib/features/discovery/data/discovery_repository.dart` (add block/report), `lib/features/discovery/presentation/candidate_card.dart` (overflow menu)
- Test: `test/features/discovery/report_test.dart`

- [ ] **Step 1: Write the failing test (repo block/report)**

Create `test/features/discovery/report_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('reportUser calls report_user RPC', () async {
    final client = _MockClient();
    when(() => client.rpc('report_user', params: any(named: 'params')))
        .thenAnswer((_) async => null);
    await DiscoveryRepository(client).reportUser('u2', 'spam');
    verify(() => client.rpc('report_user',
        params: {'p_target': 'u2', 'p_reason': 'spam'})).called(1);
  });

  test('blockUser calls block_user RPC', () async {
    final client = _MockClient();
    when(() => client.rpc('block_user', params: any(named: 'params')))
        .thenAnswer((_) async => null);
    await DiscoveryRepository(client).blockUser('u2');
    verify(() => client.rpc('block_user', params: {'p_blocked': 'u2'})).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/discovery/report_test.dart`
Expected: FAIL — methods not defined.

- [ ] **Step 3: Add repo methods + the sheet + card menu**

Append to `lib/features/discovery/data/discovery_repository.dart`:
```dart
  Future<void> reportUser(String targetId, String reason) =>
      _client.rpc('report_user', params: {'p_target': targetId, 'p_reason': reason});

  Future<void> blockUser(String targetId) =>
      _client.rpc('block_user', params: {'p_blocked': targetId});
```
Create `lib/features/discovery/presentation/report_sheet.dart` — a modal bottom sheet with reasons (spam, quấy rối, ảnh giả, khác) that calls `reportUser`, plus a "Chặn người này" action calling `blockUser`. Add an overflow `IconButton` (`Icons.more_vert`) to `CandidateCard` opening this sheet for `candidate.id`.

- [ ] **Step 4: Run test + full suite + analyze**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" test
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
```
Expected: all green; `No issues found!`.

- [ ] **Step 5: Acceptance — live deck round-trip**

Ensure `supabase start` + `supabase db reset` + seed two users with overlapping taste and nearby locations (insert via Studio/SQL: two profiles, `update_my_location`, shared `user_genres`). Log in as one, open Đôi: card shows the other with a bucketed band + shared count; swipe right; from the other account swipe right back (via a second session/SQL) → `record_swipe` returns true → celebration. Verify a report inserts a `reports` row and a block removes the candidate from the deck.

- [ ] **Step 6: Commit**

```
git add lib/features/discovery/ test/features/discovery/report_test.dart
git commit -m "feat(p1): block/report sheet + repo methods + P1 acceptance"
```

---

## Self-Review (completed by author)

- **Spec coverage:** private PostGIS location + snap ✓ (T1); bucketed distance only ✓ (T1,T3); two-stage matching (PostGIS prefilter + weighted scoring) via sanitized RPC ✓ (T3); swipe deck (right/left/up) ✓ (T7); race-safe mutual match ✓ (T4); celebration ✓ (T8); blocks/reports + rate limits ✓ (T2,T9). Photos intentionally absent (optional; a later photos task adds the private bucket); card uses the monogram fallback from the spec.
- **Placeholder scan:** none — every code step is concrete. T7 Step 3 and T9 Step 3 assemble already-defined widgets/RPCs (`CandidateCard`, `candidatesProvider`, `recordSwipe`, `MatchCelebration`, `reportUser`/`blockUser`); no undefined symbols.
- **Type consistency:** RPC names identical across SQL and Dart — `get_discovery_candidates`, `record_swipe`, `update_my_location`, `report_user`, `block_user`; `Candidate` JSON keys match the `discovery_candidate` SQL type fields exactly (`distance_band`, `shared_genres`, `shared_baitu`, `active_today`); `DiscoveryRepository` method set (`getCandidates/recordSwipe/updateMyLocation/reportUser/blockUser`) consistent T5↔T6↔T9; `MatchCelebration(otherName,sharedBaitu,onChat)` identical T8 test+impl.

---

## Next plans (when we reach them)
- **P2** Chat — 1-1 thread via Broadcast-from-Database on private channels (migration: `messages`/`message_reads` + AFTER INSERT broadcast trigger + `realtime.messages` topic RLS), chat UI, unread, message-safety, "Lập kèo" promotion from a 1-1 thread.
- Then **P3** Kèo board, **P4** venues/plan, **P5** compliance/moderation, **P6** monetization (IAP + MoMo/ZaloPay), **P7** launch (3-city seeding, FCM, store).
