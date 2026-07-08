-- supabase/tests/keo_midpoint_test.sql
-- Run with: supabase test db
-- Proves migration 20260707180000 + 20260708140000: get_keo_midpoint — in_keo gate,
-- snap 3 decimals, empty set when members have no locations, AND empty set when
-- only 1 member has a location ([A-M3] — a single located member must not leak
-- their own ~110m-snapped location as "the midpoint"). Seed pattern copied from
-- plans_test.sql.
-- Median trick: geometric median cua {A, A, B} = CHINH XAC A (bat dang thuc tam giac),
-- nen seed A voi 4 chu so le -> round(,3) trong RPC la load-bearing (xoa round la fail).
begin;
select plan(6);

select ok(exists(select 1 from pg_proc where proname='get_keo_midpoint'), 'get_keo_midpoint exists');

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000e1'),  -- host (diem A)
  ('00000000-0000-0000-0000-0000000000e2'),  -- member (diem A)
  ('00000000-0000-0000-0000-0000000000e3'),  -- outsider
  ('00000000-0000-0000-0000-0000000000e4')   -- member 2 (diem B cua {A,A,B})
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000e1', 'Mid Host', '1990-01-01'),
  ('00000000-0000-0000-0000-0000000000e2', 'Mid Member', '1991-01-01'),
  ('00000000-0000-0000-0000-0000000000e3', 'Mid Outsider', '1992-01-01'),
  ('00000000-0000-0000-0000-0000000000e4', 'Mid Member2', '1993-01-01')
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

-- seed vi tri {A, A, B}: host + e2 tai A = (105.8547, 21.0283) 4 chu so le, e4 tai B.
-- Median cua {A,A,B} = chinh xac A (deterministic), va A KHONG nam tren luoi 0.001
-- -> ket qua dung (21.028, 105.855) CHI khi RPC co round(,3).
set local role postgres;
insert into public.keo_members (keo_id, user_id, join_status, confirmed) values
  ((select id from _mid_keo), '00000000-0000-0000-0000-0000000000e2', 'approved', true),
  ((select id from _mid_keo), '00000000-0000-0000-0000-0000000000e4', 'approved', true)
  on conflict do nothing;

-- host (e1) co vi tri TRUOC, con e2/e4 thi chua -> chi 1 thanh vien co vi tri.
insert into public.user_locations (user_id, location) values
  ('00000000-0000-0000-0000-0000000000e1', ST_SetSRID(ST_MakePoint(105.8547, 21.0283), 4326)::geography)
  on conflict (user_id) do update set location = excluded.location;

-- 2) [A-M3] chi 1 nguoi (host) co vi tri -> phai tra 0 dong, KHONG duoc lo toa do
-- ~110m cua rieng host nhu the no la "midpoint".
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_keo_midpoint((select id from _mid_keo))),
  0, '1 vi tri -> 0 dong');

-- gio moi them vi tri e2 (tai A) va e4 (tai B), hoan tat cau truc {A,A,B}.
set local role postgres;
insert into public.user_locations (user_id, location) values
  ('00000000-0000-0000-0000-0000000000e2', ST_SetSRID(ST_MakePoint(105.8547, 21.0283), 4326)::geography),
  ('00000000-0000-0000-0000-0000000000e4', ST_SetSRID(ST_MakePoint(105.8600, 21.0400), 4326)::geography)
  on conflict (user_id) do update set location = excluded.location;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;

-- 3) midpoint = A da round 3 chu so le: 21.0283 -> 21.028, 105.8547 -> 105.855.
select results_eq(
  $$ select lat, lng from public.get_keo_midpoint((select id from _mid_keo)) $$,
  $$ values (21.028::double precision, 105.855::double precision) $$,
  'midpoint = diem A cua {A,A,B}, round 3 decimals');

-- 4) khong lo toa do tho: round(,3) cua gia tri tra ve phai bang chinh no
-- (so sanh qua numeric de ne floating-point, KHONG dung floor(x*1000)).
select ok(
  (select round(lat::numeric, 3)::double precision = lat
      and round(lng::numeric, 3)::double precision = lng
     from public.get_keo_midpoint((select id from _mid_keo))),
  'lat/lng snap luoi 0.001');

-- 5) nguoi ngoai keo -> check_violation.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e3"}';
select throws_ok(
  $$ select * from public.get_keo_midpoint((select id from _mid_keo)) $$,
  '23514', 'not_in_keo', 'outsider bi chan boi in_keo gate');

select * from finish();
rollback;
