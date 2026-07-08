-- Run with: supabase test db
-- Proves migration 20260708140000: get_keo_roster gates 'requested' rows to the
-- keo's host only ([A-I3] — anyone could otherwise enumerate any keo's roster,
-- INCLUDING pending join-requesters). Everyone else — approved members and
-- outsiders alike — sees only 'approved' rows (roster preview stays a product
-- feature; only the pending-requester identities are gated). Seed pattern
-- copied from keo_midpoint_test.sql (create_keo needs a pro host).
begin;
select plan(3);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000f1'), -- host (pro)
  ('00000000-0000-0000-0000-0000000000f2'), -- member, approved
  ('00000000-0000-0000-0000-0000000000f3'), -- member, requested (pending)
  ('00000000-0000-0000-0000-0000000000f4')  -- outsider (not in keo_members at all)
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000f1', 'Roster Host', '1990-01-01'),
  ('00000000-0000-0000-0000-0000000000f2', 'Roster Approved', '1991-01-01'),
  ('00000000-0000-0000-0000-0000000000f3', 'Roster Requester', '1992-01-01'),
  ('00000000-0000-0000-0000-0000000000f4', 'Roster Outsider', '1993-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000f1', 'pro', 'promo')
  on conflict do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f1"}';
set local role authenticated;
create temp table _roster_keo (id uuid);
insert into _roster_keo
select public.create_keo(
  'Roster KEO', 21.028000, 105.854000, 'HN',
  now() + interval '1 day', now() + interval '1 day 2 hours',
  4, null, null, array[]::text[], 'approval');

-- Seed one approved+confirmed member and one still-pending ('requested') member
-- directly (host row already exists as approved+confirmed via create_keo).
set local role postgres;
insert into public.keo_members (keo_id, user_id, role, join_status, confirmed) values
  ((select id from _roster_keo), '00000000-0000-0000-0000-0000000000f2', 'member', 'approved', true),
  ((select id from _roster_keo), '00000000-0000-0000-0000-0000000000f3', 'member', 'requested', false)
  on conflict (keo_id, user_id) do nothing;

-- 1) Host thay ca 3 hang: host (approved) + f2 (approved) + f3 (requested).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f1"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_keo_roster((select id from _roster_keo))),
  3, 'host thay ca 3 hang (host + approved + requested)');

-- 2) Member da approved (f2) chi thay 2 hang (host + f2) — KHONG thay f3 (requested).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f2"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_keo_roster((select id from _roster_keo))),
  2, 'member approved chi thay 2 hang (khong thay requested)');

-- 3) Nguoi ngoai (f4, khong o trong keo_members) chi thay 2 hang (host + f2 approved).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f4"}';
set local role authenticated;
select is(
  (select count(*)::int from public.get_keo_roster((select id from _roster_keo))),
  2, 'nguoi ngoai chi thay 2 hang (chi approved + host)');

select * from finish();
rollback;
