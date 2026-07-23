# Presentation gallery browser audit

## Scope

- Gallery entry point: `integration_test/presentation_gallery.dart`
- Fixture source: `integration_test/presentation_capture_test.dart`
- Audited source commit: `ba17963b2f61909ffb8fee085f4cc29dff7a5650`
- Machine-readable result: `docs/redesign-validation/web-audit-result.json`
- Required viewports: `360 × 800`, `393 × 852`, and `430 × 932`

The `state` query parameter selects a fixture only. It does not set the
success marker. The gallery writes `data-gallery-state` only after traversing
the mounted Flutter element tree and finding the exact expected
`screen_XX_*` key.

## Build and serve

Run from the repository root:

```powershell
flutter build web --release -t integration_test/presentation_gallery.dart
Set-Location build/web
python -m http.server 7357 --bind 127.0.0.1
```

Open `http://127.0.0.1:7357/?state=01` in Chrome. Use Chrome DevTools device
emulation to set each required viewport exactly.

## Exact case procedure

For each viewport, navigate through `?state=01` to `?state=22`.

- States 01–03, 07–19, and 21–22 must become ready without an interaction.
- For state 04, confirm the marker is absent, then activate the visible
  `Tiếp tục` control once.
- For state 05, confirm the marker is absent, then activate `Tiếp tục` twice.
- For state 06, confirm the marker is absent, then activate `Tiếp tục` three
  times.
- For state 20, confirm the marker is absent, then activate the single visible
  production `BookingButton`.

After the required interaction, run this exact expression in the DevTools
console:

```js
JSON.stringify({
  expected: document.documentElement.getAttribute('data-gallery-expected'),
  actual: document.documentElement.getAttribute('data-gallery-state'),
  status: document.documentElement.getAttribute('data-gallery-status'),
  error: document.documentElement.getAttribute('data-gallery-error'),
  innerWidth: window.innerWidth,
  innerHeight: window.innerHeight,
  documentWidth: document.documentElement.scrollWidth,
  bodyWidth: document.body.scrollWidth
})
```

A case passes only when:

- `status` is `ready`;
- `actual` equals `expected`;
- `actual` is the canonical root listed in the screen coverage map;
- `innerWidth`, `documentWidth`, and `bodyWidth` all equal the requested
  viewport width;
- `innerHeight` equals the requested viewport height; and
- `error` is `null`.

The exact expected roots, in state order, are:

```text
screen_01_login
screen_02_otp
screen_03_onboarding_dob
screen_04_onboarding_consent
screen_05_onboarding_profile
screen_06_onboarding_music_taste
screen_07_doi_deck
screen_08_doi_profile_detail
screen_09_match_celebration
screen_10_explore_themes
screen_11_keo_board
screen_12_keo_auto_match
screen_13_create_keo
screen_14_keo_detail
screen_15_inbox
screen_16_chat_1to1
screen_17_keo_group_chat
screen_18_profile
screen_19_plan
screen_20_booking_payment
screen_21_store
screen_22_settings
```

## Negative timeout regression

Navigate to:

```text
http://127.0.0.1:7357/?state=01&probe=missing-root
```

The fixture still mounts state 01, but the audit deliberately expects
`screen_missing_probe`. Within 5.5 seconds, the exact expected attributes are:

```text
data-gallery-state    absent
data-gallery-status   timeout
data-gallery-error    expected-root-missing
data-gallery-expected screen_missing_probe
```

This proves that a missing canonical root reaches a bounded failure state
instead of remaining indefinitely in `waiting`.
