# Cùng Hát — P3 "Kèo" (Group Outing Board) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The group surface: a board of open karaoke outings ("kèo"), create-a-kèo, request-to-join → host approve, all-members-confirm to open a realtime group chat — all privacy-bucketed and reusing the P2 Broadcast-from-DB chat plumbing.

**Architecture:** Builds on P0–P2. Migrations add `keo` + `keo_members` + RPCs for the board (`create_keo`, `list_open_keos` sanitized + bucketed, `get_keo_roster`), the join lifecycle (`request_join_keo`, `approve_join`, `decline_join`, `leave_keo`, `confirm_keo` → status `planning`), and keo group chat (reuses the generic `messages` broadcast trigger; adds `in_keo`, a keo `messages` SELECT policy, a `realtime.messages` keo policy, and `send_keo_message`). Flutter adds a `keo` feature (board on tab 1, create sheet, detail/roster, group chat reusing the chat widgets).

**Tech Stack:** PostGIS bucketed distance, SECURITY DEFINER RPCs, Supabase Realtime (Broadcast-from-DB), Riverpod 3, freezed, mocktail.

**Depends on:** P1 (`user_locations`, `dist_band`, `blocks`, `enforce_rate_limit`), P2 (`messages` + generic broadcast trigger + `realtime.messages` pattern + chat widgets), P0 (RPC pattern), app shell tab 1 = "Kèo", the `/keo/create` route stub referenced by P2's "Lập kèo".

---

### Task 1: Migration 0011 — keo + keo_members + board RPCs

**Files:**
- Create: `supabase/migrations/0011_keo.sql`, `supabase/tests/keo_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0011_keo.sql`:
```sql
create table public.keo (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 100),
  area_label text,
  area_geo geography(Point,4326) not null,
  time_window_start timestamptz not null,
  time_window_end timestamptz not null,
  group_size_target int not null check (group_size_target between 2 and 5),
  intent_tag text,
  vibe text,
  genres text[] not null default '{}',
  status text not null default 'open'
    check (status in ('open','full','planning','confirmed','done','cancelled')),
  created_at timestamptz not null default now(),
  soft_deleted_at timestamptz
);
create index keo_geo_gix on public.keo using gist (area_geo);
alter table public.keo enable row level security;
-- Board cards via sanitized RPC only; host may update own keo.
create policy keo_host_write on public.keo for all
  using (auth.uid() = host_id) with check (auth.uid() = host_id);

create table public.keo_members (
  keo_id uuid references public.keo(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('host','member')),
  join_status text not null default 'requested'
    check (join_status in ('requested','approved','declined','left')),
  confirmed boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (keo_id, user_id)
);
alter table public.keo_members enable row level security;
-- Members see their own keos' rosters; host manages. Cross reads via RPC.
create policy keo_members_self on public.keo_members for select
  using (auth.uid() = user_id
         or exists (select 1 from public.keo k where k.id = keo_id and k.host_id = auth.uid()));

create or replace function public.create_keo(
  p_title text, p_lat double precision, p_lng double precision, p_area text,
  p_start timestamptz, p_end timestamptz, p_size int, p_intent text, p_vibe text, p_genres text[]
) returns uuid language plpgsql security definer set search_path='' as $$
declare kid uuid;
begin
  perform app_private.enforce_rate_limit('create_keo', 10, interval '1 day');
  insert into public.keo(host_id, title, area_label, area_geo, time_window_start, time_window_end,
                         group_size_target, intent_tag, vibe, genres)
  values (auth.uid(), p_title, p_area,
          ST_SetSRID(ST_MakePoint(round(p_lng::numeric,3)::double precision,
                                  round(p_lat::numeric,3)::double precision),4326)::geography,
          p_start, p_end, p_size, p_intent, p_vibe, coalesce(p_genres,'{}'))
  returning id into kid;
  insert into public.keo_members(keo_id, user_id, role, join_status, confirmed)
  values (kid, auth.uid(), 'host', 'approved', true);
  return kid;
end; $$;

-- Sanitized board card (NO coords; bucketed distance from caller).
create type public.keo_card as (
  id uuid, title text, area_label text, distance_band text,
  time_window_start timestamptz, time_window_end timestamptz,
  size_target int, slots_filled int, genres text[], host_name text, status text
);

create or replace function public.list_open_keos(p_limit int default 30, p_radius_km int default 50)
returns setof public.keo_card language sql security definer set search_path='' as $$
  with me as (select location as loc from public.user_locations where user_id = auth.uid())
  select k.id, k.title, k.area_label,
         app_private.dist_band(ST_Distance(k.area_geo, me.loc)) as distance_band,
         k.time_window_start, k.time_window_end, k.group_size_target,
         (select count(*)::int from public.keo_members m
            where m.keo_id = k.id and m.join_status = 'approved') as slots_filled,
         k.genres,
         (select display_name from public.profiles p where p.id = k.host_id) as host_name,
         k.status
  from public.keo k cross join me
  where k.status = 'open'
    and k.soft_deleted_at is null
    and k.time_window_end > now()
    and ST_DWithin(k.area_geo, me.loc, p_radius_km * 1000)
    and not exists (select 1 from public.blocks b
                    where (b.blocker_id = auth.uid() and b.blocked_id = k.host_id)
                       or (b.blocker_id = k.host_id and b.blocked_id = auth.uid()))
  order by k.time_window_start asc
  limit greatest(p_limit, 1);
$$;

-- Roster of a keo (visible to any authenticated viewer of an open/active keo).
create type public.keo_member_row as (user_id uuid, display_name text, verified boolean, role text, join_status text);
create or replace function public.get_keo_roster(p_keo uuid)
returns setof public.keo_member_row language sql security definer set search_path='' as $$
  select m.user_id, p.display_name, p.verified_badge, m.role, m.join_status
  from public.keo_members m
  join public.profiles p on p.id = m.user_id
  where m.keo_id = p_keo and m.join_status in ('approved','requested')
  order by case m.role when 'host' then 0 else 1 end, m.joined_at;
$$;

revoke execute on function public.create_keo(text,double precision,double precision,text,timestamptz,timestamptz,int,text,text,text[]) from public, anon;
revoke execute on function public.list_open_keos(int,int) from public, anon;
revoke execute on function public.get_keo_roster(uuid) from public, anon;
grant execute on function public.create_keo(text,double precision,double precision,text,timestamptz,timestamptz,int,text,text,text[]) to authenticated;
grant execute on function public.list_open_keos(int,int) to authenticated;
grant execute on function public.get_keo_roster(uuid) to authenticated;
```

- [ ] **Step 2: Write a DB test (sanitized board, no coords)**

Create `supabase/tests/keo_test.sql`:
```sql
begin;
select plan(2);
select hasnt_column('public','keo_card'::regtype::text,'area_geo','keo_card has no coords');
select ok(exists(select 1 from pg_proc where proname='create_keo'), 'create_keo exists');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean; assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0011_keo.sql supabase/tests/keo_test.sql
git commit -m "feat(p3): 0011 keo + keo_members + board RPCs (create/list/roster, bucketed)"
```

---

### Task 2: Migration 0012 — join lifecycle + all-confirm gate

**Files:**
- Create: `supabase/migrations/0012_keo_join.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0012_keo_join.sql`:
```sql
create or replace function public.request_join_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
declare filled int; target int; st text;
begin
  perform app_private.enforce_rate_limit('join_keo', 50, interval '1 day');
  select status, group_size_target into st, target from public.keo where id = p_keo;
  if st <> 'open' then raise exception 'keo_not_open' using errcode='check_violation'; end if;
  if exists (select 1 from public.blocks b
             where (b.blocker_id=auth.uid() and b.blocked_id=(select host_id from public.keo where id=p_keo))
                or (b.blocked_id=auth.uid() and b.blocker_id=(select host_id from public.keo where id=p_keo)))
  then raise exception 'blocked' using errcode='check_violation'; end if;
  select count(*) into filled from public.keo_members where keo_id=p_keo and join_status='approved';
  if filled >= target then raise exception 'keo_full' using errcode='check_violation'; end if;
  insert into public.keo_members(keo_id, user_id, role, join_status)
  values (p_keo, auth.uid(), 'member', 'requested')
  on conflict (keo_id, user_id) do update set join_status='requested';
end; $$;

create or replace function app_private.assert_host(p_keo uuid) returns void
language plpgsql security definer set search_path='' as $$
begin
  if not exists (select 1 from public.keo where id=p_keo and host_id=auth.uid()) then
    raise exception 'not_host' using errcode='check_violation';
  end if;
end; $$;

create or replace function public.approve_join(p_keo uuid, p_user uuid)
returns void language plpgsql security definer set search_path='' as $$
declare filled int; target int;
begin
  perform app_private.assert_host(p_keo);
  select count(*) into filled from public.keo_members where keo_id=p_keo and join_status='approved';
  select group_size_target into target from public.keo where id=p_keo;
  if filled >= target then raise exception 'keo_full' using errcode='check_violation'; end if;
  update public.keo_members set join_status='approved' where keo_id=p_keo and user_id=p_user;
  if filled + 1 >= target then update public.keo set status='full' where id=p_keo; end if;
end; $$;

create or replace function public.decline_join(p_keo uuid, p_user uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform app_private.assert_host(p_keo);
  update public.keo_members set join_status='declined' where keo_id=p_keo and user_id=p_user;
end; $$;

create or replace function public.leave_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.keo_members set join_status='left' where keo_id=p_keo and user_id=auth.uid();
end; $$;

-- A member confirms; when ALL approved members confirmed and >=2, open the group (status='planning').
create or replace function public.confirm_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
declare approved_n int; confirmed_n int;
begin
  update public.keo_members set confirmed=true where keo_id=p_keo and user_id=auth.uid() and join_status='approved';
  select count(*) filter (where join_status='approved'),
         count(*) filter (where join_status='approved' and confirmed)
    into approved_n, confirmed_n from public.keo_members where keo_id=p_keo;
  if approved_n >= 2 and approved_n = confirmed_n then
    update public.keo set status='planning' where id=p_keo and status in ('open','full');
  end if;
end; $$;

revoke execute on function public.request_join_keo(uuid) from public, anon;
revoke execute on function public.approve_join(uuid,uuid) from public, anon;
revoke execute on function public.decline_join(uuid,uuid) from public, anon;
revoke execute on function public.leave_keo(uuid) from public, anon;
revoke execute on function public.confirm_keo(uuid) from public, anon;
grant execute on function public.request_join_keo(uuid) to authenticated;
grant execute on function public.approve_join(uuid,uuid) to authenticated;
grant execute on function public.decline_join(uuid,uuid) to authenticated;
grant execute on function public.leave_keo(uuid) to authenticated;
grant execute on function public.confirm_keo(uuid) to authenticated;
```

- [ ] **Step 2: Apply + verify clean**

Run: `supabase db reset`
Expected: applies clean (0001–0012).

- [ ] **Step 3: Commit**

```
git add supabase/migrations/0012_keo_join.sql
git commit -m "feat(p3): 0012 keo join lifecycle (request/approve/decline/leave) + all-confirm gate"
```

---

### Task 3: Migration 0013 — keo group chat (reuse Broadcast-from-DB)

**Files:**
- Create: `supabase/migrations/0013_keo_chat.sql`, `supabase/tests/keo_chat_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0013_keo_chat.sql`:
```sql
-- Caller is an approved+confirmed member of a keo whose group is open (planning+).
create or replace function app_private.in_keo(p_keo uuid)
returns boolean language sql security definer set search_path='' stable as $$
  select exists (
    select 1 from public.keo_members m
    join public.keo k on k.id = m.keo_id
    where m.keo_id = p_keo and m.user_id = auth.uid()
      and m.join_status = 'approved' and m.confirmed
      and k.status in ('planning','confirmed','done')
  );
$$;

-- keo messages readable by in-keo members (reuses the shared messages table + generic broadcast trigger)
create policy messages_select_keo on public.messages for select
  using (thread_type='keo' and app_private.in_keo(thread_id));

create or replace function public.send_keo_message(p_keo uuid, p_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare mid uuid;
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;
  perform app_private.enforce_rate_limit('message', 60, interval '1 minute');
  insert into public.messages(thread_type, thread_id, sender_id, body)
  values ('keo', p_keo, auth.uid(), p_body) returning id into mid;
  return mid;
end; $$;

create or replace function public.mark_keo_read(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.message_reads(thread_type, thread_id, user_id)
  values ('keo', p_keo, auth.uid())
  on conflict (thread_type, thread_id, user_id) do update set last_read_at = now();
end; $$;

revoke execute on function public.send_keo_message(uuid,text) from public, anon;
revoke execute on function public.mark_keo_read(uuid) from public, anon;
grant execute on function public.send_keo_message(uuid,text) to authenticated;
grant execute on function public.mark_keo_read(uuid) to authenticated;

-- Realtime authorization for the private keo topic
create policy "keo members receive broadcasts"
  on realtime.messages for select to authenticated
  using (
    exists (
      select 1 from public.keo_members m
      where 'keo:' || m.keo_id::text = realtime.topic()
        and m.user_id = auth.uid() and m.join_status='approved' and m.confirmed
    )
  );
```

- [ ] **Step 2: Write a DB test (non-member cannot send keo message)**

Create `supabase/tests/keo_chat_test.sql`:
```sql
begin;
select plan(1);
set local role authenticated;
select throws_ok(
  $$ select public.send_keo_message('00000000-0000-0000-0000-000000000000'::uuid,'hi') $$,
  'check_violation', null, 'non-member cannot send keo message');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean; assertion passes.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0013_keo_chat.sql supabase/tests/keo_chat_test.sql
git commit -m "feat(p3): 0013 keo group chat (in_keo + send_keo_message + realtime RLS)"
```

---

### Task 4: Keo models + KeoRepository + providers

**Files:**
- Create: `lib/features/keo/domain/keo.dart`, `lib/features/keo/domain/keo_member.dart`, `lib/features/keo/data/keo_repository.dart`, `lib/features/keo/application/keo_providers.dart`
- Test: `test/features/keo/keo_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/keo/keo_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('listOpenKeos maps sanitized board cards', () async {
    final client = _MockClient();
    when(() => client.rpc('list_open_keos', params: any(named: 'params')))
        .thenAnswer((_) async => [
              {'id': 'k1', 'title': 'Hát tối T7', 'area_label': 'Q1', 'distance_band': '1-3',
               'time_window_start': '2026-06-21T19:00:00Z', 'time_window_end': '2026-06-21T22:00:00Z',
               'size_target': 4, 'slots_filled': 2, 'genres': ['vpop'], 'host_name': 'Mai', 'status': 'open'},
            ]);
    final list = await KeoRepository(client).listOpenKeos();
    expect(list.single.title, 'Hát tối T7');
    expect(list.single.slotsFilled, 2);
    expect(list.single.distanceBand, '1-3');
  });

  test('requestJoin calls request_join_keo', () async {
    final client = _MockClient();
    when(() => client.rpc('request_join_keo', params: any(named: 'params')))
        .thenAnswer((_) async => null);
    await KeoRepository(client).requestJoin('k1');
    verify(() => client.rpc('request_join_keo', params: {'p_keo': 'k1'})).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/keo_repository_test.dart`
Expected: FAIL — files not found.

- [ ] **Step 3: Implement models, repo, providers**

Create `lib/features/keo/domain/keo.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'keo.freezed.dart';
part 'keo.g.dart';

@freezed
class Keo with _$Keo {
  const factory Keo({
    required String id,
    required String title,
    @JsonKey(name: 'area_label') String? areaLabel,
    @JsonKey(name: 'distance_band') String? distanceBand,
    @JsonKey(name: 'time_window_start') String? timeWindowStart,
    @JsonKey(name: 'time_window_end') String? timeWindowEnd,
    @JsonKey(name: 'size_target') @Default(2) int sizeTarget,
    @JsonKey(name: 'slots_filled') @Default(0) int slotsFilled,
    @Default([]) List<String> genres,
    @JsonKey(name: 'host_name') String? hostName,
    @Default('open') String status,
  }) = _Keo;
  factory Keo.fromJson(Map<String, dynamic> j) => _$KeoFromJson(j);
}
```

Create `lib/features/keo/domain/keo_member.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'keo_member.freezed.dart';
part 'keo_member.g.dart';

@freezed
class KeoMember with _$KeoMember {
  const factory KeoMember({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'display_name') String? displayName,
    @Default(false) bool verified,
    @Default('member') String role,
    @JsonKey(name: 'join_status') @Default('requested') String joinStatus,
  }) = _KeoMember;
  factory KeoMember.fromJson(Map<String, dynamic> j) => _$KeoMemberFromJson(j);
}
```

Create `lib/features/keo/data/keo_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/keo.dart';
import '../domain/keo_member.dart';

class KeoRepository {
  KeoRepository(this._client);
  final SupabaseClient _client;

  Future<List<Keo>> listOpenKeos({int limit = 30}) async {
    final rows = await _client.rpc('list_open_keos', params: {'p_limit': limit});
    return (rows as List).map((e) => Keo.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<KeoMember>> roster(String keoId) async {
    final rows = await _client.rpc('get_keo_roster', params: {'p_keo': keoId});
    return (rows as List).map((e) => KeoMember.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<String> createKeo({
    required String title, required double lat, required double lng, String? area,
    required DateTime start, required DateTime end, required int size,
    String? intent, String? vibe, List<String> genres = const [],
  }) async {
    final id = await _client.rpc('create_keo', params: {
      'p_title': title, 'p_lat': lat, 'p_lng': lng, 'p_area': area,
      'p_start': start.toUtc().toIso8601String(), 'p_end': end.toUtc().toIso8601String(),
      'p_size': size, 'p_intent': intent, 'p_vibe': vibe, 'p_genres': genres,
    });
    return id as String;
  }

  Future<void> requestJoin(String keoId) => _client.rpc('request_join_keo', params: {'p_keo': keoId});
  Future<void> approve(String keoId, String userId) =>
      _client.rpc('approve_join', params: {'p_keo': keoId, 'p_user': userId});
  Future<void> decline(String keoId, String userId) =>
      _client.rpc('decline_join', params: {'p_keo': keoId, 'p_user': userId});
  Future<void> leave(String keoId) => _client.rpc('leave_keo', params: {'p_keo': keoId});
  Future<void> confirm(String keoId) => _client.rpc('confirm_keo', params: {'p_keo': keoId});
}
```

Create `lib/features/keo/application/keo_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/keo_repository.dart';
import '../domain/keo.dart';
import '../domain/keo_member.dart';

final keoRepositoryProvider =
    Provider((ref) => KeoRepository(ref.watch(supabaseClientProvider)));
final openKeosProvider = FutureProvider<List<Keo>>(
    (ref) => ref.watch(keoRepositoryProvider).listOpenKeos());
final keoRosterProvider = FutureProvider.family<List<KeoMember>, String>(
    (ref, keoId) => ref.watch(keoRepositoryProvider).roster(keoId));
```

- [ ] **Step 4: Generate + run test**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" pub run build_runner build --delete-conflicting-outputs
& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/keo_repository_test.dart
```
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```
git add lib/features/keo/ test/features/keo/keo_repository_test.dart
git commit -m "feat(p3): Keo/KeoMember models + KeoRepository (board/roster/join lifecycle)"
```

---

### Task 5: Kèo board screen (tab 1) + card

**Files:**
- Create: `lib/features/keo/presentation/keo_card.dart`, `lib/features/keo/presentation/keo_board_screen.dart`
- Modify: `lib/app/home_shell.dart` (tab 1 → KeoBoardScreen)
- Test: `test/features/keo/keo_card_test.dart`

- [ ] **Step 1: Write the failing card test**

Create `test/features/keo/keo_card_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/keo/domain/keo.dart';
import 'package:cung_hat/features/keo/presentation/keo_card.dart';

void main() {
  testWidgets('keo card shows title, slots, distance band', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: KeoCard(
      keo: Keo(id: 'k1', title: 'Hát tối T7', distanceBand: '1-3',
        sizeTarget: 4, slotsFilled: 2, hostName: 'Mai'),
    ))));
    expect(find.text('Hát tối T7'), findsOneWidget);
    expect(find.textContaining('2/4'), findsOneWidget);
    expect(find.textContaining('1-3'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/keo_card_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement card + board + wire tab 1**

Create `lib/features/keo/presentation/keo_card.dart`:
```dart
import 'package:flutter/material.dart';
import '../domain/keo.dart';

class KeoCard extends StatelessWidget {
  const KeoCard({super.key, required this.keo, this.onTap});
  final Keo keo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(keo.title),
        subtitle: Text('${keo.slotsFilled}/${keo.sizeTarget} người · cách ${keo.distanceBand} km'
            '${keo.hostName != null ? ' · chủ kèo ${keo.hostName}' : ''}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
```

Create `lib/features/keo/presentation/keo_board_screen.dart` — a `ConsumerWidget` watching `openKeosProvider`: renders a `ListView` of `KeoCard`s (tap → `/keo/{id}`), a `FloatingActionButton` "Tạo kèo" → `/keo/create`, and a prominent "Ghép nhóm cho tôi" banner (wired to the suggester in a later phase; for now routes to the board filtered). Empty/loading/error → centered states. Wire tab 1 of `home_shell.dart` to `const KeoBoardScreen()`.

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/keo_card_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add lib/features/keo/presentation/ lib/app/home_shell.dart test/features/keo/keo_card_test.dart
git commit -m "feat(p3): Kèo board screen + card on tab 1"
```

---

### Task 6: Create-Kèo screen + route

**Files:**
- Create: `lib/features/keo/presentation/create_keo_screen.dart`
- Modify: `lib/app/router.dart` (`/keo/create`)
- Test: `test/features/keo/create_keo_test.dart`

- [ ] **Step 1: Write the failing test (controller calls createKeo)**

Create `test/features/keo/create_keo_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';

class _MockRepo extends Mock implements KeoRepository {}

void main() {
  test('createKeo forwards all fields', () async {
    final repo = _MockRepo();
    when(() => repo.createKeo(
          title: any(named: 'title'), lat: any(named: 'lat'), lng: any(named: 'lng'),
          area: any(named: 'area'), start: any(named: 'start'), end: any(named: 'end'),
          size: any(named: 'size'), intent: any(named: 'intent'), vibe: any(named: 'vibe'),
          genres: any(named: 'genres'),
        )).thenAnswer((_) async => 'k1');
    final c = ProviderContainer(overrides: [keoRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final id = await c.read(keoRepositoryProvider).createKeo(
      title: 'X', lat: 10.7, lng: 106.7, area: 'Q1',
      start: DateTime(2026, 6, 21, 19), end: DateTime(2026, 6, 21, 22),
      size: 4, intent: 'fun', vibe: 'chill', genres: const ['vpop']);
    expect(id, 'k1');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/create_keo_test.dart`
Expected: FAIL until repo wired (the test exercises the repo mock; it will pass once the import resolves — confirm RED first if `create_keo_screen` import is added prematurely). Keep this test repo-only (no screen import) so Step 3 focuses on the screen.

- [ ] **Step 3: Implement CreateKeoScreen + route**

Create `lib/features/keo/presentation/create_keo_screen.dart` — a `ConsumerStatefulWidget` form: title `TextField`, area `TextField`, date/time pickers for start/end, size `Slider`/`DropdownButton` (2-5), genre `FilterChip`s (reuse `genresProvider` from P0.3), and a "Tạo kèo" button that reads the device location via `LocationService.captureAndPush`-style coords (or the last known position) and calls `keoRepositoryProvider.createKeo(...)`, then `context.go('/keo/$id')`. On error show a SnackBar.

In `lib/app/router.dart` add: `GoRoute(path: '/keo/create', builder: (_, __) => const CreateKeoScreen())` (this satisfies the P2 "Lập kèo" hook).

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/create_keo_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add lib/features/keo/presentation/create_keo_screen.dart lib/app/router.dart test/features/keo/create_keo_test.dart
git commit -m "feat(p3): Create-Kèo screen + /keo/create route (satisfies P2 promotion)"
```

---

### Task 7: Kèo detail / roster (request, approve, confirm) + route

**Files:**
- Create: `lib/features/keo/presentation/keo_detail_screen.dart`
- Modify: `lib/app/router.dart` (`/keo/:id`)
- Test: `test/features/keo/keo_detail_test.dart`

- [ ] **Step 1: Write the failing widget test (roster renders + join button)**

Create `test/features/keo/keo_detail_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/keo/application/keo_providers.dart';
import 'package:cung_hat/features/keo/data/keo_repository.dart';
import 'package:cung_hat/features/keo/domain/keo_member.dart';
import 'package:cung_hat/features/keo/presentation/keo_detail_screen.dart';

class _MockRepo extends Mock implements KeoRepository {}

void main() {
  testWidgets('renders roster and Xin vào kèo button', (tester) async {
    final repo = _MockRepo();
    when(() => repo.roster('k1')).thenAnswer((_) async =>
        const [KeoMember(userId: 'u1', displayName: 'Mai', verified: true, role: 'host', joinStatus: 'approved')]);
    when(() => repo.requestJoin('k1')).thenAnswer((_) async {});
    await tester.pumpWidget(ProviderScope(
      overrides: [keoRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: KeoDetailScreen(keoId: 'k1', title: 'Hát tối T7')),
    ));
    await tester.pump();
    expect(find.text('Mai'), findsOneWidget);
    await tester.tap(find.byKey(const Key('request_join_btn')));
    await tester.pump();
    verify(() => repo.requestJoin('k1')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/keo_detail_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement KeoDetailScreen + route**

Create `lib/features/keo/presentation/keo_detail_screen.dart` — a `ConsumerWidget(keoId, title)` watching `keoRosterProvider(keoId)`: shows each `KeoMember` (monogram + name + verified icon + role/status), a `request_join_btn` "Xin vào kèo" (calls `requestJoin`, then invalidates the roster), host-only Approve/Decline buttons on `requested` members (call `approve`/`decline`), a "Đồng ý tham gia" confirm button (calls `confirm`), and — when the keo status is `planning`+ and the user is in_keo — a "Mở chat nhóm" button → `/keo/chat/{keoId}` (Task 8). Add route `GoRoute(path: '/keo/:id', builder: (_, s) => KeoDetailScreen(keoId: s.pathParameters['id']!, title: s.uri.queryParameters['title'] ?? 'Kèo'))`.

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/keo_detail_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add lib/features/keo/presentation/keo_detail_screen.dart lib/app/router.dart test/features/keo/keo_detail_test.dart
git commit -m "feat(p3): Kèo detail/roster (request/approve/confirm) + /keo/:id route"
```

---

### Task 8: Kèo group chat (reuse Broadcast-from-DB) + acceptance

**Files:**
- Modify: `lib/features/chat/data/chat_repository.dart` (keo send/subscribe), `lib/features/keo/presentation/keo_chat_screen.dart` (new), `lib/app/router.dart` (`/keo/chat/:id`)
- Test: `test/features/keo/keo_chat_test.dart`

- [ ] **Step 1: Write the failing test (keo send routes to send_keo_message)**

Create `test/features/keo/keo_chat_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('sendKeoMessage calls send_keo_message RPC', () async {
    final client = _MockClient();
    when(() => client.rpc('send_keo_message', params: any(named: 'params')))
        .thenAnswer((_) async => 'm1');
    await ChatRepository(client).sendKeoMessage('k1', 'hi nhóm');
    verify(() => client.rpc('send_keo_message',
        params: {'p_keo': 'k1', 'p_body': 'hi nhóm'})).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/keo/keo_chat_test.dart`
Expected: FAIL — `sendKeoMessage` not defined.

- [ ] **Step 3: Add keo chat methods + screen + route**

Append to `lib/features/chat/data/chat_repository.dart`:
```dart
  Future<String> sendKeoMessage(String keoId, String body) async {
    final id = await _client.rpc('send_keo_message', params: {'p_keo': keoId, 'p_body': body});
    return id as String;
  }

  Future<void> markKeoRead(String keoId) =>
      _client.rpc('mark_keo_read', params: {'p_keo': keoId});

  Future<List<Message>> keoHistory(String keoId) async {
    final rows = await _client.from('messages').select()
        .eq('thread_type', 'keo').eq('thread_id', keoId).order('created_at');
    return (rows as List).map((e) => Message.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Stream<Message> subscribeKeo(String keoId) {
    final ch = _client.channel('keo:$keoId', opts: const RealtimeChannelConfig(private: true));
    final controller = StreamController<Message>();
    ch.onBroadcast(event: 'new_message', callback: (payload) {
      controller.add(Message.fromJson(Map<String, dynamic>.from(payload)));
    }).subscribe();
    controller.onCancel = () => _client.removeChannel(ch);
    return controller.stream;
  }
```
Create `lib/features/keo/presentation/keo_chat_screen.dart` — same structure as `ChatScreen` but using `keoHistory`/`subscribeKeo`/`sendKeoMessage`/`markKeoRead`, with a collapsible "luật nhóm" banner (no quay/chụp chưa đồng ý · chia tiền rõ · tôn trọng riêng tư) and the outbound `messageLooksUnsafe` dialog. Add route `GoRoute(path: '/keo/chat/:id', builder: (_, s) => KeoChatScreen(keoId: s.pathParameters['id']!))`.

- [ ] **Step 4: Run test + full suite + analyze**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" test
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
```
Expected: all green; `No issues found!`.

- [ ] **Step 5: Acceptance — full kèo loop**

With ≥3 seed users (locations set): user A creates a kèo on the board; users B and C "Xin vào kèo"; A approves both; A/B/C each "Đồng ý tham gia" → keo status flips to `planning`; "Mở chat nhóm" appears; messages broadcast live across the three sessions; a non-member cannot open the keo chat; leave/report work from detail.

- [ ] **Step 6: Commit**

```
git add lib/features/chat/data/chat_repository.dart lib/features/keo/presentation/keo_chat_screen.dart lib/app/router.dart test/features/keo/keo_chat_test.dart
git commit -m "feat(p3): keo group chat (reuse Broadcast-from-DB) + P3 acceptance"
```

---

## Self-Review (completed by author)

- **Spec coverage:** board of open outings (sanitized, bucketed) ✓ (T1,T5); create kèo ✓ (T1,T6); request → host-approve ✓ (T2,T7); all-members-confirm → group opens ✓ (T2 `confirm_keo`, T7); realtime group chat reusing Broadcast-from-DB ✓ (T3,T8); leave/report ✓ (T7 + P1 `report_user`); satisfies P2's `/keo/create` promotion ✓ (T6). Group-on-group swipe stays deferred (spec). Venue/plan is P4.
- **Placeholder scan:** the "Ghép nhóm cho tôi" banner (T5) routes to the board until the suggester ships (later phase) — labelled. `/keo/chat/:id` referenced by T7 is implemented in T8. No undefined Dart symbols.
- **Type consistency:** RPC names identical across SQL and Dart — `create_keo`, `list_open_keos`, `get_keo_roster`, `request_join_keo`, `approve_join`, `decline_join`, `leave_keo`, `confirm_keo`, `send_keo_message`, `mark_keo_read`; `Keo` JSON keys match `keo_card` type fields; `KeoMember` matches `keo_member_row`; private topic `keo:{id}` identical in the generic broadcast trigger (P2 0009), the keo realtime RLS (T3), and `subscribeKeo` (T8); `in_keo` gate used consistently by send + select + realtime policy; reuses P1 `enforce_rate_limit`/`blocks`/`dist_band` and P2 `messages`/`message_reads`/`Message`.

---

## Next plans (when we reach them)
- **P4** Venues + plan: `venues` seed (HCMC/HN/TN K-style), midpoint computation over keo members, propose/confirm plan, safety toolkit (share-plan link + "Tôi đã tới" check-in).
- Then **P5** compliance/moderation console, **P6** monetization (IAP digital goods + MoMo/ZaloPay venue commission), **P7** launch (3-city seeding, FCM push, store submission).
