# Cung Hat Auto Keo Match Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the "Ghep nhom cho toi" board action suggest a safe matching keo, or ask the user to create a proposed new keo when no existing keo fits.

**Architecture:** Supabase RPCs own scoring and creation authority. Flutter adds a small `KeoMatchSuggestion` model, repository methods, a focused result sheet, and board wiring that asks the user before creating any new keo. Existing join, Pro gating, location fallback, and plan/venue flows remain intact.

**Tech Stack:** Supabase Postgres SECURITY DEFINER RPCs, PostGIS, pgTAP, Flutter, Riverpod 3, freezed/json_serializable, mocktail.

---

## File Structure

- Create `supabase/migrations/20260629120000_auto_keo_matching.sql`: defines `keo_match_suggestion`, `suggest_keo_match`, and `create_auto_matched_keo`.
- Create `supabase/tests/auto_keo_match_test.sql`: pgTAP coverage for sanitized type, safe matching, proposal fallback, and Pro/location gates.
- Create `lib/features/keo/domain/keo_match_suggestion.dart`: freezed model for sanitized RPC rows.
- Modify `lib/features/keo/data/keo_repository.dart`: add `suggestMatch` and `createAutoMatchedKeo`.
- Modify `lib/features/keo/application/keo_providers.dart`: expose `keoMatchSuggestionsProvider` for tests and future consumers.
- Modify `lib/features/keo/data/keo_errors.dart`: map `location_required`, `age_not_verified`, `blocked`, and `no_matchable_keo`.
- Create `lib/features/keo/presentation/keo_match_sheet.dart`: result sheet that renders existing-keo and new-proposal suggestions.
- Modify `lib/features/keo/presentation/keo_board_screen.dart`: wire the banner action to location capture, suggestion RPC, sheet actions, join/create success paths.
- Test `test/features/keo/auto_keo_match_repository_test.dart`: model/repo mapping and RPC params.
- Test `test/features/keo/keo_match_sheet_test.dart`: existing/proposal UI and callbacks.
- Modify `test/features/keo/keo_board_gate_test.dart`: add board auto-match integration tests without disturbing current Pro FAB gate tests.

---

### Task 1: Database RPCs and pgTAP Coverage

**Files:**
- Create: `supabase/migrations/20260629120000_auto_keo_matching.sql`
- Create: `supabase/tests/auto_keo_match_test.sql`

- [ ] **Step 1: Write the failing pgTAP test**

Create `supabase/tests/auto_keo_match_test.sql`:

```sql
begin;
select plan(9);

select ok(
  exists(select 1 from pg_type where typname = 'keo_match_suggestion'),
  'keo_match_suggestion type exists'
);

select is(
  (select count(*)::int
     from pg_attribute a
     join pg_class c on c.oid = a.attrelid
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'keo_match_suggestion'
      and a.attnum > 0
      and not a.attisdropped
      and a.attname in ('location','area_geo','lat','lng','score','raw_score')),
  0,
  'suggestion type exposes no coords or raw score'
);

select ok(
  exists(select 1 from pg_proc where proname = 'suggest_keo_match'),
  'suggest_keo_match RPC exists'
);

select ok(
  exists(select 1 from pg_proc where proname = 'create_auto_matched_keo'),
  'create_auto_matched_keo RPC exists'
);

set local role postgres;

insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000aa01'),
  ('00000000-0000-0000-0000-00000000aa02'),
  ('00000000-0000-0000-0000-00000000aa03'),
  ('00000000-0000-0000-0000-00000000aa04')
on conflict (id) do nothing;

insert into public.profiles (id, display_name, dob, age_verified, verified_badge, report_risk) values
  ('00000000-0000-0000-0000-00000000aa01', 'Auto Caller', '1990-01-01', true, true, 0),
  ('00000000-0000-0000-0000-00000000aa02', 'Auto Host', '1990-01-01', true, true, 0),
  ('00000000-0000-0000-0000-00000000aa03', 'No Location Pro', '1990-01-01', true, true, 0),
  ('00000000-0000-0000-0000-00000000aa04', 'Free Caller', '1990-01-01', true, true, 0)
on conflict (id) do update
set age_verified = excluded.age_verified,
    verified_badge = excluded.verified_badge,
    report_risk = excluded.report_risk;

insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-00000000aa01', 'pro', 'promo'),
  ('00000000-0000-0000-0000-00000000aa02', 'pro', 'promo'),
  ('00000000-0000-0000-0000-00000000aa03', 'pro', 'promo')
on conflict do nothing;

insert into public.user_locations (user_id, location, area_label) values
  ('00000000-0000-0000-0000-00000000aa01', public.ST_SetSRID(public.ST_MakePoint(106.700, 10.776), 4326)::public.geography, 'Q1'),
  ('00000000-0000-0000-0000-00000000aa02', public.ST_SetSRID(public.ST_MakePoint(106.702, 10.778), 4326)::public.geography, 'Q1'),
  ('00000000-0000-0000-0000-00000000aa04', public.ST_SetSRID(public.ST_MakePoint(106.701, 10.777), 4326)::public.geography, 'Q1')
on conflict (user_id) do update
set location = excluded.location,
    area_label = excluded.area_label,
    updated_at = now();

insert into public.user_genres (user_id, genre_id) values
  ('00000000-0000-0000-0000-00000000aa01', 'vpop'),
  ('00000000-0000-0000-0000-00000000aa02', 'vpop')
on conflict do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa02"}';
set local role authenticated;

create temp table _auto_keo (id uuid);
insert into _auto_keo
select public.create_keo(
  'V-Pop toi nay',
  10.778,
  106.702,
  'Q1',
  now() + interval '1 day',
  now() + interval '1 day 3 hours',
  4,
  null,
  null,
  array['vpop'],
  'open'
);

set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa01"}';
set local role authenticated;

select is(
  (select suggestion_type from public.suggest_keo_match(1) limit 1),
  'existing_keo',
  'nearby shared-genre open keo is suggested first'
);

select ok(
  (select 'shared_genres' = any(reason_labels)
     from public.suggest_keo_match(1)
    limit 1),
  'music-fit reason is returned'
);

set local role postgres;
insert into public.blocks (blocker_id, blocked_id) values
  ('00000000-0000-0000-0000-00000000aa01', '00000000-0000-0000-0000-00000000aa02')
on conflict do nothing;

set local role authenticated;

select is(
  (select suggestion_type from public.suggest_keo_match(1) limit 1),
  'new_keo_proposal',
  'blocked host is excluded and proposal fallback is returned'
);

set local role postgres;
select is(
  (select count(*)::int from public.keo where title = 'Keo goi y toi nay'),
  0,
  'proposal fallback does not insert a keo row'
);

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa04"}';
set local role authenticated;

select throws_ok(
  $$ select public.create_auto_matched_keo(
    'Keo goi y toi nay',
    now() + interval '1 day',
    now() + interval '1 day 3 hours',
    4,
    array['vpop'],
    'open'
  ) $$,
  '23514',
  null,
  'free user cannot create auto-matched keo'
);

set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa03"}';
set local role authenticated;

select throws_ok(
  $$ select public.create_auto_matched_keo(
    'Keo goi y toi nay',
    now() + interval '1 day',
    now() + interval '1 day 3 hours',
    4,
    array['vpop'],
    'open'
  ) $$,
  '23514',
  null,
  'pro user without location cannot create auto-matched keo'
);

set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa01"}';
set local role authenticated;

select lives_ok(
  $$ select public.create_auto_matched_keo(
    'Keo goi y toi nay',
    now() + interval '2 days',
    now() + interval '2 days 3 hours',
    4,
    array['vpop'],
    'open'
  ) $$,
  'pro user with location can create auto-matched keo'
);

select * from finish();
rollback;
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```powershell
supabase test db
```

Expected: FAIL because `keo_match_suggestion`, `suggest_keo_match`, and `create_auto_matched_keo` do not exist.

- [ ] **Step 3: Implement the migration**

Create `supabase/migrations/20260629120000_auto_keo_matching.sql`:

```sql
create type public.keo_match_suggestion as (
  suggestion_type text,
  keo_id uuid,
  title text,
  area_label text,
  distance_band text,
  time_window_start timestamptz,
  time_window_end timestamptz,
  size_target int,
  slots_filled int,
  genres text[],
  host_name text,
  join_mode text,
  reason_labels text[],
  proposed_start timestamptz,
  proposed_end timestamptz
);

create or replace function public.suggest_keo_match(p_limit int default 3)
returns setof public.keo_match_suggestion
language plpgsql
security definer
set search_path=''
as $$
declare
  matched_count int := 0;
  caller_verified boolean;
  caller_loc public.geography;
  caller_area text;
  caller_genres text[];
  local_now timestamp;
  proposal_local timestamp;
  proposal_start timestamptz;
  proposal_end timestamptz;
begin
  select p.age_verified
    into caller_verified
  from public.profiles p
  where p.id = auth.uid()
    and p.soft_deleted_at is null;

  if coalesce(caller_verified, false) = false then
    raise exception 'age_not_verified' using errcode='check_violation';
  end if;

  select ul.location, ul.area_label
    into caller_loc, caller_area
  from public.user_locations ul
  where ul.user_id = auth.uid();

  if caller_loc is null then
    raise exception 'location_required' using errcode='check_violation';
  end if;

  select coalesce(array_agg(ug.genre_id), '{}'::text[])
    into caller_genres
  from public.user_genres ug
  where ug.user_id = auth.uid();

  return query
  with ranked as (
    select
      'existing_keo'::text as suggestion_type,
      k.id as keo_id,
      k.title,
      k.area_label,
      app_private.dist_band(public.ST_Distance(k.area_geo, caller_loc)) as distance_band,
      k.time_window_start,
      k.time_window_end,
      k.group_size_target as size_target,
      (
        select count(*)::int
        from public.keo_members km
        where km.keo_id = k.id
          and km.join_status = 'approved'
      ) as slots_filled,
      k.genres,
      hp.display_name as host_name,
      k.join_mode,
      array_remove(array[
        case when (
          select count(*)::int
          from (
            select unnest(k.genres)
            intersect
            select unnest(caller_genres)
          ) shared_genres
        ) > 0 then 'shared_genres' end,
        case when public.ST_Distance(k.area_geo, caller_loc) < 5000 then 'near_you' end,
        case when extract(hour from k.time_window_start at time zone 'Asia/Bangkok') between 18 and 22 then 'evening_slot' end,
        case when k.join_mode = 'open' then 'open_join' end,
        case when (
          select count(*)::int
          from public.keo_members km
          where km.keo_id = k.id
            and km.join_status = 'approved'
        ) < k.group_size_target then 'available_slots' end,
        case when hp.last_active > now() - interval '1 day' then 'active_host' end
      ], null) as reason_labels,
      null::timestamptz as proposed_start,
      null::timestamptz as proposed_end,
      (
        3.0 * (
          select count(*)::numeric
          from (
            select unnest(k.genres)
            intersect
            select unnest(caller_genres)
          ) shared_genres
        )
        + case when cardinality(k.genres) = 0 then 0.5 else 0 end
        + case
            when public.ST_Distance(k.area_geo, caller_loc) < 1000 then 3.0
            when public.ST_Distance(k.area_geo, caller_loc) < 3000 then 2.0
            when public.ST_Distance(k.area_geo, caller_loc) < 5000 then 1.0
            else 0.25
          end
        + case when extract(hour from k.time_window_start at time zone 'Asia/Bangkok') between 18 and 22 then 1.0 else 0 end
        + case when hp.last_active > now() - interval '1 day' then 0.5 else 0 end
        - coalesce(hp.report_risk, 0) * 2.0
      ) as score
    from public.keo k
    join public.profiles hp on hp.id = k.host_id
    where k.status = 'open'
      and k.soft_deleted_at is null
      and k.time_window_end > now()
      and k.time_window_start < now() + interval '7 days'
      and k.host_id <> auth.uid()
      and hp.soft_deleted_at is null
      and hp.age_verified = true
      and public.ST_DWithin(k.area_geo, caller_loc, 50000)
      and (
        select count(*)::int
        from public.keo_members km
        where km.keo_id = k.id
          and km.join_status = 'approved'
      ) < k.group_size_target
      and not exists (
        select 1
        from public.keo_members mine
        where mine.keo_id = k.id
          and mine.user_id = auth.uid()
          and mine.join_status in ('requested','approved')
      )
      and not exists (
        select 1
        from public.blocks b
        where (b.blocker_id = auth.uid() and b.blocked_id = k.host_id)
           or (b.blocker_id = k.host_id and b.blocked_id = auth.uid())
      )
  )
  select
    r.suggestion_type,
    r.keo_id,
    r.title,
    r.area_label,
    r.distance_band,
    r.time_window_start,
    r.time_window_end,
    r.size_target,
    r.slots_filled,
    r.genres,
    r.host_name,
    r.join_mode,
    r.reason_labels,
    r.proposed_start,
    r.proposed_end
  from ranked r
  where r.score >= 1.0
  order by r.score desc, r.time_window_start asc
  limit greatest(p_limit, 1);

  get diagnostics matched_count = row_count;
  if matched_count > 0 then
    return;
  end if;

  local_now := timezone('Asia/Bangkok', now());
  proposal_local := date_trunc('day', local_now) + interval '19 hours';
  if proposal_local <= local_now then
    proposal_local := proposal_local + interval '1 day';
  end if;
  proposal_start := proposal_local at time zone 'Asia/Bangkok';
  proposal_end := proposal_start + interval '3 hours';

  return query
  select
    'new_keo_proposal'::text,
    null::uuid,
    'Keo goi y toi nay'::text,
    caller_area,
    null::text,
    null::timestamptz,
    null::timestamptz,
    4,
    1,
    coalesce(caller_genres, '{}'::text[]),
    null::text,
    'open'::text,
    array_remove(array[
      case when cardinality(coalesce(caller_genres, '{}'::text[])) > 0 then 'shared_genres' end,
      'evening_slot',
      'open_join'
    ], null),
    proposal_start,
    proposal_end;
end;
$$;

create or replace function public.create_auto_matched_keo(
  p_title text,
  p_start timestamptz,
  p_end timestamptz,
  p_size int,
  p_genres text[],
  p_join_mode text default 'open'
)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
  kid uuid;
  caller_verified boolean;
  caller_loc public.geography;
  caller_area text;
  clean_title text;
begin
  if not app_private.is_pro() then
    raise exception 'pro_required' using errcode='check_violation';
  end if;

  select p.age_verified
    into caller_verified
  from public.profiles p
  where p.id = auth.uid()
    and p.soft_deleted_at is null;

  if coalesce(caller_verified, false) = false then
    raise exception 'age_not_verified' using errcode='check_violation';
  end if;

  select ul.location, ul.area_label
    into caller_loc, caller_area
  from public.user_locations ul
  where ul.user_id = auth.uid();

  if caller_loc is null then
    raise exception 'location_required' using errcode='check_violation';
  end if;

  if p_end <= p_start then
    raise exception 'invalid_time_window' using errcode='check_violation';
  end if;

  if p_size < 2 or p_size > 5 then
    raise exception 'invalid_group_size' using errcode='check_violation';
  end if;

  clean_title := nullif(trim(p_title), '');
  if clean_title is null then
    clean_title := 'Keo goi y toi nay';
  end if;

  perform app_private.enforce_rate_limit('create_keo', 10, interval '1 day');

  insert into public.keo(
    host_id,
    title,
    area_label,
    area_geo,
    time_window_start,
    time_window_end,
    group_size_target,
    intent_tag,
    vibe,
    genres,
    join_mode
  )
  values (
    auth.uid(),
    left(clean_title, 100),
    caller_area,
    caller_loc,
    p_start,
    p_end,
    p_size,
    null,
    null,
    coalesce(p_genres, '{}'::text[]),
    case when p_join_mode in ('open','approval') then p_join_mode else 'open' end
  )
  returning id into kid;

  insert into public.keo_members(keo_id, user_id, role, join_status, confirmed)
  values (kid, auth.uid(), 'host', 'approved', true);

  return kid;
end;
$$;

revoke execute on function public.suggest_keo_match(int) from public, anon;
revoke execute on function public.create_auto_matched_keo(text,timestamptz,timestamptz,int,text[],text) from public, anon;
grant execute on function public.suggest_keo_match(int) to authenticated;
grant execute on function public.create_auto_matched_keo(text,timestamptz,timestamptz,int,text[],text) to authenticated;
```

- [ ] **Step 4: Run the DB test**

Run:

```powershell
supabase test db
```

Expected: PASS with 9 assertions.

- [ ] **Step 5: Commit**

```powershell
git add supabase/migrations/20260629120000_auto_keo_matching.sql supabase/tests/auto_keo_match_test.sql
git commit -m "feat(db): add auto keo matching RPCs"
```

---

### Task 2: Dart Model, Repository, Providers, and Error Mapping

**Files:**
- Create: `lib/features/keo/domain/keo_match_suggestion.dart`
- Modify: `lib/features/keo/data/keo_repository.dart`
- Modify: `lib/features/keo/application/keo_providers.dart`
- Modify: `lib/features/keo/data/keo_errors.dart`
- Test: `test/features/keo/auto_keo_match_repository_test.dart`

- [ ] **Step 1: Write the failing repository test**

Create `test/features/keo/auto_keo_match_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cung_hat/features/keo/data/keo_errors.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';

import '../../support/supabase_mocks.dart';

void main() {
  test('suggestMatch maps sanitized suggestion rows', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('suggest_keo_match', params: any(named: 'params')))
        .thenAnswer((_) => rpcOk([
              {
                'suggestion_type': 'existing_keo',
                'keo_id': '00000000-0000-0000-0000-000000000001',
                'title': 'V-Pop toi nay',
                'area_label': 'Q1',
                'distance_band': '1-3',
                'time_window_start': '2026-06-30T12:00:00Z',
                'time_window_end': '2026-06-30T15:00:00Z',
                'size_target': 4,
                'slots_filled': 2,
                'genres': ['vpop'],
                'host_name': 'Mai',
                'join_mode': 'open',
                'reason_labels': ['shared_genres', 'near_you'],
                'proposed_start': null,
                'proposed_end': null,
              },
            ]));

    final suggestions = await KeoRepository(client).suggestMatch(limit: 2);

    expect(suggestions.single.suggestionType, 'existing_keo');
    expect(suggestions.single.keoId, '00000000-0000-0000-0000-000000000001');
    expect(suggestions.single.reasonLabels, ['shared_genres', 'near_you']);
    verify(() => client.rpc('suggest_keo_match', params: {'p_limit': 2}))
        .called(1);
  });

  test('createAutoMatchedKeo sends proposal fields to RPC', () async {
    final client = MockSupabaseClient();
    when(() => client.rpc('create_auto_matched_keo',
            params: any(named: 'params')))
        .thenAnswer((_) => rpcOk('k-new'));

    final id = await KeoRepository(client).createAutoMatchedKeo(
      title: 'Keo goi y toi nay',
      start: DateTime.utc(2026, 6, 30, 12),
      end: DateTime.utc(2026, 6, 30, 15),
      size: 4,
      genres: const ['vpop'],
      joinMode: 'open',
    );

    expect(id, 'k-new');
    verify(
      () => client.rpc(
        'create_auto_matched_keo',
        params: {
          'p_title': 'Keo goi y toi nay',
          'p_start': '2026-06-30T12:00:00.000Z',
          'p_end': '2026-06-30T15:00:00.000Z',
          'p_size': 4,
          'p_genres': ['vpop'],
          'p_join_mode': 'open',
        },
      ),
    ).called(1);
  });

  test('keoErrorMessage maps auto-match errors', () {
    expect(
      keoErrorMessage('PostgrestException(message: location_required)'),
      'Can bat vi tri de ghep keo. Hay bat Location roi thu lai.',
    );
    expect(
      keoErrorMessage('PostgrestException(message: age_not_verified)'),
      'Can xac minh tuoi truoc khi ghep keo.',
    );
  });
}
```

- [ ] **Step 2: Run the repository test to verify it fails**

Run:

```powershell
flutter test test/features/keo/auto_keo_match_repository_test.dart
```

Expected: FAIL because `KeoMatchSuggestion`, `suggestMatch`, and `createAutoMatchedKeo` are not defined.

- [ ] **Step 3: Add the domain model**

Create `lib/features/keo/domain/keo_match_suggestion.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'keo_match_suggestion.freezed.dart';
part 'keo_match_suggestion.g.dart';

@freezed
abstract class KeoMatchSuggestion with _$KeoMatchSuggestion {
  const factory KeoMatchSuggestion({
    @JsonKey(name: 'suggestion_type') required String suggestionType,
    @JsonKey(name: 'keo_id') String? keoId,
    required String title,
    @JsonKey(name: 'area_label') String? areaLabel,
    @JsonKey(name: 'distance_band') String? distanceBand,
    @JsonKey(name: 'time_window_start') String? timeWindowStart,
    @JsonKey(name: 'time_window_end') String? timeWindowEnd,
    @JsonKey(name: 'size_target') @Default(4) int sizeTarget,
    @JsonKey(name: 'slots_filled') @Default(0) int slotsFilled,
    @Default([]) List<String> genres,
    @JsonKey(name: 'host_name') String? hostName,
    @JsonKey(name: 'join_mode') @Default('open') String joinMode,
    @JsonKey(name: 'reason_labels') @Default([]) List<String> reasonLabels,
    @JsonKey(name: 'proposed_start') String? proposedStart,
    @JsonKey(name: 'proposed_end') String? proposedEnd,
  }) = _KeoMatchSuggestion;

  factory KeoMatchSuggestion.fromJson(Map<String, dynamic> json) =>
      _$KeoMatchSuggestionFromJson(json);
}
```

- [ ] **Step 4: Add repository methods**

Modify `lib/features/keo/data/keo_repository.dart`:

```dart
import '../domain/keo_match_suggestion.dart';
```

Add methods inside `KeoRepository`:

```dart
  Future<List<KeoMatchSuggestion>> suggestMatch({int limit = 3}) async {
    final rows =
        await _client.rpc('suggest_keo_match', params: {'p_limit': limit});
    return (rows as List)
        .map((e) =>
            KeoMatchSuggestion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<String> createAutoMatchedKeo({
    required String title,
    required DateTime start,
    required DateTime end,
    required int size,
    List<String> genres = const [],
    String joinMode = 'open',
  }) async {
    final id = await _client.rpc('create_auto_matched_keo', params: {
      'p_title': title,
      'p_start': start.toUtc().toIso8601String(),
      'p_end': end.toUtc().toIso8601String(),
      'p_size': size,
      'p_genres': genres,
      'p_join_mode': joinMode,
    });
    return id as String;
  }
```

- [ ] **Step 5: Add provider and error messages**

Modify `lib/features/keo/application/keo_providers.dart`:

```dart
import '../domain/keo_match_suggestion.dart';
```

Add:

```dart
final keoMatchSuggestionsProvider =
    FutureProvider.autoDispose<List<KeoMatchSuggestion>>(
  (ref) => ref.watch(keoRepositoryProvider).suggestMatch(),
);
```

Modify `lib/features/keo/data/keo_errors.dart` by extending `_messages`:

```dart
  'blocked': 'Khong the vao keo nay vi cai dat an toan.',
  'location_required': 'Can bat vi tri de ghep keo. Hay bat Location roi thu lai.',
  'age_not_verified': 'Can xac minh tuoi truoc khi ghep keo.',
  'no_matchable_keo': 'Chua tim duoc keo phu hop, thu lai sau.',
```

- [ ] **Step 6: Generate code and run the repository test**

Run:

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/features/keo/auto_keo_match_repository_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/features/keo/domain/keo_match_suggestion.dart lib/features/keo/domain/keo_match_suggestion.freezed.dart lib/features/keo/domain/keo_match_suggestion.g.dart lib/features/keo/data/keo_repository.dart lib/features/keo/application/keo_providers.dart lib/features/keo/data/keo_errors.dart test/features/keo/auto_keo_match_repository_test.dart
git commit -m "feat(keo): add auto-match model and repository"
```

---

### Task 3: Auto-Match Result Sheet

**Files:**
- Create: `lib/features/keo/presentation/keo_match_sheet.dart`
- Test: `test/features/keo/keo_match_sheet_test.dart`

- [ ] **Step 1: Write the failing sheet tests**

Create `test/features/keo/keo_match_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cung_hat/features/keo/domain/keo_match_suggestion.dart';
import 'package:cung_hat/features/keo/presentation/keo_match_sheet.dart';

void main() {
  testWidgets('existing keo sheet calls onJoin', (tester) async {
    var joined = false;
    const suggestion = KeoMatchSuggestion(
      suggestionType: 'existing_keo',
      keoId: 'k1',
      title: 'V-Pop toi nay',
      distanceBand: '1-3',
      sizeTarget: 4,
      slotsFilled: 2,
      genres: ['vpop'],
      hostName: 'Mai',
      joinMode: 'open',
      reasonLabels: ['shared_genres', 'near_you'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeoMatchSheet(
            suggestions: const [suggestion],
            onJoin: (_) async => joined = true,
            onCreate: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Keo hop voi ban'), findsOneWidget);
    expect(find.text('V-Pop toi nay'), findsOneWidget);

    await tester.tap(find.byKey(const Key('keo_match_join_btn')));
    await tester.pumpAndSettle();

    expect(joined, isTrue);
  });

  testWidgets('proposal sheet calls onCreate only after confirmation',
      (tester) async {
    var created = false;
    const suggestion = KeoMatchSuggestion(
      suggestionType: 'new_keo_proposal',
      title: 'Keo goi y toi nay',
      sizeTarget: 4,
      slotsFilled: 1,
      genres: ['vpop'],
      joinMode: 'open',
      reasonLabels: ['evening_slot', 'open_join'],
      proposedStart: '2026-06-30T12:00:00Z',
      proposedEnd: '2026-06-30T15:00:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeoMatchSheet(
            suggestions: const [suggestion],
            onJoin: (_) async {},
            onCreate: (_) async => created = true,
          ),
        ),
      ),
    );

    expect(created, isFalse);
    expect(find.text('Tao keo moi tu goi y nay?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('keo_match_create_btn')));
    await tester.pumpAndSettle();

    expect(created, isTrue);
  });
}
```

- [ ] **Step 2: Run the sheet tests to verify they fail**

Run:

```powershell
flutter test test/features/keo/keo_match_sheet_test.dart
```

Expected: FAIL because `KeoMatchSheet` is not defined.

- [ ] **Step 3: Implement the sheet**

Create `lib/features/keo/presentation/keo_match_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../domain/keo_match_suggestion.dart';

class KeoMatchSheet extends StatefulWidget {
  const KeoMatchSheet({
    super.key,
    required this.suggestions,
    required this.onJoin,
    required this.onCreate,
  });

  final List<KeoMatchSuggestion> suggestions;
  final Future<void> Function(KeoMatchSuggestion suggestion) onJoin;
  final Future<void> Function(KeoMatchSuggestion suggestion) onCreate;

  @override
  State<KeoMatchSheet> createState() => _KeoMatchSheetState();
}

class _KeoMatchSheetState extends State<KeoMatchSheet> {
  bool _submitting = false;

  KeoMatchSuggestion? get _suggestion =>
      widget.suggestions.isEmpty ? null : widget.suggestions.first;

  bool get _isProposal =>
      _suggestion?.suggestionType == 'new_keo_proposal';

  Future<void> _submit() async {
    final suggestion = _suggestion;
    if (suggestion == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      if (_isProposal) {
        await widget.onCreate(suggestion);
      } else {
        await widget.onJoin(suggestion);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = _suggestion;
    if (suggestion == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Chua tim duoc keo phu hop. Thu lai sau.'),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isProposal
                        ? 'Tao keo moi tu goi y nay?'
                        : 'Keo hop voi ban',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Dong',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              suggestion.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetaLine(suggestion: suggestion),
            if (suggestion.genres.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final genre in suggestion.genres)
                    Chip(label: Text(genre)),
                ],
              ),
            ],
            if (suggestion.reasonLabels.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final reason in suggestion.reasonLabels)
                    Chip(label: Text(_reasonLabel(reason))),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: Key(_isProposal
                  ? 'keo_match_create_btn'
                  : 'keo_match_join_btn'),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_primaryLabel(suggestion)),
            ),
            if (_isProposal)
              TextButton(
                key: const Key('keo_match_later_btn'),
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).maybePop(),
                child: const Text('De sau'),
              ),
          ],
        ),
      ),
    );
  }

  String _primaryLabel(KeoMatchSuggestion suggestion) {
    if (_isProposal) return 'Tao keo nay';
    return suggestion.joinMode == 'open' ? 'Vao keo nay' : 'Xin vao keo';
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'shared_genres':
        return 'Hop gu nhac';
      case 'near_you':
        return 'Gan ban';
      case 'evening_slot':
        return 'Gio dep';
      case 'open_join':
        return 'Vao nhanh';
      case 'available_slots':
        return 'Con cho';
      case 'active_host':
        return 'Chu keo dang online';
      default:
        return reason;
    }
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.suggestion});

  final KeoMatchSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final bits = <String>[
      if (suggestion.distanceBand != null)
        'cach ${suggestion.distanceBand} km',
      '${suggestion.slotsFilled}/${suggestion.sizeTarget} nguoi',
      if (suggestion.hostName != null) 'chu keo ${suggestion.hostName}',
      if (suggestion.proposedStart != null) suggestion.proposedStart!,
    ];
    return Text(
      bits.join(' · '),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
```

- [ ] **Step 4: Run the sheet tests**

Run:

```powershell
flutter test test/features/keo/keo_match_sheet_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/keo/presentation/keo_match_sheet.dart test/features/keo/keo_match_sheet_test.dart
git commit -m "feat(keo): add auto-match result sheet"
```

---

### Task 4: Board Integration

**Files:**
- Modify: `lib/features/keo/presentation/keo_board_screen.dart`
- Modify: `test/features/keo/keo_board_gate_test.dart`

- [ ] **Step 1: Extend board tests**

Modify `test/features/keo/keo_board_gate_test.dart` by replacing `_FakeKeoRepository` with this version:

```dart
class _FakeKeoRepository implements KeoRepository {
  _FakeKeoRepository({
    this.suggestions = const [],
    this.openKeos = const [],
  });

  final List<KeoMatchSuggestion> suggestions;
  final List<Keo> openKeos;
  int joinCalls = 0;
  int createCalls = 0;

  @override
  Future<List<Keo>> listOpenKeos({int limit = 30}) async => openKeos;

  @override
  Future<List<KeoMatchSuggestion>> suggestMatch({int limit = 3}) async =>
      suggestions;

  @override
  Future<void> requestJoin(String keoId) async {
    joinCalls += 1;
  }

  @override
  Future<String> createAutoMatchedKeo({
    required String title,
    required DateTime start,
    required DateTime end,
    required int size,
    List<String> genres = const [],
    String joinMode = 'open',
  }) async {
    createCalls += 1;
    return 'created-keo';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationService implements LocationService {
  @override
  Future<bool> captureAndPush() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

Add imports:

```dart
import 'package:cung_hat/features/discovery/application/discovery_providers.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';
import 'package:cung_hat/features/keo/domain/keo_match_suggestion.dart';
```

Update `_wrap` to accept a repo:

```dart
ProviderScope _wrap(
  Widget child, {
  required Set<String> entitlements,
  KeoRepository? repo,
}) {
  return ProviderScope(
    overrides: [
      keoRepositoryProvider.overrideWithValue(
        repo ?? _FakeKeoRepository(),
      ),
      locationServiceProvider.overrideWithValue(_FakeLocationService()),
      entitlementsProvider.overrideWith((ref) async => entitlements),
    ],
    child: child,
  );
}
```

Add test:

```dart
testWidgets('Ghép nhóm cho tôi opens existing suggestion and joins',
    (tester) async {
  final repo = _FakeKeoRepository(
    openKeos: const [
      Keo(id: 'board-1', title: 'Board keo', sizeTarget: 4),
    ],
    suggestions: const [
      KeoMatchSuggestion(
        suggestionType: 'existing_keo',
        keoId: 'match-1',
        title: 'V-Pop toi nay',
        distanceBand: '<1',
        sizeTarget: 4,
        slotsFilled: 2,
        genres: ['vpop'],
        joinMode: 'open',
        reasonLabels: ['shared_genres'],
      ),
    ],
  );

  await tester.pumpWidget(_wrap(
    MaterialApp(theme: AppTheme.light(), home: const KeoBoardScreen()),
    entitlements: const <String>{'pro'},
    repo: repo,
  ));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Ghép nhóm cho tôi'));
  await tester.pumpAndSettle();

  expect(find.text('Keo hop voi ban'), findsOneWidget);
  await tester.tap(find.byKey(const Key('keo_match_join_btn')));
  await tester.pumpAndSettle();

  expect(repo.joinCalls, 1);
});

testWidgets('proposal suggestion creates only after user confirms',
    (tester) async {
  final repo = _FakeKeoRepository(
    openKeos: const [
      Keo(id: 'board-1', title: 'Board keo', sizeTarget: 4),
    ],
    suggestions: const [
      KeoMatchSuggestion(
        suggestionType: 'new_keo_proposal',
        title: 'Keo goi y toi nay',
        sizeTarget: 4,
        slotsFilled: 1,
        genres: ['vpop'],
        joinMode: 'open',
        reasonLabels: ['evening_slot'],
        proposedStart: '2026-06-30T12:00:00Z',
        proposedEnd: '2026-06-30T15:00:00Z',
      ),
    ],
  );

  await tester.pumpWidget(_wrap(
    MaterialApp(theme: AppTheme.light(), home: const KeoBoardScreen()),
    entitlements: const <String>{'pro'},
    repo: repo,
  ));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Ghép nhóm cho tôi'));
  await tester.pumpAndSettle();

  expect(repo.createCalls, 0);
  await tester.tap(find.byKey(const Key('keo_match_create_btn')));
  await tester.pumpAndSettle();

  expect(repo.createCalls, 1);
});
```

- [ ] **Step 2: Run board tests to verify they fail**

Run:

```powershell
flutter test test/features/keo/keo_board_gate_test.dart
```

Expected: FAIL because the board banner still only invalidates `openKeosProvider` and does not show `KeoMatchSheet`.

- [ ] **Step 3: Wire the board action**

Modify `lib/features/keo/presentation/keo_board_screen.dart`:

Add imports:

```dart
import '../../discovery/application/discovery_providers.dart';
import '../data/keo_errors.dart';
import '../domain/keo_match_suggestion.dart';
import 'keo_match_sheet.dart';
```

Change `_matchBanner` to call `_runAutoMatch`:

```dart
  Widget _matchBanner(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    child: Material(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        onTap: () => _runAutoMatch(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghép nhóm cho tôi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Tự động gợi ý kèo hợp gu, gần bạn',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
```

Add these methods to `KeoBoardScreen`:

```dart
  Future<void> _runAutoMatch(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ref.read(locationServiceProvider).captureAndPush();
      final suggestions = await ref.read(keoRepositoryProvider).suggestMatch();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => KeoMatchSheet(
          suggestions: suggestions,
          onJoin: (suggestion) => _joinSuggestion(context, ref, suggestion),
          onCreate: (suggestion) =>
              _createSuggestion(context, ref, suggestion),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(SnackBar(content: Text(keoErrorMessage(e))));
    }
  }

  Future<void> _joinSuggestion(
    BuildContext context,
    WidgetRef ref,
    KeoMatchSuggestion suggestion,
  ) async {
    final keoId = suggestion.keoId;
    if (keoId == null) return;
    await ref.read(keoRepositoryProvider).requestJoin(keoId);
    ref.invalidate(openKeosProvider);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    context.push('/keo/$keoId?title=${Uri.encodeComponent(suggestion.title)}');
  }

  Future<void> _createSuggestion(
    BuildContext context,
    WidgetRef ref,
    KeoMatchSuggestion suggestion,
  ) async {
    final start = DateTime.tryParse(suggestion.proposedStart ?? '');
    final end = DateTime.tryParse(suggestion.proposedEnd ?? '');
    if (start == null || end == null) {
      throw 'no_matchable_keo';
    }
    final id = await ref.read(keoRepositoryProvider).createAutoMatchedKeo(
          title: suggestion.title,
          start: start,
          end: end,
          size: suggestion.sizeTarget,
          genres: suggestion.genres,
          joinMode: suggestion.joinMode,
        );
    ref.invalidate(openKeosProvider);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    context.push('/keo/$id?title=${Uri.encodeComponent(suggestion.title)}');
  }
```

Update the empty-board branch so users can still access auto-match when there are no listed keo:

```dart
          if (keos.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 96, top: AppSpacing.sm),
              children: [
                _boardHeader(context),
                _matchBanner(context, ref),
                EmptyState(
                  icon: Icons.groups,
                  title: 'Chưa có kèo quanh đây',
                  subtitle:
                      'Hãy thử ghép nhóm tự động hoặc là người đầu tiên rủ mọi người đi hát.',
                  actionLabel: 'Tạo kèo đầu tiên',
                  onAction: () => context.push('/keo/create'),
                ),
              ],
            );
          }
```

- [ ] **Step 4: Run board tests**

Run:

```powershell
flutter test test/features/keo/keo_board_gate_test.dart
```

Expected: PASS, including the existing Pro FAB gate tests.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/keo/presentation/keo_board_screen.dart test/features/keo/keo_board_gate_test.dart
git commit -m "feat(keo): wire auto-match banner"
```

---

### Task 5: Focused Verification and Final Pass

**Files:**
- Verify only; no file edits expected unless a previous task revealed a failure.

- [ ] **Step 1: Run focused Flutter tests**

Run:

```powershell
flutter test test/features/keo
```

Expected: PASS for all keo feature tests.

- [ ] **Step 2: Run full analysis**

Run:

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run database tests**

Run:

```powershell
supabase test db
```

Expected: PASS for existing and new pgTAP tests.

- [ ] **Step 4: Run debug APK build**

Run:

```powershell
flutter build apk --debug --dart-define-from-file=env/dev.json
```

Expected: debug APK build succeeds.

---

## Self-Review

- Spec coverage: server-side matching, sanitized results, explicit user confirmation before creation, Pro gate preservation, location fallback behavior, error handling, and SQL/Flutter verification are covered by Tasks 1-5.
- Placeholder scan: the plan contains concrete file paths, concrete SQL, concrete Dart snippets, exact commands, and expected outcomes.
- Type consistency: SQL `keo_match_suggestion` fields match Dart `KeoMatchSuggestion` JSON keys; RPC names match repository methods; UI uses the repository method names defined in Task 2.
- Scope check: this is one implementation slice. Dedicated availability windows and plan auto-proposal are not included in this implementation plan because the approved spec explicitly kept them out of the first slice.
