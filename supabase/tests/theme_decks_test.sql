-- Run with: supabase test db
-- Proves migration 20260706150000_theme_decks:
--   1) get_theme_deck_counts(genres[]) counts active-7-day users per genre
--      within 50km, WITHOUT swallowing 0-count genres (subquery-per-row shape).
--   2) get_discovery_candidates gains p_genre (3rd param) and filters by it.
-- Seed pattern copied from boost_test.sql/candidate_bio_test.sql: co-located
-- users near Ha Noi (105.854, 21.028). Direct insert into user_locations
-- (as postgres) instead of the update_my_location RPC — matches
-- auto_keo_match_test.sql's seed style and avoids a role switch per row.
begin;
select plan(5);

set local role postgres;

-- This test asserts EXACT counts/sets within 50km of Ha Noi, so pre-existing
-- local-dev rows near that cluster (manual QA fixtures, e.g. "QA Linh Ballad")
-- would inflate live_count / leak into results_eq. Soft-delete them for the
-- duration of this transaction only (rolled back at the end, same technique
-- as auto_keo_match_test.sql's `update public.keo set soft_deleted_at = now()`).
update public.profiles set soft_deleted_at = now()
  where soft_deleted_at is null
    and id not in (
      '00000000-0000-0000-0000-0000000000d1',
      '00000000-0000-0000-0000-0000000000d2',
      '00000000-0000-0000-0000-0000000000d3'
    );

insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000d1'), -- caller A
  ('00000000-0000-0000-0000-0000000000d2'), -- B: genre ballad, active now
  ('00000000-0000-0000-0000-0000000000d3')  -- C: genre rap_vn, inactive 30d
  on conflict (id) do nothing;

insert into public.profiles (id, display_name, dob, age_verified, last_active) values
  ('00000000-0000-0000-0000-0000000000d1','Caller D','1995-01-01', true, now()),
  ('00000000-0000-0000-0000-0000000000d2','Ballad D','1995-01-01', true, now()),
  ('00000000-0000-0000-0000-0000000000d3','Rap D','1995-01-01', true, now())
  on conflict (id) do update
  set display_name = excluded.display_name, last_active = excluded.last_active;

-- C is inactive beyond the 7-day window used by get_theme_deck_counts.
update public.profiles set last_active = now() - interval '30 days'
  where id = '00000000-0000-0000-0000-0000000000d3';

insert into public.user_locations (user_id, location, area_label) values
  ('00000000-0000-0000-0000-0000000000d1', public.ST_SetSRID(public.ST_MakePoint(105.854, 21.028), 4326)::public.geography, 'HN'),
  ('00000000-0000-0000-0000-0000000000d2', public.ST_SetSRID(public.ST_MakePoint(105.854, 21.028), 4326)::public.geography, 'HN'),
  ('00000000-0000-0000-0000-0000000000d3', public.ST_SetSRID(public.ST_MakePoint(105.854, 21.028), 4326)::public.geography, 'HN')
  on conflict (user_id) do update
  set location = excluded.location, area_label = excluded.area_label, updated_at = now();

insert into public.user_genres (user_id, genre_id) values
  ('00000000-0000-0000-0000-0000000000d2', 'ballad'),
  ('00000000-0000-0000-0000-0000000000d3', 'rap_vn')
  on conflict do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d1","role":"authenticated"}';
set local role authenticated;

-- Case 1: ballad has exactly 1 live user (B, active now, co-located).
select is(
  (select live_count from public.get_theme_deck_counts(array['ballad','rap_vn','bolero'])
     where genre_id = 'ballad'),
  1,
  'ballad live_count = 1 (B active now, co-located)');

-- Case 2: rap_vn has 0 live users -- C exists but is inactive beyond 7 days.
select is(
  (select live_count from public.get_theme_deck_counts(array['ballad','rap_vn','bolero'])
     where genre_id = 'rap_vn'),
  0,
  'rap_vn live_count = 0 (C inactive > 7 days)');

-- Case 3: bolero has NO users at all -- the row must still exist with
-- live_count = 0. This is the regression the subquery-per-row shape (vs.
-- LEFT JOIN + outer WHERE, which would drop the row entirely) guards against.
select ok(
  exists(select 1 from public.get_theme_deck_counts(array['ballad','rap_vn','bolero'])
           where genre_id = 'bolero' and live_count = 0),
  'bolero row exists with live_count = 0 (0-count genre not swallowed)');

-- Case 4: get_discovery_candidates(p_genre) filters correctly -- 'ballad'
-- returns only B.
select results_eq(
  $$ select id from public.get_discovery_candidates(20, 50, 'ballad') $$,
  $$ values ('00000000-0000-0000-0000-0000000000d2'::uuid) $$,
  'get_discovery_candidates(p_genre := ballad) returns only B');

-- Case 5: 'bolero' (nobody in that genre) returns 0 rows.
select is_empty(
  $$ select id from public.get_discovery_candidates(20, 50, 'bolero') $$,
  'get_discovery_candidates(p_genre := bolero) returns 0 rows');

select * from finish();
rollback;
