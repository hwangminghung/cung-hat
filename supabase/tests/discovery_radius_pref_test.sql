-- Run with: supabase test db
-- Proves migration 20260707160000_discovery_radius_pref: discovery_prefs.radius_km
-- (5-100 range CHECK) + set_discovery_radius / get_discovery_prefs RPCs.
-- Seed pattern copied from discovery_prefs_test.sql.
begin;
select plan(5);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000f1')  -- caller
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, age_verified) values
  ('00000000-0000-0000-0000-0000000000f1','R','1995-01-01', true)
  on conflict (id) do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f1","role":"authenticated"}';
set local role authenticated;

-- 1) chua co dong prefs -> mac dinh (false, 50) qua getter gop.
select results_eq(
  $$ select auto_expand, radius_km from public.get_discovery_prefs() $$,
  $$ values (false, 50) $$,
  'mac dinh (false, 50) khi chua co dong prefs');

-- 2) set radius 80 -> doc lai qua getter gop ra (false, 80).
select public.set_discovery_radius(80);
select results_eq(
  $$ select auto_expand, radius_km from public.get_discovery_prefs() $$,
  $$ values (false, 80) $$,
  'doc lai ra (false, 80) sau khi set radius');

-- 3) auto_expand set true truoc do (RPC cu set_discovery_auto_expand) van doc
-- dung qua getter gop, khong bi ghi de boi radius.
select public.set_discovery_auto_expand(true);
select results_eq(
  $$ select auto_expand, radius_km from public.get_discovery_prefs() $$,
  $$ values (true, 80) $$,
  'auto_expand=true van giu radius=80 qua getter gop');

-- 4-5) radius ngoai range [5,100] -> check_violation (23514).
select throws_ok(
  $$ select public.set_discovery_radius(4) $$,
  '23514', 'radius_range', 'radius 4 (duoi 5) raises check_violation (radius_range)');
select throws_ok(
  $$ select public.set_discovery_radius(101) $$,
  '23514', 'radius_range', 'radius 101 (tren 100) raises check_violation (radius_range)');

select * from finish();
rollback;
