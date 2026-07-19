# Cùng Hát presentation redesign validation

## Outcome

The 22 approved presentation states passed deterministic Android capture and
manual visual inspection. The evidence directory contains exactly 22 non-empty
PNG files, each `1080 × 2340`, with basenames matching the approved capture
matrix. Every image contains its expected `screen_XX_*` production state and no
capture reported a Flutter exception.

The capture fixtures use only provider overrides and in-memory repository
implementations. They do not construct a production repository, Supabase
client, HTTP client, or RPC call.

## Mockup-to-capture comparison

| # | Mockup | Android capture | Result | Intentional difference |
|---:|---|---|---|---|
| 01 | `docs/redesign-mockups/01-login.png` | `after/01-login.png` | Pass | The capture keeps the production CH/music-box fallback illustration and an empty phone field instead of the mockup's remote-photo treatment and sample number. |
| 02 | `docs/redesign-mockups/02-otp.png` | `after/02-otp.png` | Pass | OTP cells remain empty and focused for safe initial-state validation; the in-memory auth fixture exposes `+84900000001` rather than the mockup's populated sample code and phone. |
| 03 | `docs/redesign-mockups/03-onboarding-dob.png` | `after/03-onboarding-dob.png` | Pass | The production first-entry state has no invented birth date and uses the shipped icon/card composition instead of the reference illustration. |
| 04 | `docs/redesign-mockups/04-onboarding-consent.png` | `after/04-onboarding-consent.png` | Pass | The production consent cards and preserved CTA callback are captured before consent is granted; no policy or consent data was fabricated. |
| 05 | `docs/redesign-mockups/05-onboarding-profile.png` | `after/05-onboarding-profile.png` | Pass | The capture validates the safe blank form and monogram fallback rather than the mockup's seeded name, biography, and portrait. |
| 06 | `docs/redesign-mockups/06-onboarding-music-taste.png` | `after/06-onboarding-music-taste.png` | Pass | The in-memory reference catalog is intentionally limited to V-Pop, Mỹ Tâm, and two songs; selections begin empty instead of copying the mockup's broader sample catalog. |
| 07 | `docs/redesign-mockups/07-doi-deck.png` | `after/07-doi-deck.png` | Pass | No remote profile media is requested, so the production monogram fallback is shown. The standalone production screen retains its current filter, music, boost, refresh, pass, and like controls without an invented app shell. |
| 08 | `docs/redesign-mockups/08-doi-profile-detail.png` | `after/08-doi-profile-detail.png` | Pass | The production detail sheet is pumped directly, as required. It uses a monogram and the two safe fixture songs instead of the mockup photo/quote payload. |
| 09 | `docs/redesign-mockups/09-match-celebration.png` | `after/09-match-celebration.png` | Pass | Deterministic Minh/Linh monograms and one existing shared song replace remote photos and the mockup's additional sample song. |
| 10 | `docs/redesign-mockups/10-explore-themes.png` | `after/10-explore-themes.png` | Pass | The capture uses the production emoji motifs and a uniform provider-derived count of 12 per theme, not the reference's decorative art and illustrative counts. |
| 11 | `docs/redesign-mockups/11-keo-board.png` | `after/11-keo-board.png` | Pass | One real fixture kèo and the auto-match promotion are shown; the mockup's extra sample kèo and bottom shell are not invented. Displayed times are derived from the UTC fixture in the device time zone. |
| 12 | `docs/redesign-mockups/12-keo-auto-match.png` | `after/12-keo-auto-match.png` | Pass | The production sheet is pumped directly. Existing reason values (`same_genre`, `nearby`) remain data-safe rather than being replaced by mock localization data. |
| 13 | `docs/redesign-mockups/13-create-keo.png` | `after/13-create-keo.png` | Pass | The production initial viewport is captured with a blank form and the available V-Pop reference option, not the reference's prefilled kèo. |
| 14 | `docs/redesign-mockups/14-keo-detail.png` | `after/14-keo-detail.png` | Pass | The deterministic roster is intentionally empty and the viewer sees the production join CTA; host, confirmed, and pending members from the mockup are not fabricated. |
| 15 | `docs/redesign-mockups/15-inbox.png` | `after/15-inbox.png` | Pass | Only one group and one pair thread exist in the fixture. Production monogram/ticket fallbacks replace remote avatars and the mockup's extra conversations. |
| 16 | `docs/redesign-mockups/16-chat-1to1.png` | `after/16-chat-1to1.png` | Pass | Empty in-memory history and live streams validate the production empty conversation state instead of inventing message content. |
| 17 | `docs/redesign-mockups/17-keo-group-chat.png` | `after/17-keo-group-chat.png` | Pass | Empty in-memory group history validates the production empty state and safety rules instead of the mockup's sample messages. |
| 18 | `docs/redesign-mockups/18-profile.png` | `after/18-profile.png` | Pass | The safe fixture yields a monogram and a data-derived 60% completion value rather than the mockup photo and 75%; current production upsell, photo, prompt, and settings cards remain visible. |
| 19 | `docs/redesign-mockups/19-plan-map.png` | `after/19-plan.png` | Pass | Native maps are disabled for deterministic capture. The production placeholder map, one safe venue, and the fixture's confirmed plan replace map tiles and additional candidate venues. |
| 20 | `docs/redesign-mockups/20-booking-payment.png` | `after/20-booking-payment.png` | Pass | The reference image depicts the confirmed-plan handoff, while the required production anchor is the booking-payment sheet. The capture opens that private sheet through the real `BookingButton`; no booking response or gateway result is invented. |
| 21 | `docs/redesign-mockups/21-store.png` | `after/21-store.png` | Pass | Product rows and `199k/49k/99k/79k` prices come from the in-memory store catalog; no store network or decorative remote asset is used. |
| 22 | `docs/redesign-mockups/22-settings.png` | `after/22-settings.png` | Pass | The capture preserves the current production consent, language, data, account, and legal hierarchy. Marketing remains false in the safe fixture instead of copying the mockup's all-on switches. |

Visual notes: states 04 and 06 place their bottom CTA close to the side edges at
the emulator size, and states 12 and 15 expose dark safe-area/background bands.
The controls and copy remain legible, the expected roots are present, and the
capture run reports no overflow or Flutter exception. These are recorded as
review notes rather than data or boundary changes.

## Android evidence

| Command | Outcome |
|---|---|
| `adb -s emulator-5554 shell getprop sys.boot_completed` | Pass — returned `1`. |
| `flutter build apk --debug` | Pass — built `build\app\outputs\flutter-apk\app-debug.apk`. |
| `flutter test integration_test/presentation_capture_test.dart -d emulator-5554 --plain-name "captures 01-login from its production screen root" --reporter expanded` | TDD red first: the intentionally blank fixture found zero `screen_01_login` roots; green after implementation: one test passed. |
| `flutter test integration_test/presentation_capture_test.dart -d emulator-5554 --name "captures 0[12]-" --reporter expanded` | Pass — two tests crossed an integration-test teardown boundary successfully. |
| `flutter drive --driver=test_driver/presentation_capture_driver.dart --target=integration_test/presentation_capture_test.dart -d emulator-5554` | Pass — `+23`, all tests passed; 22 named screenshot tests plus driver teardown. |

Flutter 3.44 reverts `convertFlutterSurfaceToImage()` during each test teardown.
The brief's process-local conversion flag was therefore reset with an
`addTearDown` callback as well. This is the minimum compatibility adjustment
needed to capture more than the first test and is covered by the two-test
boundary regression command above.

## Mobile web evidence

`flutter build web` passed. The current application entry point requires
Supabase compile-time defines:

- Exact `flutter run -d chrome --web-port 7357`: reached `main.dart`, then
  intentionally asserted because `SUPABASE_URL`/`SUPABASE_ANON_KEY` were absent.
- Validation retry:
  `flutter run -d chrome --web-port 7357 --dart-define-from-file=env/dev.emulator.json`
  started successfully with the repository's existing local-emulator
  configuration. No source, fixture, or environment file was changed.

Connected Chrome measurements:

| Viewport | `innerWidth` | document/body scroll width | Flutter root bounds | Result |
|---|---:|---:|---|---|
| `360 × 800` | 360 | 360 | left 0, right 360, width 360 | Pass |
| `393 × 852` | 393 | 393 | left 0, right 393, width 393 | Pass |
| `430 × 932` | 430 | 430 | left 0, right 430, width 430 | Pass |

At every width the login surface was centered and visually legible with no
horizontal scrollbar. At 360px a pointer click focused an actual `INPUT`;
keyboard entry produced `900000001`, and the document scroll width remained
360px. Browser logs contained no application error, only Flutter's notice that
it replaces the existing viewport meta tag.

## Widget-test, iOS, and analyzer evidence

- `flutter test --reporter compact`: pass — 955 tests.
- The test suite includes the presentation matrix for 360/393/430dp, text
  scales 1.0/1.2/1.4, reduced motion, keyboard insets, and
  `TargetPlatform.iOS` cases.
- iOS was validated through `TargetPlatform.iOS` widget tests only. No iOS
  Simulator or iOS build was run or claimed from Windows.
- `flutter analyze integration_test/presentation_capture_test.dart test_driver/presentation_capture_driver.dart`:
  pass — no issues.
- The exact workspace `flutter analyze` command is polluted by the user's
  ignored `build/claude-design/...` snapshot (214 issues, all inside that
  snapshot). The snapshot was preserved. The exact `flutter analyze` command
  passed with no issues in a clean detached worktree pinned to the final
  evidence commit.

## Boundary audit

The evidence harness imports repository interfaces only to supply in-memory
implementations and provider overrides. It performs no external backend,
network, or RPC operation. The required forbidden-path audit reports
`Frontend-only boundary clean.` No file under `supabase/`, feature
`data/domain/application`, `lib/app/router.dart`, `lib/core/providers/`, or
`lib/core/analytics/` is changed by Task 17.
