# Cùng Hát presentation redesign validation

## Outcome

Twenty-one approved presentation states passed deterministic Android capture,
manual image inspection, and a live Chrome gallery audit at 360, 393, and
430dp. State 19 is **Pass with follow-up**: its share CTA wraps to three lines
at 360dp but remains reachable and overflow-free. The evidence directory
contains exactly 22 non-empty `1080 × 2340` PNGs with the approved basenames
and expected `screen_XX_*` production roots.

The first captures of states 12, 15, and 18 exposed the unpainted engine surface
because their transparent roots were mounted without the `Scaffold` supplied
by their production-equivalent host. Their fixtures now use the same light
`Scaffold` relationship as the focused tests or `HomeShell`. The three
refreshed PNGs each contain zero exact-black and zero near-black pixels.

All fixture data comes from provider overrides and in-memory interface
implementations. The harness and gallery do not initialize the production
router, Supabase, HTTP, or an RPC.

## Mockup-to-capture comparison

| # | Mockup | Android capture | Result | Intentional difference |
|---:|---|---|---|---|
| 01 | `docs/redesign-mockups/01-login.png` | `after/01-login.png` | Pass | Uses the production CH/music-box fallback and an empty phone field; no remote photo or sample number. |
| 02 | `docs/redesign-mockups/02-otp.png` | `after/02-otp.png` | Pass | OTP cells remain empty; the in-memory auth state safely exposes `+84900000001`. |
| 03 | `docs/redesign-mockups/03-onboarding-dob.png` | `after/03-onboarding-dob.png` | Pass | The real first-entry state has no invented birth date. |
| 04 | `docs/redesign-mockups/04-onboarding-consent.png` | `after/04-onboarding-consent.png` | Pass | Captured before consent is granted; no policy data is fabricated. |
| 05 | `docs/redesign-mockups/05-onboarding-profile.png` | `after/05-onboarding-profile.png` | Pass | Validates the safe blank form and monogram fallback. |
| 06 | `docs/redesign-mockups/06-onboarding-music-taste.png` | `after/06-onboarding-music-taste.png` | Pass | Uses a deterministic catalog of V-Pop, Mỹ Tâm, and two songs; selections begin empty. |
| 07 | `docs/redesign-mockups/07-doi-deck.png` | `after/07-doi-deck.png` | Pass | Uses the production monogram fallback and standalone screen controls without an invented shell. |
| 08 | `docs/redesign-mockups/08-doi-profile-detail.png` | `after/08-doi-profile-detail.png` | Pass | Uses a monogram and two safe fixture songs instead of remote media. |
| 09 | `docs/redesign-mockups/09-match-celebration.png` | `after/09-match-celebration.png` | Pass | Deterministic Minh/Linh monograms and one existing shared song replace remote photos. |
| 10 | `docs/redesign-mockups/10-explore-themes.png` | `after/10-explore-themes.png` | Pass | Uses production motifs and provider-derived counts of 12. |
| 11 | `docs/redesign-mockups/11-keo-board.png` | `after/11-keo-board.png` | Pass | Shows one real fixture kèo and the production auto-match promotion. |
| 12 | `docs/redesign-mockups/12-keo-auto-match.png` | `after/12-keo-auto-match.png` | Pass | The real sheet is mounted inside its focused-test light `Scaffold`; reason values remain `same_genre` and `nearby`; no black host region remains. |
| 13 | `docs/redesign-mockups/13-create-keo.png` | `after/13-create-keo.png` | Pass | Shows the real blank form and available V-Pop option. |
| 14 | `docs/redesign-mockups/14-keo-detail.png` | `after/14-keo-detail.png` | Pass | The safe roster is empty and the viewer sees the production join CTA. |
| 15 | `docs/redesign-mockups/15-inbox.png` | `after/15-inbox.png` | Pass | One group and one pair thread are hosted by the same light `Scaffold` relationship as `HomeShell`; no black host region remains. |
| 16 | `docs/redesign-mockups/16-chat-1to1.png` | `after/16-chat-1to1.png` | Pass | Empty in-memory history validates the real empty conversation state. |
| 17 | `docs/redesign-mockups/17-keo-group-chat.png` | `after/17-keo-group-chat.png` | Pass | Empty group history validates the production empty state and rules. |
| 18 | `docs/redesign-mockups/18-profile.png` | `after/18-profile.png` | Pass | The safe profile yields a monogram and 60% completion; its transparent root uses the same light `Scaffold` relationship as `HomeShell`; no black host region remains. |
| 19 | `docs/redesign-mockups/19-plan-map.png` | `after/19-plan.png` | Pass with follow-up | Native maps are disabled and one safe venue is shown. At 360dp, “Chia sẻ cho bạn bè” wraps to three lines; it remains reachable and overflow-free but needs a later copy/layout pass. |
| 20 | `docs/redesign-mockups/20-booking-payment.png` | `after/20-booking-payment.png` | Pass | The sheet widget is private, so both capture and live gallery open it through the real `BookingButton`; no gateway result is invented. |
| 21 | `docs/redesign-mockups/21-store.png` | `after/21-store.png` | Pass | Rows and `199k/49k/99k/79k` prices come from the in-memory catalog. |
| 22 | `docs/redesign-mockups/22-settings.png` | `after/22-settings.png` | Pass | Preserves the production consent, language, data, account, and legal hierarchy; marketing is safely false. |

State 19's three-line share CTA is the only visual follow-up. No dark band is
accepted as intentional: the 12/15/18 host defects were corrected and
recaptured.

## Android evidence

| Command/check | Outcome |
|---|---|
| `adb -s emulator-5554 shell getprop sys.boot_completed` | Pass — returned `1`. |
| Initial login fixture TDD | Red — a blank fixture found zero `screen_01_login` roots; green after the real `PhoneScreen` fixture was added. |
| `flutter test integration_test/presentation_capture_test.dart -d emulator-5554 --plain-name "captures 12-keo-auto-match from the production sheet" --reporter expanded` | Red for the host correction — required ancestor `Scaffold` count was zero. |
| `flutter test integration_test/presentation_capture_test.dart -d emulator-5554 --name "captures (12|15|18)-" --reporter expanded` | Green — all three corrected fixtures passed the light-production-host assertion. |
| `flutter drive --driver=test_driver/presentation_capture_driver.dart --target=integration_test/presentation_capture_test.dart -d emulator-5554` | Pass — `+23`; 22 screenshot tests plus teardown. |
| Exact PNG inventory | Pass — 22 approved non-empty basenames, each `1080 × 2340`. |
| Locked-pixel audit of states 12/15/18 | Pass — exact-black `0` and near-black `0` pixels for all three. |
| Manual after-image inspection | Pass — every refreshed PNG was opened; all expected states are visible. |

Flutter 3.44 reverts `convertFlutterSurfaceToImage()` during each integration
test teardown. The process-local conversion flag is reset with `addTearDown`,
which allows the full 22-state drive to cross test boundaries.

## Mobile web evidence

The preferred Chrome widget-test runner was attempted first:

- `flutter test --platform chrome test/app/presentation_matrix_test.dart
  --reporter compact` launched headless Chrome but remained at `+0 loading`
  for 4m55s and was terminated.
- A registry-only filter compiled in 22.8s and launched Chrome, then also
  remained at `+0`.
- The unrelated small control `test/shared/widgets/stamp_chip_test.dart`
  reproduced `+0 loading`.

This is recorded as a local Chrome test-runner blocker, not as a passing
browser matrix.

The bounded live alternative is
`integration_test/presentation_gallery.dart`. It imports the same 22 in-memory
capture fixture builders and uses `?state=01..22` only to select the fixture.
After `runApp`, a bounded post-frame probe walks the mounted Flutter element
tree. It sets the invisible canonical DOM marker only after the expected
`screen_XX_*` root key is genuinely present; a missing root reports a distinct
timeout/error state instead. The harness is not part of the production app or
router. Onboarding 04–06 is reached sequentially through the real
`onb_continue` control. State 20 remains the real `BookingButton` path.

| Command/check | Outcome |
|---|---|
| `flutter build web --release -t integration_test/presentation_gallery.dart` | Pass — built the isolated gallery. |
| Fresh local static server | Pass — isolated gallery artifact served to connected Chrome. |
| 22 states at `360 × 800` | Pass — 22/22 actual-root markers; document/body width 360; no horizontal overflow. |
| 22 states at `393 × 852` | Pass — 22/22 actual-root markers; document/body width 393; no horizontal overflow. |
| 22 states at `430 × 932` | Pass — 22/22 actual-root markers; document/body width 430; no horizontal overflow. |
| Manual 360dp canvas review | Pass — all 22 settled canvases were opened and checked for identity and legibility. |

The repeated live audit passed 66/66 state/viewport cases, each with an exact
canonical marker produced by a mounted root, not by the query string. For
states 04–06, the marker was absent initially and appeared only after the real
`onb_continue` control had been pressed one, two, or three times respectively.
For state 20, it was absent initially and appeared only after the real
`BookingButton` opened its private payment sheet. This is a regression proof
against the prior splash/initial-step false positive. Representative pointer,
focus, and keyboard checks passed for:

- login phone entry (`INPUT`, value `900000001`);
- onboarding 03→04→05→06 at all three widths;
- Đôi Like and Kèo Join using in-memory callbacks;
- chat composer entry (`INPUT`, value `Xin chào`);
- the real `BookingButton` opening the private payment sheet;
- a Store purchase CTA and a Settings privacy switch.

Final successful action attempts produced no application console errors and
preserved exact viewport scroll widths. Separately, the production runtime
requires the repository's existing
`--dart-define-from-file=env/dev.emulator.json` configuration; its live login
surface also passed connected-Chrome checks at 360/393/430. No environment
file was changed.

## Widget-test, iOS, and analyzer evidence

- The native widget suite includes the 22-state presentation matrix at
  360/393/430dp, text scales 1.0/1.2/1.4, reduced motion, keyboard focus, and
  Android/iOS theme-platform variants.
- iOS was validated through `TargetPlatform.iOS` widget tests only. No iOS
  Simulator or iOS build was run or claimed from Windows.
- Focused analyzer commands pass with no issues.
- The exact workspace `flutter analyze` command is polluted by the user's
  ignored `build/claude-design/...` snapshot. That snapshot is preserved; the
  exact command is also run in a clean detached worktree pinned to the final
  evidence commit.

## Boundary audit

The evidence harness imports repository interfaces only to supply in-memory
implementations and provider overrides. It performs no external backend,
network, or RPC operation. The required forbidden-path audit reports
`Frontend-only boundary clean.` No file under `supabase/`, feature
`data/domain/application`, `lib/app/router.dart`, `lib/core/providers/`, or
`lib/core/analytics/` is changed by Task 17.

## Final follow-up verification

After the light-host corrections, refreshed captures, and actual-root marker
hardening, the final verification records:

- `flutter build web --release -t integration_test/presentation_gallery.dart`
  passed for the isolated live-audit entry point.
- The exact PNG inventory found exactly 22 non-empty approved basenames and no
  extra PNGs in `after/`.
- `git diff --check e3f1f389..HEAD` and the working-tree `git diff --check`
  were both empty.
- The forbidden-path audit was rerun over committed, staged, working-tree, and
  untracked paths and again returned `Frontend-only boundary clean.`

The evidence commits exclude the pre-existing user-owned untracked mockups,
research, decision note, and scripts; they remain unmodified.
