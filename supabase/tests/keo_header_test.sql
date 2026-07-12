-- Run with: supabase test db
-- Proves migration 20260713120000:
--   (a) get_keo_roster tra cot `confirmed` dung gia tri (nut "Dong y tham gia"
--       phia client doi trang thai dua tren cot nay);
--   (b) get_keo_header: keo 'open' ai cung xem; keo 'planning' chi host /
--       thanh vien (approved hoac requested) — nguoi ngoai bi chan.
-- Seed pattern copy tu roster_gate_test.sql (create_keo can pro host).
begin;
select plan(6);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000e1'), -- host (pro)
  ('00000000-0000-0000-0000-0000000000e2'), -- member approved + confirmed
  ('00000000-0000-0000-0000-0000000000e3'), -- requester (pending)
  ('00000000-0000-0000-0000-0000000000e4')  -- outsider
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000e1', 'Header Host', '1990-01-01'),
  ('00000000-0000-0000-0000-0000000000e2', 'Header Member', '1991-01-01'),
  ('00000000-0000-0000-0000-0000000000e3', 'Header Requester', '1992-01-01'),
  ('00000000-0000-0000-0000-0000000000e4', 'Header Outsider', '1993-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000e1', 'pro', 'promo')
  on conflict do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
create temp table _header_keo (id uuid);
insert into _header_keo
select public.create_keo(
  'Header KEO', 21.028000, 105.854000, 'Hoan Kiem HN',
  now() + interval '1 day', now() + interval '1 day 2 hours',
  4, null, null, array[]::text[], 'approval');

set local role postgres;
insert into public.keo_members (keo_id, user_id, role, join_status, confirmed) values
  ((select id from _header_keo), '00000000-0000-0000-0000-0000000000e2', 'member', 'approved', true),
  ((select id from _header_keo), '00000000-0000-0000-0000-0000000000e3', 'member', 'requested', false)
  on conflict (keo_id, user_id) do nothing;

-- (a) roster tra confirmed dung: e2 = true, host tu create_keo = true.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select is(
  (select confirmed from public.get_keo_roster((select id from _header_keo))
   where user_id = '00000000-0000-0000-0000-0000000000e2'),
  true, 'roster tra confirmed=true cho member da xac nhan');

-- keo dang 'open': nguoi ngoai van xem duoc header (ngang list_open_keos).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e4"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_keo_header((select id from _header_keo))),
  1, 'keo open: nguoi ngoai xem duoc header');

-- Chuyen keo sang 'planning' (roi discovery).
set local role postgres;
update public.keo set status = 'planning' where id = (select id from _header_keo);

-- (b) planning: host + member + requester deu thay; outsider bi chan.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_keo_header((select id from _header_keo))),
  1, 'keo planning: host thay header');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e2"}';
set local role authenticated;
select is(
  (select area_label from public.get_keo_header((select id from _header_keo))),
  'Hoan Kiem HN', 'keo planning: member thay header voi area_label dung');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e3"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_keo_header((select id from _header_keo))),
  1, 'keo planning: requester dang cho duyet van thay header');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e4"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_keo_header((select id from _header_keo))),
  0, 'keo planning: nguoi ngoai bi chan');

select * from finish();
rollback;
