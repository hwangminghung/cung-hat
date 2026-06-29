# Cung Hat - Auto Keo Match Design

Date: 2026-06-29
Status: approved for spec review

## Goal

Make the "Ghep nhom cho toi" entry point on the Keo board useful: when a user taps it, the app finds a suitable existing keo first. If no existing keo is good enough, the app proposes a new keo draft and asks the user whether they want to create it. The app must never silently create a keo.

## Decision

Use approach 2: server-side matching plus explicit user confirmation before creating a new keo.

This fits the current app shape:

- `KeoBoardScreen` already has a "Ghep nhom cho toi" banner.
- Existing keo lifecycle already lives behind Supabase RPCs.
- Existing privacy pattern returns distance bands and public/sanitized metadata instead of user coordinates or raw scores.
- Plan and venue flow already has midpoint venue suggestion and a bottom sheet time picker.
- Pro gating already prevents non-Pro users from creating keo server-side.

## Non-Goals

- Do not create a keo without a user confirmation tap.
- Do not expose raw user coordinates, exact match score, ranking weights, or other users' private taste rows.
- Do not build a full availability calendar in this slice.
- Do not bypass the current Pro gate for keo creation.
- Do not refactor unrelated keo, plan, onboarding, OTP, or map changes already in the working tree.

## Architecture

Add a small auto-match surface inside the keo feature:

- Supabase owns candidate selection and scoring.
- Flutter calls one suggestion RPC and renders a result sheet.
- Joining an existing keo reuses `request_join_keo`.
- Creating a proposed keo uses a new RPC that still checks Pro entitlement and rate limits.

The first implementation does not need an Edge Function. Postgres has the data and primitives already needed: taste tables, snapped locations, block/report safety tables, keo status/capacity, and venue/plan RPCs.

## Database Contract

Add a new composite type:

```sql
public.keo_match_suggestion as (
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
)
```

`suggestion_type` is either:

- `existing_keo`
- `new_keo_proposal`

For `existing_keo`, `keo_id` is present and proposed fields are null.

For `new_keo_proposal`, `keo_id` is null and proposed fields are present. This is only a draft; no row is inserted into `public.keo`.

Add RPC:

```sql
public.suggest_keo_match(p_limit int default 3)
returns setof public.keo_match_suggestion
```

The RPC returns up to `p_limit` existing keo suggestions. If no existing keo meets the minimum threshold, it returns one `new_keo_proposal`.

Add RPC:

```sql
public.create_auto_matched_keo(
  p_title text,
  p_start timestamptz,
  p_end timestamptz,
  p_size int,
  p_genres text[],
  p_join_mode text default 'open'
) returns uuid
```

This RPC creates a keo from the current user's stored snapped location in `public.user_locations`. It must:

- Require `app_private.is_pro()`, raising `pro_required` for non-Pro users.
- Enforce `app_private.enforce_rate_limit('create_keo', 10, interval '1 day')`.
- Require the caller has `profiles.age_verified = true`.
- Require the caller has a stored location row.
- Insert the host row in `keo_members` as approved and confirmed.
- Reuse the same title, time, size, genre, join-mode checks as `create_keo`.

## Matching Rules

`suggest_keo_match` should rank only safe, actionable existing keo:

- `keo.status = 'open'`
- `keo.soft_deleted_at is null`
- `keo.time_window_end > now()`
- approved members count is below `group_size_target`
- caller is not the host
- caller is not already active in that keo
- caller and host are not blocked in either direction
- caller and host have verified age
- host profile is not soft-deleted

Score existing keo with simple, auditable rules:

- Music fit: shared genres between caller taste and `keo.genres`; if the keo has no genres, do not penalize harshly.
- Distance fit: closer snapped distance gets a bonus, but clients only see `distance_band`.
- Time fit: starts within the next 7 days; prefer evening slots.
- Capacity fit: keo with remaining slots gets a bonus; full keo is excluded.
- Safety fit: exclude high-risk profiles when needed, or subtract by `profiles.report_risk`.
- Activity fit: host active recently gets a small bonus.

Reason labels should be short stable tokens such as:

- `shared_genres`
- `near_you`
- `evening_slot`
- `open_join`
- `available_slots`
- `active_host`

The client maps these to Vietnamese copy.

## Availability

The current schema has no dedicated availability table. For this slice:

- Existing keo already provide their own time windows.
- New proposals use the next reasonable Vietnam-local evening slot, defaulting to 19:00-22:00 in UTC+7 launch cities.
- If Vietnam-local time is already past 19:00, choose tomorrow 19:00-22:00.

Future extension:

```sql
public.user_availability_windows (
  user_id uuid,
  starts_at timestamptz,
  ends_at timestamptz,
  source text check (source in ('manual','inferred')),
  created_at timestamptz default now()
)
```

That table is intentionally out of scope for the first slice.

## UI Flow

In `KeoBoardScreen`, replace the current banner refresh action.

Tap "Ghep nhom cho toi":

1. Try `locationService.captureAndPush()` so the server has a fresh snapped location. If this fails, still call `suggest_keo_match`; the RPC either uses an existing stored server location or raises `location_required`.
2. Call `keoRepository.suggestMatch()`.
3. Show a modal bottom sheet with the result.

Existing keo result:

- Title: "Keo hop voi ban"
- Show title, distance band, time window, slots, genres, join mode, and reason chips.
- Primary CTA:
  - `join_mode = 'open'`: "Vao keo nay"
  - `join_mode = 'approval'`: "Xin vao keo"
- CTA calls `requestJoin(keoId)`.
- On success, invalidate `openKeosProvider` and navigate to `/keo/{id}?title=...` or show success in place.

New proposal result:

- Title: "Tao keo moi tu goi y nay?"
- Show proposed title, time, size, genres, and reason chips.
- Primary CTA: "Tao keo nay"
- Secondary CTA: "De sau"
- Primary CTA calls `createAutoMatchedKeo(...)`.
- On success, navigate to `/keo/{id}`.
- If server raises `pro_required`, show the existing Pro upgrade path.

Empty/error:

- Network or RPC error shows a retry action.
- `location_required` shows copy that asks the user to enable Location and try again.
- No profile/taste can still propose a broad default keo, but the reason copy should avoid claiming music fit.

## Flutter Files

Create:

- `lib/features/keo/domain/keo_match_suggestion.dart`
- `lib/features/keo/presentation/keo_match_sheet.dart`

Modify:

- `lib/features/keo/data/keo_repository.dart`
- `lib/features/keo/application/keo_providers.dart`
- `lib/features/keo/presentation/keo_board_screen.dart`
- `lib/features/keo/data/keo_errors.dart`

Generated files:

- `lib/features/keo/domain/keo_match_suggestion.freezed.dart`
- `lib/features/keo/domain/keo_match_suggestion.g.dart`

## Error Handling

Server error codes:

- `pro_required`: creating a suggested new keo requires Pro.
- `location_required`: no stored location exists for auto-create.
- `age_not_verified`: caller is not age verified.
- `no_matchable_keo`: only if the RPC cannot even build a default proposal.
- existing keo codes from `request_join_keo`: `free_join_limit`, `keo_full`, `already_declined`, `keo_not_open`, `blocked`.

Client maps these via `keoErrorMessage` and uses the same upgrade dialog where possible.

## Privacy and Safety

- The suggestion RPC is the privacy boundary.
- Do not return exact user coordinates or exact distances.
- Do not return raw scores or ranking weights.
- Do not return other users' private taste rows.
- Apply block checks both ways.
- Require age-verified participants for suggestions.
- Keep `report_risk` server-only.
- Creating a proposal should use the caller's stored snapped location, not a client-supplied arbitrary coordinate.

## Testing

SQL tests:

- `keo_match_suggestion` type has no coordinate or raw-score columns.
- A keo with shared genre and nearby distance is returned as `existing_keo`.
- A blocked host is excluded.
- A full or expired keo is excluded.
- When no existing keo qualifies, RPC returns `new_keo_proposal` and does not insert into `public.keo`.
- `create_auto_matched_keo` rejects non-Pro users with `pro_required`.
- `create_auto_matched_keo` rejects users without stored location with `location_required`.
- A Pro user with location can create from proposal and receives a host membership row.

Flutter tests:

- Repository maps `suggest_keo_match` rows into `KeoMatchSuggestion`.
- Repository calls `create_auto_matched_keo` with expected params.
- Board banner shows loading while matching.
- Existing result sheet calls `requestJoin`.
- Proposal result sheet calls `createAutoMatchedKeo` only after "Tao keo nay".
- Proposal result sheet can be dismissed without creating.
- `pro_required` path shows upgrade copy.

Verification commands after implementation:

```powershell
flutter analyze
flutter test test/features/keo
supabase test db
flutter build apk --debug --dart-define-from-file=env/dev.json
```

## Rollout

This can ship as a narrow feature flag-free slice because:

- It adds new RPCs rather than changing existing `request_join_keo` or `create_keo`.
- It reuses the current board banner.
- It preserves server authority.
- It keeps the current Pro creation gate intact.

If needed, the UI can initially hide the auto-create CTA for non-Pro users, but the server must still enforce `pro_required`.
