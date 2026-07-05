-- Run with: supabase test db
-- Proves migration 20260704110000_boost: activate_boost() (Pro-gated, 1/ngay, 30 phut)
-- va uu tien xep hang trong get_discovery_candidates cho ho so dang boost.
--
-- rate_limits tumbling window (0007): window_start = to_timestamp(floor(epoch(now())/epoch(p_window))*epoch(p_window)).
-- Voi p_window = interval '1 day' -> snap ve UTC midnight = date_trunc('day', now()).
-- enforce_rate_limit tang count TRUOC roi raise khi count > limit; cap 'daily_boost' = 1,
-- nen seed count = 1 tai window hom nay lam lan goi tiep theo vuot cap (1+1 > 1) -> 23514.
-- is_pro() tra true khi co entitlement 'pro' con hieu luc cho auth.uid().
begin;
select plan(5);

set local role postgres;

insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000b1'), -- free user
  ('00000000-0000-0000-0000-0000000000b2'), -- pro user
  ('00000000-0000-0000-0000-0000000000b3'), -- ranking: caller
  ('00000000-0000-0000-0000-0000000000b4'), -- ranking: boosting candidate
  ('00000000-0000-0000-0000-0000000000b5')  -- ranking: non-boosting candidate
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, age_verified, last_active) values
  ('00000000-0000-0000-0000-0000000000b1','Free B','1990-01-01', true, now()),
  ('00000000-0000-0000-0000-0000000000b2','Pro B','1990-01-01', true, now()),
  ('00000000-0000-0000-0000-0000000000b3','Caller','1990-01-01', true, now()),
  -- Both candidates: SAME dob, IDENTICAL last_active so activity term is equal, no genres/songs.
  ('00000000-0000-0000-0000-0000000000b4','Boosted Cand','1990-01-01', true, now() - interval '10 days'),
  ('00000000-0000-0000-0000-0000000000b5','Plain Cand','1990-01-01', true, now() - interval '10 days')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000b2','pro','promo')
  on conflict do nothing;

-- Case 1: FREE user calling activate_boost() -> throws 23514 with message 'pro_required'.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b1","role":"authenticated"}';
set local role authenticated;
select throws_ok(
  $$ select public.activate_boost() $$,
  '23514', 'pro_required', 'free user cannot activate_boost (pro_required)');

-- Case 2: PRO user calling activate_boost() -> returns timestamptz ~ now() + 30 min.
-- NOTE: activate_boost() is VOLATILE and has a side effect (inserts a boosts row), so it
-- MUST be evaluated exactly once. `x BETWEEN a AND b` expands to `x>=a AND x<=b`, which
-- would evaluate the volatile call TWICE (second call then raises boost_active). Materialize
-- the single return value in a CTE first, then range-check it.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b2","role":"authenticated"}';
set local role authenticated;
with b as (select public.activate_boost() as exp)
select ok(
  b.exp between now() + interval '29 minutes' and now() + interval '31 minutes',
  'pro user activate_boost returns expiry ~ now() + 30 min')
from b;

-- Case 3: PRO user with a boost still active -> throws 23514 'boost_active'.
-- (Case 2 already inserted an active boosts row for b2, so a second call must be rejected.)
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b2","role":"authenticated"}';
set local role authenticated;
select throws_ok(
  $$ select public.activate_boost() $$,
  '23514', 'boost_active', 'second activate_boost while active raises boost_active');

-- Case 4: daily_boost at cap (count=1) AND no active boost row -> throws 23514 'boost_limit'.
set local role postgres;
delete from public.boosts where user_id = '00000000-0000-0000-0000-0000000000b2';
insert into public.rate_limits (user_id, bucket, window_start, count) values
  ('00000000-0000-0000-0000-0000000000b2','daily_boost', date_trunc('day', now()), 1)
  on conflict (user_id, bucket, window_start) do update set count = 1;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b2","role":"authenticated"}';
set local role authenticated;
select throws_ok(
  $$ select public.activate_boost() $$,
  '23514', 'boost_limit', 'pro user over daily_boost cap raises boost_limit');

-- Case 5: ranking -- two candidates at the same location/eligibility for a third caller;
-- the one with an active boost ranks FIRST. Seed locations via the SECURITY DEFINER RPC
-- update_my_location (keys off auth.uid(); direct insert into user_locations is RLS-blocked).
-- Same coords for both candidates -> identical dist_m; identical last_active (both seeded
-- equal -- update_my_location may bump both to now(), still equal) + no shared genres/songs
-- -> all base score terms equal, so the +3.0 boost term is the only tiebreaker.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b3","role":"authenticated"}';
set local role authenticated;
select public.update_my_location(10.777, 106.701, 'Q1'); -- caller
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b4","role":"authenticated"}';
set local role authenticated;
select public.update_my_location(10.778, 106.701, 'Q1'); -- boosting candidate
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b5","role":"authenticated"}';
set local role authenticated;
select public.update_my_location(10.778, 106.701, 'Q1'); -- non-boosting candidate (same coords as b4)

-- Give ONLY b4 an active boost.
set local role postgres;
insert into public.boosts (user_id, expires_at) values
  ('00000000-0000-0000-0000-0000000000b4', now() + interval '30 minutes')
  on conflict (user_id) do update set expires_at = excluded.expires_at;

-- Call as caller b3 and assert the boosting candidate (b4) appears before the plain one (b5).
-- WITH ORDINALITY preserves the function's ORDER BY as an explicit rank column (ord); compare
-- the rank of b4 (boosting) against b5 (plain). b4 < b5 => b4 ranks higher.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b3","role":"authenticated"}';
set local role authenticated;
with ranked as (
  select t.id, t.ord as rn
  from public.get_discovery_candidates(20, 50) with ordinality as t(id, display_name, age,
       distance_band, shared_genres, shared_baitu, verified, active_today, bio, ord)
)
select ok(
  (select rn from ranked where id = '00000000-0000-0000-0000-0000000000b4')
    < (select rn from ranked where id = '00000000-0000-0000-0000-0000000000b5'),
  'boosting candidate ranks before non-boosting candidate');

select * from finish();
rollback;
