-- Run with: supabase test db
-- Covers migration 20260706120000_keo_card_is_mine.sql: list_open_keos.is_mine
-- flags a keo as "mine" when the caller is the host OR has requested/approved
-- membership; a bystander sees is_mine=false.
begin;
select plan(3);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000d1'), -- host
  ('00000000-0000-0000-0000-0000000000d2'), -- requested member
  ('00000000-0000-0000-0000-0000000000d3')  -- bystander
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000d1','Mine Host','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000d2','Mine Requester','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000d3','Mine Bystander','1990-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000d1','pro','promo')
  on conflict do nothing;
-- All three co-located in HN so list_open_keos' ST_DWithin radius filter passes.
insert into public.user_locations (user_id, location, area_label) values
  ('00000000-0000-0000-0000-0000000000d1', public.ST_SetSRID(public.ST_MakePoint(105.800, 21.000), 4326)::public.geography, 'HN'),
  ('00000000-0000-0000-0000-0000000000d2', public.ST_SetSRID(public.ST_MakePoint(105.801, 21.001), 4326)::public.geography, 'HN'),
  ('00000000-0000-0000-0000-0000000000d3', public.ST_SetSRID(public.ST_MakePoint(105.802, 21.002), 4326)::public.geography, 'HN')
  on conflict (user_id) do update
  set location = excluded.location, area_label = excluded.area_label, updated_at = now();

-- Host (pro) creates an approval-mode keo.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d1"}';
set local role authenticated;
create temp table _mine_keo (id uuid);
insert into _mine_keo select public.create_keo('Mine KEO',21.0,105.8,'HN',now()+interval '1 day',now()+interval '1 day 2 hours',4,null,null,array[]::text[],'approval');

-- Requester (free, no pro needed for request_join_keo) requests to join.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d2"}';
set local role authenticated;
select public.request_join_keo((select id from _mine_keo));

-- Case 1: host lists board -> their own keo has is_mine=true.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d1"}';
set local role authenticated;
select is(
  (select is_mine from public.list_open_keos(30,50) where id = (select id from _mine_keo)),
  true,
  'host sees is_mine=true for their own keo');

-- Case 2: requester (join_status=requested) sees is_mine=true.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d2"}';
set local role authenticated;
select is(
  (select is_mine from public.list_open_keos(30,50) where id = (select id from _mine_keo)),
  true,
  'requester sees is_mine=true for a keo they requested to join');

-- Case 3: bystander (no membership, not host) sees is_mine=false.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d3"}';
set local role authenticated;
select is(
  (select is_mine from public.list_open_keos(30,50) where id = (select id from _mine_keo)),
  false,
  'bystander sees is_mine=false');

select * from finish();
rollback;
