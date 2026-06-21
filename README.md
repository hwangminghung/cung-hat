# Cùng Hát

Flutter + Supabase music-meetup app (Vietnam): match strangers by music taste to sing karaoke together (1-1 swipe + group "Kèo"). Spec & plans: `docs/superpowers/`.

## Dev loop (Windows, this machine)
1. `supabase start` (Docker must be running)
2. Copy `env/dev.example.json` → `env/dev.json`, paste the anon key from `supabase status`
3. `& "C:\Users\Public\flutter\bin\flutter.bat" run -d chrome --dart-define-from-file=env/dev.json`

Codegen after model/ARB changes:
`flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs`

Tests: `flutter test`. Static analysis: `flutter analyze`.
Backend reset: `supabase db reset`. DB (pgTAP) tests: `supabase test db`.

> Windows note: the home path has spaces, so invoke Flutter via the no-space junction `C:\Users\Public\flutter\bin\flutter.bat` for `run`/`build`/`test`.
