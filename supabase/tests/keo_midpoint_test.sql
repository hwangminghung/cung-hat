-- supabase/tests/keo_midpoint_test.sql
-- Run with: supabase test db
-- Proves migration 20260707180000: get_keo_midpoint — in_keo gate, snap 3 decimals,
-- empty set when members have no locations. Seed pattern copied from plans_test.sql.
begin;
select plan(5);

select ok(exists(select 1 from pg_proc where proname='get_keo_midpoint'), 'get_keo_midpoint exists');

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000e1'),  -- host
  ('00000000-0000-0000-0000-0000000000e2'),  -- member
  ('00000000-0000-0000-0000-0000000000e3')   -- outsider
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000e1', 'Mid Host', '1990-01-01'),
  ('00000000-0000-0000-0000-0000000000e2', 'Mid Member', '1991-01-01'),
  ('00000000-0000-0000-0000-0000000000e3', 'Mid Outsider', '1992-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000e1', 'pro', 'promo')
  on conflict do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
create temp table _mid_keo (id uuid);
insert into _mid_keo
select public.create_keo(
  'Midpoint KEO', 21.028000, 105.854000, 'HN',
  now() + interval '1 day', now() + interval '1 day 2 hours',
  4, null, null, array[]::text[], 'approval');

-- 1) chua ai co vi tri -> tra 0 dong (khong loi).
select is(
  (select count(*) from public.get_keo_midpoint((select id from _mid_keo)))::int,
  0, 'khong co vi tri thanh vien -> 0 dong');

-- seed vi tri: ca 2 thanh vien CUNG toa do -> median = chinh toa do do (deterministic).
set local role postgres;
insert into public.keo_members (keo_id, user_id, join_status, confirmed) values
  ((select id from _mid_keo), '00000000-0000-0000-0000-0000000000e2', 'approved', true)
  on conflict do nothing;
insert into public.user_locations (user_id, location) values
  ('00000000-0000-0000-0000-0000000000e1', ST_SetSRID(ST_MakePoint(105.854, 21.028), 4326)::geography),
  ('00000000-0000-0000-0000-0000000000e2', ST_SetSRID(ST_MakePoint(105.854, 21.028), 4326)::geography)
  on conflict (user_id) do update set location = excluded.location;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;

-- 2) midpoint = toa do chung, da round 3 chu so le.
select results_eq(
  $$ select lat, lng from public.get_keo_midpoint((select id from _mid_keo)) $$,
  $$ values (21.028::double precision, 105.854::double precision) $$,
  'midpoint = toa do chung, round 3 decimals');

-- 3) khong lo toa do tho: round(,3) cua gia tri tra ve phai bang chinh no
-- (so sanh qua numeric de ne floating-point, KHONG dung floor(x*1000)).
select ok(
  (select round(lat::numeric, 3)::double precision = lat
      and round(lng::numeric, 3)::double precision = lng
     from public.get_keo_midpoint((select id from _mid_keo))),
  'lat/lng snap luoi 0.001');

-- 4) nguoi ngoai keo -> check_violation.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e3"}';
select throws_ok(
  $$ select * from public.get_keo_midpoint((select id from _mid_keo)) $$,
  '23514', 'not_in_keo', 'outsider bi chan boi in_keo gate');

select * from finish();
rollback;
