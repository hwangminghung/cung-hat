# Integration (acceptance) tests

`app_test.dart` drives the **real app** end-to-end against the **local Supabase** stack
via Flutter's `integration_test` (WidgetTester drives the actual widget tree, so the
web canvas renderer is irrelevant — unlike DOM browser automation).

**Test 1 (must pass):** boot → phone/auth screen → enter `900000001` → send OTP →
enter `123456` → verify → asserts redirect to the onboarding DOB step. This exercises
real GoTrue OTP auth + go_router redirect against live local Supabase.

**Test 2 (skipped):** onboarding DOB picker — `showDatePicker` is brittle under
WidgetTester; wire it when revisiting.

## Prerequisites
1. Local Supabase running with a CLEAN db (so the test user has no profile → deterministic onboarding redirect):
   ```powershell
   $env:SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN='localdummytoken'
   supabase db reset
   ```
2. A device/target (see below). The host's `127.0.0.1` is the default Supabase URL;
   override per target with `--dart-define`.

## Run on an Android emulator (recommended — exercises everything faithfully)
From an emulator the host is reachable as `10.0.2.2`:
```powershell
& "C:\Users\Public\flutter\bin\flutter.bat" test integration_test/app_test.dart `
  -d <emulator-id> `
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 `
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
```
(`flutter emulators` to list; `flutter emulators --launch <id>` to start one.)

## Run on web (Chrome) — needs chromedriver + flutter drive
`flutter test ... -d chrome` is NOT supported for integration tests. Use a driver:
1. Install chromedriver matching your Chrome version (Chrome for Testing), run it: `chromedriver --port=4444`.
2. Create `test_driver/integration_test.dart` with the standard
   `integrationDriver()` body, then:
   ```powershell
   & "C:\Users\Public\flutter\bin\flutter.bat" drive `
     --driver=test_driver/integration_test.dart `
     --target=integration_test/app_test.dart -d chrome `
     --dart-define=SUPABASE_URL=http://127.0.0.1:54321 `
     --dart-define=SUPABASE_ANON_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
   ```

## Run on Windows desktop
Requires the Visual Studio "Desktop development with C++" workload and a scaffolded
`windows/` folder (`flutter create --platforms=windows .`). Note `firebase_messaging`
has no Windows implementation; the guarded init in `main.dart` skips it.
