-- Run with: supabase test db
-- Proves migration 0024: Pro superset, create_keo Pro-gate, free 1-active-keo cap,
-- open-mode auto-approve.
begin;
select plan(6);

set local role postgres;
-- Three users: pro host, free user A, free user B.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000a1'),
  ('00000000-0000-0000-0000-0000000000b1'),
  ('00000000-0000-0000-0000-0000000000b2')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000a1','Pro Host','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000b1','Free A','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000b2','Free B','1990-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000a1','pro','promo')
  on conflict do nothing;

-- Case 1: has_entitlement superset — pro user has see_likes without owning it.
-- app_private is not granted to `authenticated` (callers reach it only via definer
-- public.* RPCs), so call it directly as owner. auth.uid() reads the request.jwt.claims
-- GUC, which resolves regardless of the active role.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
select ok(app_private.has_entitlement('see_likes'), 'pro user has see_likes via superset');

-- Case 2: free user cannot create keo.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b1"}';
set local role authenticated;
select throws_ok(
  $$ select public.create_keo('K',21.0,105.8,'HN',now()+interval '1 day',now()+interval '1 day 2 hours',4,null,null,array[]::text[],'open') $$,
  '23514', null, 'free user blocked from create_keo');

-- Case 3: pro user creates an OPEN keo (store the id in a temp table for later cases).
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
set local role authenticated;
create temp table _t (keo uuid);
insert into _t select public.create_keo('Open KEO',21.0,105.8,'HN',now()+interval '1 day',now()+interval '1 day 2 hours',5,null,null,array[]::text[],'open');
-- public.* tables are not granted to `authenticated`; read back the stored value as owner.
set local role postgres;
select is((select join_mode from public.keo k join _t t on t.keo=k.id), 'open', 'pro create_keo stores join_mode=open');

-- Case 4: free B joins the OPEN keo -> auto-approved.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b2"}';
set local role authenticated;
select lives_ok(
  $$ select public.request_join_keo((select keo from _t)) $$,
  'free user can request-join open keo');
-- Read back the membership row as owner (public.* not granted to authenticated).
set local role postgres;
select is(
  (select join_status from public.keo_members m, _t t where m.keo_id=t.keo and m.user_id='00000000-0000-0000-0000-0000000000b2'),
  'approved', 'open-mode join is auto-approved');

-- Case 5: free B (now in 1 active keo) is blocked from a SECOND keo.
-- Pro host makes a second open keo; B already has 1 active -> free_join_limit.
-- Track the second keo's id explicitly: relying on uuid ordering could pick the keo
-- B already joined (which would auto-approve via on-conflict, not trip the cap).
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
set local role authenticated;
create temp table _t2 (keo uuid);
insert into _t2 select public.create_keo('Open KEO 2',21.0,105.8,'HN',now()+interval '1 day',now()+interval '1 day 2 hours',5,null,null,array[]::text[],'open');
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b2"}';
set local role authenticated;
select throws_ok(
  $$ select public.request_join_keo((select keo from _t2)) $$,
  '23514', null, 'free user capped at 1 active keo');

select * from finish();
rollback;
