-- Run with: supabase test db
-- Proves migration 20260713150000: get_my_keos tra dung danh sach keo cua
-- caller cho section "Keo cua ban" (mockup 15) — ke ca khi keo da roi 'open'
-- (planning), la loi vao duy nhat cua host/member sau khi board an keo.
-- Seed pattern copy keo_header_test.sql (create_keo can pro host).
begin;
select plan(6);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000d1'), -- host (pro)
  ('00000000-0000-0000-0000-0000000000d2'), -- member approved
  ('00000000-0000-0000-0000-0000000000d3'), -- requester (pending)
  ('00000000-0000-0000-0000-0000000000d4'), -- outsider
  ('00000000-0000-0000-0000-0000000000d5')  -- member da roi (left)
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000d1', 'MyKeo Host', '1990-01-01'),
  ('00000000-0000-0000-0000-0000000000d2', 'MyKeo Member', '1991-01-01'),
  ('00000000-0000-0000-0000-0000000000d3', 'MyKeo Requester', '1992-01-01'),
  ('00000000-0000-0000-0000-0000000000d4', 'MyKeo Outsider', '1993-01-01'),
  ('00000000-0000-0000-0000-0000000000d5', 'MyKeo Leaver', '1994-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000d1', 'pro', 'promo')
  on conflict do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d1"}';
set local role authenticated;
create temp table _my_keo (id uuid);
insert into _my_keo
select public.create_keo(
  'MyKeo KEO', 21.028000, 105.854000, 'Dong Da HN',
  now() + interval '1 day', now() + interval '1 day 2 hours',
  4, null, null, array[]::text[], 'approval');
-- Keo thu 2 cua host roi cancel — khong duoc hien.
create temp table _my_keo_cancelled (id uuid);
insert into _my_keo_cancelled
select public.create_keo(
  'MyKeo Cancelled', 21.028000, 105.854000, 'Dong Da HN',
  now() + interval '2 day', now() + interval '2 day 2 hours',
  4, null, null, array[]::text[], 'approval');

set local role postgres;
insert into public.keo_members (keo_id, user_id, role, join_status, confirmed) values
  ((select id from _my_keo), '00000000-0000-0000-0000-0000000000d2', 'member', 'approved', true),
  ((select id from _my_keo), '00000000-0000-0000-0000-0000000000d3', 'member', 'requested', false),
  ((select id from _my_keo), '00000000-0000-0000-0000-0000000000d5', 'member', 'left', false)
  on conflict (keo_id, user_id) do nothing;
-- Keo chinh chuyen 'planning' (da roi board) — day la ca can chung minh.
update public.keo set status = 'planning' where id = (select id from _my_keo);
update public.keo set status = 'cancelled' where id = (select id from _my_keo_cancelled);

-- 1+2) Host thay keo planning cua minh, is_mine = true.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d1"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_my_keos() where title = 'MyKeo KEO'),
  1, 'host thay keo planning cua minh');
select is(
  (select is_mine from public.get_my_keos() where title = 'MyKeo KEO'),
  true, 'host: is_mine = true (UI chip Chu keo)');

-- 3) Member approved thay keo, is_mine = false.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d2"}';
set local role authenticated;
select is(
  (select is_mine from public.get_my_keos() where title = 'MyKeo KEO'),
  false, 'member approved thay keo, is_mine = false');

-- 4) Requester dang cho duyet van thay.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d3"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_my_keos() where title = 'MyKeo KEO'),
  1, 'requester thay keo dang xin vao');

-- 5) Nguoi ngoai khong thay gi.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d4"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_my_keos() where title like 'MyKeo%'),
  0, 'nguoi ngoai: 0 keo');

-- 6) Member da roi (left) khong thay; keo cancelled khong hien voi host.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d5"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_my_keos() where title like 'MyKeo%'),
  0, 'member da roi: 0 keo (va cancelled khong hien — case host da phu o #1 chi tra 1 row)');

select * from finish();
rollback;
