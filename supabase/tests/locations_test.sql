-- Run with: supabase test db
-- Covers migration 0006_locations.sql:
--   1) RLS: public.user_locations has no client policy, so it is never directly
--      selectable even as role `authenticated` (exact coords are RPC-only).
--   2) app_private.dist_band boundary buckets (CASE thresholds <1000/<3000/<5000).
--   3) Snap-at-write: public.update_my_location rounds lat/lng to 3 decimals
--      (~100m k-anonymity) before storing the point.
begin;
select plan(9);

-- Assertion 1: RLS with no policy ⇒ zero rows selectable directly even as authenticated.
set local role authenticated;
select is_empty($$ select * from public.user_locations $$, 'user_locations not directly selectable');

-- app_private had `revoke all ... from authenticated`, so calling app_private.dist_band
-- under role `authenticated` would raise "permission denied for schema app_private".
-- Reset to the default (superuser) role so the bucketing assertions exercise the function
-- itself rather than schema-level EXECUTE privilege.
reset role;

-- Assertions 2-7: dist_band boundary cases. CASE in migration:
--   m < 1000 -> '<1', m < 3000 -> '1-3', m < 5000 -> '3-5', else '5+'.
-- The cutoffs are strict `<`, so each round number falls into the NEXT band up.
select is(app_private.dist_band(999),  '<1',  'dist_band(999) -> <1');
select is(app_private.dist_band(1000), '1-3', 'dist_band(1000) -> 1-3 (1000 is NOT <1)');
select is(app_private.dist_band(2999), '1-3', 'dist_band(2999) -> 1-3');
select is(app_private.dist_band(3000), '3-5', 'dist_band(3000) -> 3-5');
select is(app_private.dist_band(4999), '3-5', 'dist_band(4999) -> 3-5');
select is(app_private.dist_band(5000), '5+',  'dist_band(5000) -> 5+');

-- Assertions 8-9: snap-at-write via update_my_location under a faked authenticated user.
-- Direct INSERT into user_locations is blocked (RLS, no policy), so the only way in is
-- the SECURITY DEFINER RPC, which keys off auth.uid(). Seed auth.users as owner (postgres
-- bypasses RLS/privilege) then fake the JWT `sub` claim like consent_gate_test.sql does.
set local role postgres;
insert into auth.users (id) values ('00000000-0000-0000-0000-000000000001')
  on conflict (id) do nothing;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-000000000001"}';
set local role authenticated;

-- 10.7771 -> round(,3) -> 10.777 ; 106.7009 -> round(,3) -> 106.701
select public.update_my_location(10.7771, 106.7009, 'Q1');

-- Read the stored point back as owner (RLS makes it invisible to other roles) and assert
-- the coordinates were snapped to 3 decimals at write time.
set local role postgres;
select is(
  public.ST_Y(location::public.geometry),
  10.777::double precision,
  'update_my_location snaps latitude to 3 decimals (10.7771 -> 10.777)')
  from public.user_locations
  where user_id = '00000000-0000-0000-0000-000000000001';
select is(
  public.ST_X(location::public.geometry),
  106.701::double precision,
  'update_my_location snaps longitude to 3 decimals (106.7009 -> 106.701)')
  from public.user_locations
  where user_id = '00000000-0000-0000-0000-000000000001';

select * from finish();
rollback;
