# Cùng Hát — P0 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a runnable Flutter + Supabase skeleton for "Cùng Hát" that establishes every reusable pattern — migration discipline, RLS, the hardened `SECURITY DEFINER` RPC contract, repository → Riverpod provider → UI layering, freezed models, the test harness, EN/VI l10n, a 4-tab app shell, and CI — proven end-to-end through a minimal `profiles` read/write slice.

**Architecture:** Feature-first Flutter (Riverpod 3 DI, go_router, freezed, Material 3) talks to Supabase (Postgres + PostGIS, local-first via the Supabase CLI). All cross-user reads will go through `SECURITY DEFINER` RPCs in a private schema; P0 proves the pattern with self-scoped `get_my_profile` / `upsert_my_profile`. Secrets never leave Edge Functions / `--dart-define` files.

**Tech Stack:** Flutter (Dart 3), Riverpod 3, go_router, freezed + json_serializable, supabase_flutter, intl/flutter_localizations, mocktail (tests); Supabase CLI + Docker (local Postgres/PostGIS); GitHub Actions CI.

---

## Pre-requisites (read once, do not skip)

This machine has **spaces in the home path** (`C:\Users\Hwang Ming Hung`), which breaks Flutter/Android native tooling. Workarounds already on the machine:

- **Invoke Flutter via the no-space junction:** `& "C:\Users\Public\flutter\bin\flutter.bat"` for `run`/`build`/`test`. Plain `flutter` is OK for `analyze`/`gen-l10n`/`pub`.
- **Docker Desktop must be running** for `supabase start` (start `com.docker.service` as Administrator if the engine is stopped).
- **Supabase CLI** via scoop; if `supabase` isn't found in the tool shell, refresh PATH at the top of the PowerShell call:
  `$env:Path=[Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User')`
- Project root for all paths below: `C:\Users\Hwang Ming Hung\cung-hat` (already a git repo).
- **Migration rule (permanent):** never edit an applied migration — always add a new dated file. After any migration, run `supabase db reset` and verify clean.

---

### Task 1: Scaffold the Flutter app into the existing repo

**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`, `analysis_options.yaml`, platform folders (`android/`, `ios/`, `web/`), and the feature-first skeleton dirs.

- [ ] **Step 1: Create the Flutter project in-place**

Run (from repo root, the dir already contains `docs/` + `.git`):
```
& "C:\Users\Public\flutter\bin\flutter.bat" create --org dev.cunghat --project-name cung_hat --platforms=android,ios,web .
```
Expected: project files generated; existing `docs/` and `.git` untouched.

- [ ] **Step 2: Create the feature-first skeleton**

Run:
```
mkdir lib/app lib/core/config lib/core/providers lib/l10n lib/features
```
These hold: `app/` (router, theme, shell), `core/config` (env), `core/providers` (shared Riverpod), `l10n/` (ARB), `features/<feature>/{domain,data,application,presentation}`.

- [ ] **Step 3: Strict analysis options**

Replace `analysis_options.yaml`:
```yaml
include: package:flutter_lints/flutter.yaml
analyzer:
  errors:
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
linter:
  rules:
    prefer_const_constructors: true
    require_trailing_commas: true
```

- [ ] **Step 4: Verify it builds and analyzes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```
git add -A
git commit -m "chore(p0): scaffold Flutter app + feature-first skeleton"
```

---

### Task 2: Add dependencies

**Files:**
- Modify: `pubspec.yaml` (via `pub add`)

- [ ] **Step 1: Add runtime + dev dependencies**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" pub add flutter_riverpod go_router supabase_flutter freezed_annotation json_annotation intl
& "C:\Users\Public\flutter\bin\flutter.bat" pub add flutter_localizations --sdk=flutter
& "C:\Users\Public\flutter\bin\flutter.bat" pub add dev:build_runner dev:freezed dev:json_serializable dev:mocktail
```

- [ ] **Step 2: Enable l10n generation**

Create `l10n.yaml` at repo root:
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```
Add to `pubspec.yaml` under `flutter:`: `generate: true`.

- [ ] **Step 3: Verify resolution**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" pub get`
Expected: `Got dependencies!` with no version conflicts.

- [ ] **Step 4: Commit**

```
git add pubspec.yaml pubspec.lock l10n.yaml
git commit -m "chore(p0): add riverpod/go_router/supabase/freezed/intl/mocktail deps"
```

---

### Task 3: App config + environment wiring

**Files:**
- Create: `lib/core/config/app_config.dart`, `env/dev.example.json`
- Modify: `.gitignore`

- [ ] **Step 1: Write the failing test**

Create `test/core/app_config_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/core/config/app_config.dart';

void main() {
  test('AppConfig reads supabase values from dart-define', () {
    const cfg = AppConfig(supabaseUrl: 'https://x.supabase.co', supabaseAnonKey: 'k');
    expect(cfg.supabaseUrl, 'https://x.supabase.co');
    expect(cfg.supabaseAnonKey, 'k');
    expect(cfg.isConfigured, isTrue);
  });

  test('AppConfig.isConfigured is false when empty', () {
    const cfg = AppConfig(supabaseUrl: '', supabaseAnonKey: '');
    expect(cfg.isConfigured, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/core/app_config_test.dart`
Expected: FAIL — `app_config.dart` not found.

- [ ] **Step 3: Implement AppConfig**

Create `lib/core/config/app_config.dart`:
```dart
class AppConfig {
  const AppConfig({required this.supabaseUrl, required this.supabaseAnonKey});

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  factory AppConfig.fromEnv() => const AppConfig(
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/core/app_config_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Add env template + gitignore, then commit**

Create `env/dev.example.json`:
```json
{
  "SUPABASE_URL": "http://127.0.0.1:54321",
  "SUPABASE_ANON_KEY": "<local anon key from `supabase status`>"
}
```
Append to `.gitignore`: `env/*.json` and `!env/dev.example.json`.
```
git add lib/core/config/app_config.dart test/core/app_config_test.dart env/dev.example.json .gitignore
git commit -m "feat(p0): AppConfig from dart-define + env template"
```

---

### Task 4: Initialise Supabase + first migration (extensions, profiles, RLS)

**Files:**
- Create: `supabase/config.toml` (via `supabase init`), `supabase/migrations/0001_foundation.sql`

- [ ] **Step 1: Init + start the local stack**

Run:
```
supabase init
supabase start
```
Expected: prints local API URL `http://127.0.0.1:54321`, anon key, service_role key, Studio `:54323`. Copy the anon key into `env/dev.json` (create from `env/dev.example.json`).

- [ ] **Step 2: Write the foundation migration**

Create `supabase/migrations/0001_foundation.sql`:
```sql
-- Extensions
create extension if not exists postgis;
create extension if not exists pgcrypto;

-- updated_at trigger helper
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

-- profiles: core identity, self-scoped
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) <= 50),
  full_name    text check (char_length(full_name) <= 100),
  dob          date,
  age_verified boolean not null default false,
  bio          text check (char_length(bio) <= 500),
  language     text not null default 'vi',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

-- Self can read/insert/update OWN row only. No cross-user access here;
-- cross-user reads will go through SECURITY DEFINER RPCs (see 0002).
create policy profiles_select_self on public.profiles
  for select using (auth.uid() = id);
create policy profiles_insert_self on public.profiles
  for insert with check (auth.uid() = id);
create policy profiles_update_self on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
```

- [ ] **Step 3: Apply + verify clean**

Run: `supabase db reset`
Expected: applies `0001_foundation.sql` with no errors; `profiles` table + RLS present (check in Studio `:54323`).

- [ ] **Step 4: Commit**

```
git add supabase/config.toml supabase/migrations/0001_foundation.sql
git commit -m "feat(p0): supabase init + 0001 foundation (postgis, profiles, RLS)"
```

---

### Task 5: The hardened SECURITY DEFINER RPC pattern (migration 0002)

**Files:**
- Create: `supabase/migrations/0002_profile_rpcs.sql`
- Test: `supabase/tests/profile_rpcs_test.sql`

- [ ] **Step 1: Write the migration establishing the canonical RPC contract**

Create `supabase/migrations/0002_profile_rpcs.sql`:
```sql
-- Private schema NOT exposed by PostgREST; all definer logic lives here.
create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;

-- Sanitized return type = the privacy boundary (never SELECT * of base tables).
create type public.my_profile as (
  id uuid, display_name text, full_name text, dob date,
  age_verified boolean, bio text, language text
);

create or replace function public.get_my_profile()
returns public.my_profile
language sql security definer set search_path = ''
as $$
  select p.id, p.display_name, p.full_name, p.dob, p.age_verified, p.bio, p.language
  from public.profiles p
  where p.id = auth.uid();
$$;

create or replace function public.upsert_my_profile(
  p_display_name text, p_full_name text, p_dob date, p_bio text, p_language text
) returns public.my_profile
language plpgsql security definer set search_path = ''
as $$
declare result public.my_profile;
begin
  insert into public.profiles (id, display_name, full_name, dob, bio, language)
  values (auth.uid(), p_display_name, p_full_name, p_dob, p_bio, coalesce(p_language, 'vi'))
  on conflict (id) do update
    set display_name = excluded.display_name,
        full_name    = excluded.full_name,
        dob          = excluded.dob,
        bio          = excluded.bio,
        language     = excluded.language;
  select p.id, p.display_name, p.full_name, p.dob, p.age_verified, p.bio, p.language
    into result from public.profiles p where p.id = auth.uid();
  return result;
end; $$;

-- Lock execution: deny anon/public, allow only logged-in users.
revoke execute on function public.get_my_profile() from public, anon;
revoke execute on function public.upsert_my_profile(text,text,date,text,text) from public, anon;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.upsert_my_profile(text,text,date,text,text) to authenticated;
```

- [ ] **Step 2: Write a SQL smoke test asserting anon is denied**

Create `supabase/tests/profile_rpcs_test.sql`:
```sql
-- Run with: supabase test db
begin;
select plan(2);
-- anon must NOT be able to execute the RPC
set local role anon;
select throws_ok($$ select public.get_my_profile() $$, '42501');
-- the sanitized type must not leak base columns like created_at
select hasnt_column('public', 'my_profile'::regtype::text, 'created_at',
  'my_profile sanitized type omits created_at');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + run the DB test**

Run: `supabase db reset` then `supabase test db`
Expected: migration applies; both assertions pass (anon denied; sanitized type has no `created_at`).

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0002_profile_rpcs.sql supabase/tests/profile_rpcs_test.sql
git commit -m "feat(p0): hardened SECURITY DEFINER RPC pattern (get/upsert my profile)"
```

---

### Task 6: Seed music genre reference data (migration 0003)

**Files:**
- Create: `supabase/migrations/0003_music_ref.sql`

- [ ] **Step 1: Write the reference-table migration with seed**

Create `supabase/migrations/0003_music_ref.sql`:
```sql
create table public.music_genres (
  id text primary key,
  name_vi text not null,
  name_en text not null,
  sort int not null default 0
);
alter table public.music_genres enable row level security;
create policy music_genres_read on public.music_genres for select using (true);

insert into public.music_genres (id, name_vi, name_en, sort) values
  ('vpop','V-Pop','V-Pop',1),
  ('ballad','Ballad','Ballad',2),
  ('bolero','Bolero','Bolero',3),
  ('rap_vn','Rap Việt','Vietnamese Rap',4),
  ('kpop','K-Pop','K-Pop',5),
  ('us_uk','US-UK','US-UK',6),
  ('rock','Rock','Rock',7),
  ('indie','Indie','Indie',8);
```

- [ ] **Step 2: Apply + verify rows**

Run: `supabase db reset`
Expected: `music_genres` has 8 rows (verify in Studio).

- [ ] **Step 3: Commit**

```
git add supabase/migrations/0003_music_ref.sql
git commit -m "feat(p0): music_genres reference table + seed (public read)"
```

---

### Task 7: Initialise Supabase client + Riverpod scope in main

**Files:**
- Create: `lib/core/providers/supabase_providers.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write the supabase client provider**

Create `lib/core/providers/supabase_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Overridden in main() after Supabase.initialize(); never read before that.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  throw UnimplementedError('supabaseClientProvider must be overridden in main()');
});
```

- [ ] **Step 2: Wire main()**

Replace `lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/providers/supabase_providers.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cfg = AppConfig.fromEnv();
  await Supabase.initialize(url: cfg.supabaseUrl, anonKey: cfg.supabaseAnonKey);
  runApp(
    ProviderScope(
      overrides: [supabaseClientProvider.overrideWithValue(Supabase.instance.client)],
      child: const CungHatApp(),
    ),
  );
}
```

- [ ] **Step 3: Verify analyze (app.dart created in Task 9; expect a missing-import error until then)**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" analyze lib/core lib/main.dart`
Expected: only the `app/app.dart` URI error (resolved in Task 9). No other issues.

- [ ] **Step 4: Commit**

```
git add lib/core/providers/supabase_providers.dart lib/main.dart
git commit -m "feat(p0): Supabase.initialize + ProviderScope override in main"
```

---

### Task 8: Profile freezed model

**Files:**
- Create: `lib/features/profile/domain/profile.dart`
- Test: `test/features/profile/profile_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/profile/profile_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/profile/domain/profile.dart';

void main() {
  test('Profile.fromJson maps the sanitized RPC shape', () {
    final p = Profile.fromJson({
      'id': 'u1', 'display_name': 'Mai', 'full_name': 'Tran Mai',
      'dob': '2000-01-01', 'age_verified': true, 'bio': 'hi', 'language': 'vi',
    });
    expect(p.id, 'u1');
    expect(p.displayName, 'Mai');
    expect(p.ageVerified, isTrue);
  });

  test('Profile equality is value-based (freezed)', () {
    const a = Profile(id: 'u1', ageVerified: false, language: 'vi');
    const b = Profile(id: 'u1', ageVerified: false, language: 'vi');
    expect(a, b);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/profile/profile_test.dart`
Expected: FAIL — `profile.dart` not found.

- [ ] **Step 3: Implement the freezed model**

Create `lib/features/profile/domain/profile.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'full_name') String? fullName,
    String? dob,
    @JsonKey(name: 'age_verified') @Default(false) bool ageVerified,
    String? bio,
    @Default('vi') String language,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
```

- [ ] **Step 4: Generate code + run test**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" pub run build_runner build --delete-conflicting-outputs
& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/profile/profile_test.dart
```
Expected: codegen creates `profile.freezed.dart` + `profile.g.dart`; both tests PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/profile/domain/ test/features/profile/profile_test.dart
git commit -m "feat(p0): Profile freezed model (sanitized RPC shape)"
```

---

### Task 9: App shell — go_router + 4-tab bottom nav

**Files:**
- Create: `lib/app/app.dart`, `lib/app/router.dart`, `lib/app/home_shell.dart`
- Test: `test/app/home_shell_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/app/home_shell_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/app/home_shell.dart';

void main() {
  testWidgets('HomeShell shows 4 tabs and switches', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    expect(find.text('Đôi'), findsOneWidget);
    expect(find.text('Kèo'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
    await tester.tap(find.text('Kèo'));
    await tester.pumpAndSettle();
    expect(find.text('Kèo — sắp có'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/app/home_shell_test.dart`
Expected: FAIL — `home_shell.dart` not found.

- [ ] **Step 3: Implement shell, router, app**

Create `lib/app/home_shell.dart`:
```dart
import 'package:flutter/material.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  static const _labels = ['Đôi', 'Kèo', 'Chat', 'Hồ sơ'];
  static const _icons = [Icons.favorite, Icons.groups, Icons.chat_bubble, Icons.person];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('${_labels[_index]} — sắp có')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(icon: Icon(_icons[i]), label: _labels[i]),
        ],
      ),
    );
  }
}
```

Create `lib/app/router.dart`:
```dart
import 'package:go_router/go_router.dart';
import 'home_shell.dart';

final appRouter = GoRouter(
  routes: [GoRoute(path: '/', builder: (_, __) => const HomeShell())],
);
```

Create `lib/app/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'router.dart';

class CungHatApp extends StatelessWidget {
  const CungHatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cùng Hát',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6750A4), useMaterial3: true),
      routerConfig: appRouter,
    );
  }
}
```

- [ ] **Step 4: Run test + analyze**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" test test/app/home_shell_test.dart
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
```
Expected: widget test PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```
git add lib/app/ test/app/home_shell_test.dart
git commit -m "feat(p0): app shell with go_router + 4-tab nav (Đôi/Kèo/Chat/Hồ sơ)"
```

---

### Task 10: ProfileRepository + provider (proves the RPC round-trip pattern)

**Files:**
- Create: `lib/features/profile/data/profile_repository.dart`, `lib/features/profile/application/profile_providers.dart`
- Test: `test/features/profile/profile_repository_test.dart`

- [ ] **Step 1: Write the failing contract test (mocktail)**

Create `test/features/profile/profile_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/profile/data/profile_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  test('getMyProfile calls the get_my_profile RPC and maps result', () async {
    final client = _MockClient();
    when(() => client.rpc('get_my_profile')).thenAnswer((_) async => {
          'id': 'u1', 'display_name': 'Mai', 'age_verified': true, 'language': 'vi',
        });
    final repo = ProfileRepository(client);
    final p = await repo.getMyProfile();
    expect(p!.displayName, 'Mai');
    verify(() => client.rpc('get_my_profile')).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/profile/profile_repository_test.dart`
Expected: FAIL — `profile_repository.dart` not found.

- [ ] **Step 3: Implement repository + provider**

Create `lib/features/profile/data/profile_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<Profile?> getMyProfile() async {
    final res = await _client.rpc('get_my_profile');
    if (res == null) return null;
    final map = res is List ? (res.isEmpty ? null : res.first) : res;
    return map == null ? null : Profile.fromJson(Map<String, dynamic>.from(map));
  }

  Future<Profile> upsertMyProfile(Profile p) async {
    final res = await _client.rpc('upsert_my_profile', params: {
      'p_display_name': p.displayName,
      'p_full_name': p.fullName,
      'p_dob': p.dob,
      'p_bio': p.bio,
      'p_language': p.language,
    });
    final map = res is List ? res.first : res;
    return Profile.fromJson(Map<String, dynamic>.from(map));
  }
}
```

Create `lib/features/profile/application/profile_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

final myProfileProvider = FutureProvider<Profile?>(
  (ref) => ref.watch(profileRepositoryProvider).getMyProfile(),
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/profile/profile_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/profile/data/ lib/features/profile/application/ test/features/profile/profile_repository_test.dart
git commit -m "feat(p0): ProfileRepository + providers (RPC round-trip pattern)"
```

---

### Task 11: l10n EN/VI scaffolding

**Files:**
- Create: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify: `lib/app/app.dart`
- Test: `test/l10n/l10n_test.dart`

- [ ] **Step 1: Create ARB files**

`lib/l10n/app_en.arb`:
```json
{ "@@locale": "en", "appTitle": "Cùng Hát", "tabDoi": "Đôi", "tabKeo": "Kèo", "comingSoon": "Coming soon" }
```
`lib/l10n/app_vi.arb`:
```json
{ "@@locale": "vi", "appTitle": "Cùng Hát", "tabDoi": "Đôi", "tabKeo": "Kèo", "comingSoon": "Sắp có" }
```

- [ ] **Step 2: Generate localizations**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" gen-l10n`
Expected: generates `app_localizations.dart` (+ `_en`/`_vi`) under `.dart_tool/flutter_gen` / configured output.

- [ ] **Step 3: Wire localization delegates in app.dart**

Modify `lib/app/app.dart` `MaterialApp.router(...)` to add:
```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// inside MaterialApp.router:
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
```

- [ ] **Step 4: Write + run a localization test**

Create `test/l10n/l10n_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('VI locale resolves comingSoon to "Sắp có"', () async {
    final l = await AppLocalizations.delegate.load(const Locale('vi'));
    expect(l.comingSoon, 'Sắp có');
  });
}
```
Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/l10n/l10n_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
git add lib/l10n/ lib/app/app.dart test/l10n/l10n_test.dart
git commit -m "feat(p0): EN/VI l10n scaffolding (VI default)"
```

---

### Task 12: CI — analyze + test on push

**Files:**
- Create: `.github/workflows/ci.yml`
- Modify: `README.md`

- [ ] **Step 1: Write the CI workflow**

Create `.github/workflows/ci.yml`:
```yaml
name: CI
on: [push, pull_request]
jobs:
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter gen-l10n
      - run: flutter analyze
      - run: flutter test
```

- [ ] **Step 2: Write README run instructions**

Create/replace `README.md` with the local dev loop:
```markdown
# Cùng Hát
Flutter + Supabase music-meetup app (VN). Spec: docs/superpowers/specs/.

## Dev loop (Windows, this machine)
1. `supabase start` (Docker running)
2. Copy `env/dev.example.json` → `env/dev.json`, paste the anon key from `supabase status`
3. `& "C:\Users\Public\flutter\bin\flutter.bat" run -d chrome --dart-define-from-file=env/dev.json`

Codegen after model/ARB changes: `flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs`.
Tests: `flutter test`. Backend reset: `supabase db reset`; DB tests: `supabase test db`.
```

- [ ] **Step 3: Run the full local suite (CI parity)**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
& "C:\Users\Public\flutter\bin\flutter.bat" test
```
Expected: `No issues found!` and all tests green.

- [ ] **Step 4: Commit**

```
git add .github/workflows/ci.yml README.md
git commit -m "ci(p0): analyze+test workflow + README dev loop"
```

---

### Task 13: P0 acceptance — run the app end-to-end

**Files:** none (verification only)

- [ ] **Step 1: Launch on web against local Supabase**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" run -d chrome --dart-define-from-file=env/dev.json`
Expected: app boots to the 4-tab shell; tapping tabs switches the placeholder; no console errors about Supabase init.

- [ ] **Step 2: Confirm full suite green + clean tree**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
& "C:\Users\Public\flutter\bin\flutter.bat" test
git status
```
Expected: `No issues found!`, all tests pass, working tree clean.

- [ ] **Step 3: Tag the foundation**

```
git tag p0-foundation
```

---

## Self-Review (completed by author)

- **Spec coverage (P0 slice):** scaffold ✓ (T1), deps ✓ (T2), config/env ✓ (T3), Supabase + PostGIS + profiles + RLS ✓ (T4), hardened SECURITY DEFINER RPC pattern + anon-deny test ✓ (T5), reference seed ✓ (T6), client init ✓ (T7), freezed model ✓ (T8), 4-tab shell ✓ (T9), repository→provider pattern ✓ (T10), EN/VI l10n ✓ (T11), CI ✓ (T12), acceptance ✓ (T13). Auth/consent/taste-picker, Đôi, Kèo, chat, venues, safety, monetization, moderation are **out of P0** and covered by later plans (see spec §17 P0.2–P7).
- **Placeholder scan:** none — every step has concrete code/SQL/commands.
- **Type consistency:** `Profile`/`Profile.fromJson` (T8) reused in T10; `supabaseClientProvider` (T7) consumed in T10; RPC names `get_my_profile`/`upsert_my_profile` identical across T5 (SQL) and T10 (Dart); sanitized `my_profile` shape matches `Profile` fields.

---

## Next plans (to be written when we reach them)
- **P0.2** Auth: phone OTP (+84) via Send-SMS Auth Hook + 18+ DOB gate.
- **P0.3** Onboarding consent (granular PDPL) + gamified music-taste picker (genres/artists/bài tủ from curated list).
- **P1** Đôi: PostGIS matching RPCs + swipe deck + race-safe match + celebration + blocks/reports.
- **P2** Chat (Broadcast-from-DB), **P3** Kèo board, **P4** meet-up/venues, **P5** compliance/moderation, **P6** monetization (IAP + MoMo/ZaloPay), **P7** launch (3-city seeding, FCM, store).
