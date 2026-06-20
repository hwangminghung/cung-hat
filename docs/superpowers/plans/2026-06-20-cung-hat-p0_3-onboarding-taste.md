# Cùng Hát — P0.3 Onboarding (Consent + 18+ Gate) & Music-Taste Picker

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After phone login, a new user completes onboarding: a hard **18+ DOB gate** (enforced server-side), **granular PDPL consent**, basic profile, and a gamified **music-taste** capture (genres + artists + **bài tủ from a curated song list**). On completion the user has a profile row and the router lets them into the app.

**Architecture:** Builds on P0 + P0.2. New migration `0004` adds artist/song reference tables, `consents`, and the `user_genres`/`user_artists`/`user_baitu` taste graph, plus RPCs `record_consent`, `get_my_taste`, `upsert_my_taste`, and a **replacement** `upsert_my_profile` that computes `age_verified` from DOB and rejects under-18. Flutter: an `onboarding` feature with a stepper coordinating DOB → consent → profile → taste, replacing the P0.2 placeholder route.

**Tech Stack:** Supabase Postgres + RLS + SECURITY DEFINER RPCs, Riverpod 3, freezed, mocktail.

**Depends on:** P0 (`Profile`, `profileRepositoryProvider`, `myProfileProvider`, `upsert_my_profile`, `music_genres`, RPC pattern from `0002`), P0.2 (auth, `/onboarding` route placeholder, `goRouterProvider`).

---

### Task 1: Migration 0004 — taste graph, consents, 18+ gate

**Files:**
- Create: `supabase/migrations/0004_onboarding.sql`, `supabase/tests/onboarding_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0004_onboarding.sql`:
```sql
-- Reference: artists + curated karaoke songs (public read)
create table public.music_artists (
  id text primary key, name text not null, is_curated boolean not null default true, sort int not null default 0
);
create table public.songs (
  id text primary key, title text not null, artist text not null, is_curated boolean not null default true
);
alter table public.music_artists enable row level security;
alter table public.songs enable row level security;
create policy music_artists_read on public.music_artists for select using (true);
create policy songs_read on public.songs for select using (true);

insert into public.music_artists (id, name, sort) values
  ('son_tung','Sơn Tùng M-TP',1),('my_tam','Mỹ Tâm',2),('den_vau','Đen Vâu',3),
  ('hoang_thuy_linh','Hoàng Thùy Linh',4),('blackpink','BLACKPINK',5),('taylor_swift','Taylor Swift',6);
insert into public.songs (id, title, artist) values
  ('s1','Lạc Trôi','Sơn Tùng M-TP'),('s2','Ước Gì','Mỹ Tâm'),
  ('s3','Đưa Nhau Đi Trốn','Đen Vâu'),('s4','Để Mị Nói Cho Mà Nghe','Hoàng Thùy Linh'),
  ('s5','Nơi Này Có Anh','Sơn Tùng M-TP'),('s6','Em Của Ngày Hôm Qua','Sơn Tùng M-TP');

-- Taste graph (self-owned)
create table public.user_genres (
  user_id uuid references auth.users(id) on delete cascade,
  genre_id text references public.music_genres(id),
  primary key (user_id, genre_id)
);
create table public.user_artists (
  user_id uuid references auth.users(id) on delete cascade,
  artist_id text references public.music_artists(id),
  primary key (user_id, artist_id)
);
create table public.user_baitu (
  user_id uuid references auth.users(id) on delete cascade,
  song_id text references public.songs(id),
  position int not null default 0,
  primary key (user_id, song_id)
);
alter table public.user_genres enable row level security;
alter table public.user_artists enable row level security;
alter table public.user_baitu enable row level security;
create policy ug_self on public.user_genres for all using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy ua_self on public.user_artists for all using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy ub_self on public.user_baitu for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- Consents (PDPL)
create table public.consents (
  user_id uuid references auth.users(id) on delete cascade,
  purpose text not null check (purpose in ('location','photos','matching','marketing','cross_border')),
  granted boolean not null,
  granted_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  policy_version text not null,
  primary key (user_id, purpose)
);
alter table public.consents enable row level security;
create policy consents_self on public.consents for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

create or replace function public.record_consent(p_purpose text, p_granted boolean, p_policy_version text)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.consents (user_id, purpose, granted, policy_version, withdrawn_at)
  values (auth.uid(), p_purpose, p_granted, p_policy_version, case when p_granted then null else now() end)
  on conflict (user_id, purpose) do update
    set granted = excluded.granted,
        granted_at = case when excluded.granted then now() else public.consents.granted_at end,
        withdrawn_at = case when excluded.granted then null else now() end,
        policy_version = excluded.policy_version;
end; $$;

-- Replace upsert_my_profile: compute age_verified from DOB, REJECT under-18 (server-enforced gate)
create or replace function public.upsert_my_profile(
  p_display_name text, p_full_name text, p_dob date, p_bio text, p_language text
) returns public.my_profile
language plpgsql security definer set search_path='' as $$
declare result public.my_profile;
begin
  if p_dob is null or p_dob > (current_date - interval '18 years') then
    raise exception 'under_18' using errcode = 'check_violation';
  end if;
  insert into public.profiles (id, display_name, full_name, dob, age_verified, bio, language)
  values (auth.uid(), p_display_name, p_full_name, p_dob, true, p_bio, coalesce(p_language,'vi'))
  on conflict (id) do update
    set display_name=excluded.display_name, full_name=excluded.full_name,
        dob=excluded.dob, age_verified=true, bio=excluded.bio, language=excluded.language;
  select p.id,p.display_name,p.full_name,p.dob,p.age_verified,p.bio,p.language
    into result from public.profiles p where p.id=auth.uid();
  return result;
end; $$;
revoke execute on function public.upsert_my_profile(text,text,date,text,text) from public, anon;
grant execute on function public.upsert_my_profile(text,text,date,text,text) to authenticated;

-- Taste read/write
create or replace function public.get_my_taste()
returns jsonb language sql security definer set search_path='' as $$
  select jsonb_build_object(
    'genres', coalesce((select jsonb_agg(genre_id) from public.user_genres where user_id=auth.uid()), '[]'::jsonb),
    'artists', coalesce((select jsonb_agg(artist_id) from public.user_artists where user_id=auth.uid()), '[]'::jsonb),
    'baitu', coalesce((select jsonb_agg(song_id order by position) from public.user_baitu where user_id=auth.uid()), '[]'::jsonb)
  );
$$;

create or replace function public.upsert_my_taste(p_genre_ids text[], p_artist_ids text[], p_song_ids text[])
returns void language plpgsql security definer set search_path='' as $$
begin
  delete from public.user_genres where user_id=auth.uid();
  delete from public.user_artists where user_id=auth.uid();
  delete from public.user_baitu where user_id=auth.uid();
  insert into public.user_genres (user_id, genre_id)
    select auth.uid(), unnest(p_genre_ids);
  insert into public.user_artists (user_id, artist_id)
    select auth.uid(), unnest(p_artist_ids);
  insert into public.user_baitu (user_id, song_id, position)
    select auth.uid(), s, ordinality from unnest(p_song_ids) with ordinality as t(s, ordinality);
end; $$;

revoke execute on function public.record_consent(text,boolean,text) from public, anon;
revoke execute on function public.get_my_taste() from public, anon;
revoke execute on function public.upsert_my_taste(text[],text[],text[]) from public, anon;
grant execute on function public.record_consent(text,boolean,text) to authenticated;
grant execute on function public.get_my_taste() to authenticated;
grant execute on function public.upsert_my_taste(text[],text[],text[]) to authenticated;
```

- [ ] **Step 2: Write a DB test for the 18+ gate**

Create `supabase/tests/onboarding_test.sql`:
```sql
begin;
select plan(2);
select throws_ok(
  $$ select public.upsert_my_profile('X', 'X Y', current_date, null, 'vi') $$,
  'check_violation', null, 'under-18 DOB is rejected');
select ok(
  exists(select 1 from pg_proc where proname='upsert_my_taste'),
  'upsert_my_taste exists');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: applies clean; both assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0004_onboarding.sql supabase/tests/onboarding_test.sql
git commit -m "feat(p0.3): 0004 taste graph + consents + 18+ gate + taste RPCs"
```

---

### Task 2: Reference data (genres/artists/songs) — models, repo, providers

**Files:**
- Create: `lib/features/onboarding/domain/music_ref.dart`, `lib/features/onboarding/data/reference_repository.dart`, `lib/features/onboarding/application/reference_providers.dart`
- Test: `test/features/onboarding/reference_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/onboarding/reference_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/onboarding/data/reference_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}
class _MockBuilder extends Mock implements SupabaseQueryBuilder {}
class _MockFilter extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

void main() {
  test('genres() selects from music_genres ordered by sort', () async {
    final client = _MockClient();
    final qb = _MockBuilder();
    final fb = _MockFilter();
    when(() => client.from('music_genres')).thenReturn(qb);
    when(() => qb.select()).thenReturn(fb);
    when(() => fb.order('sort')).thenAnswer((_) async => [
      {'id': 'vpop', 'name_vi': 'V-Pop', 'name_en': 'V-Pop', 'sort': 1},
    ]);
    final repo = ReferenceRepository(client);
    final genres = await repo.genres();
    expect(genres.single.id, 'vpop');
    expect(genres.single.nameVi, 'V-Pop');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/reference_repository_test.dart`
Expected: FAIL — files not found.

- [ ] **Step 3: Implement models + repo + providers**

Create `lib/features/onboarding/domain/music_ref.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'music_ref.freezed.dart';
part 'music_ref.g.dart';

@freezed
class Genre with _$Genre {
  const factory Genre({
    required String id,
    @JsonKey(name: 'name_vi') required String nameVi,
    @JsonKey(name: 'name_en') required String nameEn,
  }) = _Genre;
  factory Genre.fromJson(Map<String, dynamic> j) => _$GenreFromJson(j);
}

@freezed
class Artist with _$Artist {
  const factory Artist({required String id, required String name}) = _Artist;
  factory Artist.fromJson(Map<String, dynamic> j) => _$ArtistFromJson(j);
}

@freezed
class Song with _$Song {
  const factory Song({required String id, required String title, required String artist}) = _Song;
  factory Song.fromJson(Map<String, dynamic> j) => _$SongFromJson(j);
}
```

Create `lib/features/onboarding/data/reference_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/music_ref.dart';

class ReferenceRepository {
  ReferenceRepository(this._client);
  final SupabaseClient _client;

  Future<List<Genre>> genres() async {
    final rows = await _client.from('music_genres').select().order('sort');
    return (rows as List).map((e) => Genre.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Artist>> artists() async {
    final rows = await _client.from('music_artists').select().order('sort');
    return (rows as List).map((e) => Artist.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Song>> songs() async {
    final rows = await _client.from('songs').select();
    return (rows as List).map((e) => Song.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
```

Create `lib/features/onboarding/application/reference_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/reference_repository.dart';
import '../domain/music_ref.dart';

final referenceRepositoryProvider =
    Provider((ref) => ReferenceRepository(ref.watch(supabaseClientProvider)));
final genresProvider = FutureProvider<List<Genre>>((ref) => ref.watch(referenceRepositoryProvider).genres());
final artistsProvider = FutureProvider<List<Artist>>((ref) => ref.watch(referenceRepositoryProvider).artists());
final songsProvider = FutureProvider<List<Song>>((ref) => ref.watch(referenceRepositoryProvider).songs());
```

- [ ] **Step 4: Generate + run test**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" pub run build_runner build --delete-conflicting-outputs
& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/reference_repository_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/onboarding/ test/features/onboarding/reference_repository_test.dart
git commit -m "feat(p0.3): reference data models/repo/providers (genres/artists/songs)"
```

---

### Task 3: Onboarding repository (consent + taste + profile) + providers

**Files:**
- Create: `lib/features/onboarding/data/onboarding_repository.dart`, `lib/features/onboarding/application/onboarding_providers.dart`
- Test: `test/features/onboarding/onboarding_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/onboarding/onboarding_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/onboarding/data/onboarding_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('recordConsent calls record_consent with params', () async {
    final client = _MockClient();
    when(() => client.rpc('record_consent', params: any(named: 'params')))
        .thenAnswer((_) async => null);
    await OnboardingRepository(client)
        .recordConsent(purpose: 'location', granted: true, policyVersion: 'v1');
    verify(() => client.rpc('record_consent', params: {
      'p_purpose': 'location', 'p_granted': true, 'p_policy_version': 'v1',
    })).called(1);
  });

  test('saveTaste calls upsert_my_taste with arrays', () async {
    final client = _MockClient();
    when(() => client.rpc('upsert_my_taste', params: any(named: 'params')))
        .thenAnswer((_) async => null);
    await OnboardingRepository(client)
        .saveTaste(genreIds: ['vpop'], artistIds: ['my_tam'], songIds: ['s2']);
    verify(() => client.rpc('upsert_my_taste', params: {
      'p_genre_ids': ['vpop'], 'p_artist_ids': ['my_tam'], 'p_song_ids': ['s2'],
    })).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/onboarding_repository_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement repository + provider**

Create `lib/features/onboarding/data/onboarding_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingRepository {
  OnboardingRepository(this._client);
  final SupabaseClient _client;

  Future<void> recordConsent({
    required String purpose, required bool granted, required String policyVersion,
  }) =>
      _client.rpc('record_consent', params: {
        'p_purpose': purpose, 'p_granted': granted, 'p_policy_version': policyVersion,
      });

  Future<void> saveTaste({
    required List<String> genreIds,
    required List<String> artistIds,
    required List<String> songIds,
  }) =>
      _client.rpc('upsert_my_taste', params: {
        'p_genre_ids': genreIds, 'p_artist_ids': artistIds, 'p_song_ids': songIds,
      });
}
```

Create `lib/features/onboarding/application/onboarding_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/onboarding_repository.dart';

final onboardingRepositoryProvider =
    Provider((ref) => OnboardingRepository(ref.watch(supabaseClientProvider)));
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/onboarding_repository_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```
git add lib/features/onboarding/data/onboarding_repository.dart lib/features/onboarding/application/onboarding_providers.dart test/features/onboarding/onboarding_repository_test.dart
git commit -m "feat(p0.3): OnboardingRepository (recordConsent + saveTaste)"
```

---

### Task 4: DOB + 18-gate step (client check; server enforces)

**Files:**
- Create: `lib/features/onboarding/presentation/dob_step.dart`
- Test: `test/features/onboarding/dob_step_test.dart`

- [ ] **Step 1: Write the failing test (pure age helper)**

Create `test/features/onboarding/dob_step_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/onboarding/presentation/dob_step.dart';

void main() {
  test('isAdult true for >=18', () {
    expect(isAdult(DateTime(2000, 1, 1), now: DateTime(2026, 6, 20)), isTrue);
  });
  test('isAdult false for <18', () {
    expect(isAdult(DateTime(2010, 1, 1), now: DateTime(2026, 6, 20)), isFalse);
  });
  test('isAdult false exactly one day before 18th birthday', () {
    expect(isAdult(DateTime(2008, 6, 21), now: DateTime(2026, 6, 20)), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/dob_step_test.dart`
Expected: FAIL — `dob_step.dart` not found.

- [ ] **Step 3: Implement the pure helper + the step widget**

Create `lib/features/onboarding/presentation/dob_step.dart`:
```dart
import 'package:flutter/material.dart';

bool isAdult(DateTime dob, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final eighteenth = DateTime(dob.year + 18, dob.month, dob.day);
  return !n.isBefore(eighteenth);
}

class DobStep extends StatelessWidget {
  const DobStep({super.key, required this.dob, required this.onPick});
  final DateTime? dob;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final ok = dob != null && isAdult(dob!);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Bạn sinh ngày nào? (phải đủ 18 tuổi)'),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
              initialDate: DateTime(2000),
            );
            if (picked != null) onPick(picked);
          },
          child: Text(dob == null ? 'Chọn ngày sinh'
              : '${dob!.day}/${dob!.month}/${dob!.year}'),
        ),
        if (dob != null && !ok)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Bạn phải đủ 18 tuổi để dùng ứng dụng.',
                style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/dob_step_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```
git add lib/features/onboarding/presentation/dob_step.dart test/features/onboarding/dob_step_test.dart
git commit -m "feat(p0.3): DOB step + isAdult 18-gate helper (server still enforces)"
```

---

### Task 5: Consent step

**Files:**
- Create: `lib/features/onboarding/presentation/consent_step.dart`
- Test: `test/features/onboarding/consent_step_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/onboarding/consent_step_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/onboarding/presentation/consent_step.dart';

void main() {
  testWidgets('toggling a purpose reports its new value', (tester) async {
    final changes = <String, bool>{};
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ConsentStep(
      values: const {'location': false, 'matching': false},
      onChanged: (k, v) => changes[k] = v,
    ))));
    await tester.tap(find.byKey(const Key('consent_location')));
    await tester.pump();
    expect(changes['location'], isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/consent_step_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement ConsentStep**

Create `lib/features/onboarding/presentation/consent_step.dart`:
```dart
import 'package:flutter/material.dart';

const consentPurposes = ['location', 'photos', 'matching', 'marketing', 'cross_border'];
const consentLabelsVi = {
  'location': 'Dùng vị trí để gợi ý người/kèo gần bạn',
  'photos': 'Lưu & hiển thị ảnh hồ sơ (tùy chọn)',
  'matching': 'Dùng gu nhạc để ghép người',
  'marketing': 'Nhận thông báo khuyến mãi',
  'cross_border': 'Dữ liệu lưu tại Singapore (chuyển xuyên biên giới)',
};

class ConsentStep extends StatelessWidget {
  const ConsentStep({super.key, required this.values, required this.onChanged});
  final Map<String, bool> values;
  final void Function(String purpose, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        for (final p in values.keys)
          SwitchListTile(
            key: Key('consent_$p'),
            title: Text(consentLabelsVi[p] ?? p),
            value: values[p] ?? false,
            onChanged: (v) => onChanged(p, v),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/consent_step_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/onboarding/presentation/consent_step.dart test/features/onboarding/consent_step_test.dart
git commit -m "feat(p0.3): granular PDPL consent step"
```

---

### Task 6: Taste-picker step (genres + artists + bài tủ from curated list)

**Files:**
- Create: `lib/features/onboarding/presentation/taste_step.dart`
- Test: `test/features/onboarding/taste_step_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/onboarding/taste_step_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/onboarding/domain/music_ref.dart';
import 'package:cung_hat/features/onboarding/presentation/taste_step.dart';

void main() {
  testWidgets('tapping a genre chip toggles selection', (tester) async {
    final selected = <String>{};
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TasteChips(
      items: const [Genre(id: 'vpop', nameVi: 'V-Pop', nameEn: 'V-Pop')],
      labelOf: (g) => (g as Genre).nameVi,
      idOf: (g) => (g as Genre).id,
      selected: selected,
      onToggle: (id) => selected.contains(id) ? selected.remove(id) : selected.add(id),
    ))));
    await tester.tap(find.text('V-Pop'));
    await tester.pump();
    expect(selected.contains('vpop'), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/taste_step_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement a reusable chips widget**

Create `lib/features/onboarding/presentation/taste_step.dart`:
```dart
import 'package:flutter/material.dart';

/// Reusable multi-select chip grid for genres / artists / songs (bài tủ).
class TasteChips extends StatefulWidget {
  const TasteChips({
    super.key,
    required this.items,
    required this.labelOf,
    required this.idOf,
    required this.selected,
    required this.onToggle,
  });
  final List<Object> items;
  final String Function(Object) labelOf;
  final String Function(Object) idOf;
  final Set<String> selected;
  final void Function(String id) onToggle;

  @override
  State<TasteChips> createState() => _TasteChipsState();
}

class _TasteChipsState extends State<TasteChips> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        for (final item in widget.items)
          FilterChip(
            label: Text(widget.labelOf(item)),
            selected: widget.selected.contains(widget.idOf(item)),
            onSelected: (_) {
              widget.onToggle(widget.idOf(item));
              setState(() {});
            },
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/taste_step_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/onboarding/presentation/taste_step.dart test/features/onboarding/taste_step_test.dart
git commit -m "feat(p0.3): reusable TasteChips multi-select (genres/artists/bài tủ)"
```

---

### Task 7: Onboarding flow coordinator + wire the route

**Files:**
- Create: `lib/features/onboarding/presentation/onboarding_flow.dart`, `lib/features/onboarding/application/onboarding_controller.dart`
- Modify: `lib/app/router.dart` (replace `_OnboardingPlaceholder` with `OnboardingFlow`)
- Test: `test/features/onboarding/onboarding_controller_test.dart`

- [ ] **Step 1: Write the failing controller test**

Create `test/features/onboarding/onboarding_controller_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/onboarding/application/onboarding_controller.dart';
import 'package:cung_hat/features/onboarding/application/onboarding_providers.dart';
import 'package:cung_hat/features/onboarding/data/onboarding_repository.dart';
import 'package:cung_hat/features/profile/application/profile_providers.dart';
import 'package:cung_hat/features/profile/data/profile_repository.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

class _MockOnb extends Mock implements OnboardingRepository {}
class _MockProf extends Mock implements ProfileRepository {}

void main() {
  test('submit records consents, saves profile, saves taste', () async {
    final onb = _MockOnb();
    final prof = _MockProf();
    when(() => onb.recordConsent(purpose: any(named: 'purpose'), granted: any(named: 'granted'), policyVersion: any(named: 'policyVersion'))).thenAnswer((_) async {});
    when(() => onb.saveTaste(genreIds: any(named: 'genreIds'), artistIds: any(named: 'artistIds'), songIds: any(named: 'songIds'))).thenAnswer((_) async {});
    when(() => prof.upsertMyProfile(any())).thenAnswer((_) async =>
        const Profile(id: 'u1', displayName: 'Mai', ageVerified: true, language: 'vi'));

    final c = ProviderContainer(overrides: [
      onboardingRepositoryProvider.overrideWithValue(onb),
      profileRepositoryProvider.overrideWithValue(prof),
    ]);
    addTearDown(c.dispose);

    final ctrl = c.read(onboardingControllerProvider.notifier);
    await ctrl.submit(
      displayName: 'Mai', fullName: 'Tran Mai', dob: DateTime(2000, 1, 1), bio: 'hi',
      consents: const {'location': true, 'matching': true},
      genreIds: const ['vpop'], artistIds: const ['my_tam'], songIds: const ['s2'],
    );

    verify(() => prof.upsertMyProfile(any())).called(1);
    verify(() => onb.saveTaste(genreIds: ['vpop'], artistIds: ['my_tam'], songIds: ['s2'])).called(1);
    verify(() => onb.recordConsent(purpose: 'location', granted: true, policyVersion: any(named: 'policyVersion'))).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/onboarding_controller_test.dart`
Expected: FAIL — `onboarding_controller.dart` not found.

- [ ] **Step 3: Implement the controller**

Create `lib/features/onboarding/application/onboarding_controller.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/profile.dart';
import 'onboarding_providers.dart';

const kPolicyVersion = 'v1';

class OnboardingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String displayName,
    required String fullName,
    required DateTime dob,
    required String bio,
    required Map<String, bool> consents,
    required List<String> genreIds,
    required List<String> artistIds,
    required List<String> songIds,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final onb = ref.read(onboardingRepositoryProvider);
      for (final e in consents.entries) {
        await onb.recordConsent(purpose: e.key, granted: e.value, policyVersion: kPolicyVersion);
      }
      final iso = '${dob.year.toString().padLeft(4, '0')}-'
          '${dob.month.toString().padLeft(2, '0')}-'
          '${dob.day.toString().padLeft(2, '0')}';
      await ref.read(profileRepositoryProvider).upsertMyProfile(
            Profile(id: '', displayName: displayName, fullName: fullName, dob: iso, bio: bio, language: 'vi'),
          );
      await onb.saveTaste(genreIds: genreIds, artistIds: artistIds, songIds: songIds);
      ref.invalidate(myProfileProvider); // router re-evaluates → leaves onboarding
    });
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);
```

- [ ] **Step 4: Build the flow widget + wire the route**

Create `lib/features/onboarding/presentation/onboarding_flow.dart` — a `ConsumerStatefulWidget` `Stepper` chaining `DobStep` → `ConsentStep` → a name/bio form → `TasteChips` (genres from `genresProvider`, artists from `artistsProvider`, songs from `songsProvider`), with a final "Hoàn tất" button that:
- guards `isAdult(dob)` client-side,
- calls `ref.read(onboardingControllerProvider.notifier).submit(...)`,
- shows a SnackBar on `under_18`/error from the AsyncValue.

In `lib/app/router.dart`: remove `_OnboardingPlaceholder`, import `OnboardingFlow`, and change the `/onboarding` route to `builder: (_, __) => const OnboardingFlow()`.

- [ ] **Step 5: Generate, run controller test + analyze**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" pub run build_runner build --delete-conflicting-outputs
& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/onboarding/onboarding_controller_test.dart
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
```
Expected: controller test PASS; `No issues found!`.

- [ ] **Step 6: Commit**

```
git add lib/features/onboarding/ lib/app/router.dart test/features/onboarding/onboarding_controller_test.dart
git commit -m "feat(p0.3): onboarding flow (DOB→consent→profile→taste) + route wiring"
```

---

### Task 8: l10n + acceptance

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (onboarding strings)

- [ ] **Step 1: Add + generate onboarding strings**

Add keys for: `onbDobTitle`, `onbUnder18`, `onbConsentTitle`, `onbNameLabel`, `onbBioLabel`, `onbTasteGenres`, `onbTasteArtists`, `onbBaitu`, `onbFinish` to both ARBs (VI + EN), then `& "C:\Users\Public\flutter\bin\flutter.bat" gen-l10n` and swap hardcoded strings in the onboarding widgets.

- [ ] **Step 2: Full suite green**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test` then `... analyze`
Expected: all tests green; `No issues found!`.

- [ ] **Step 3: Acceptance — full signup → onboarding → home**

Ensure `supabase start` + `supabase db reset`. Run the app, log in (`900000001`/`123456`), then complete: DOB (≥18) → consent toggles → name/bio → pick genres/artists/bài tủ → Hoàn tất.
Expected: profile row created (`age_verified=true`); router leaves `/onboarding` into the 4-tab shell; verify in Studio that `user_genres`/`user_artists`/`user_baitu`/`consents` rows exist for the user. Try a <18 DOB → blocked client-side and server raises `under_18`.

- [ ] **Step 4: Commit**

```
git add lib/l10n/ lib/features/onboarding/
git commit -m "feat(p0.3): localize onboarding (EN/VI) + acceptance pass"
```

---

## Self-Review (completed by author)

- **Spec coverage:** 18+ DOB gate (server-enforced + client guard) ✓ (T1,T4); granular PDPL consent ✓ (T1,T5,T7); curated taste capture genres/artists/bài tủ ✓ (T2,T6,T7); profile creation ✓ (T7); onboarding→home routing via `myProfileProvider` invalidation ✓ (T7). Gamified <90s flow is realized as a 4-step Stepper (chips); deeper gamification polish (taste-skill UI) deferred to the UI pass.
- **Placeholder scan:** none — every code step is concrete. T7 Step 4 describes the flow widget assembly using already-defined components (`DobStep`, `ConsentStep`, `TasteChips`, `genresProvider/artistsProvider/songsProvider`, `onboardingControllerProvider`); no undefined types.
- **Type consistency:** RPC names `record_consent`/`upsert_my_taste`/`get_my_taste`/`upsert_my_profile` identical across `0004` SQL (T1) and Dart repos (T3); `OnboardingRepository.recordConsent/saveTaste` signatures identical T3↔T7; reuses P0 `Profile`/`profileRepositoryProvider`/`myProfileProvider`; `isAdult(dob,{now})` signature identical T4 test+impl; `TasteChips(items,labelOf,idOf,selected,onToggle)` identical T6 test+impl.

---

## Next plans (when we reach them)
- **P1 Đôi:** PostGIS location capture (`update_my_location`, bucketed) + `user_locations` + matching RPC (`get_discovery_candidates`) + swipe deck (`flutter_card_swiper`) + `record_swipe` race-safe match + match celebration + blocks/reports.
- Then **P2** chat (Broadcast-from-DB), **P3** Kèo board, **P4** venues/plan, **P5** compliance/moderation, **P6** monetization (IAP + MoMo/ZaloPay), **P7** launch (3-city seeding, FCM, store).
