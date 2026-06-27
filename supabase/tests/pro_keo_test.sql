-- Run with: supabase test db
-- Proves migration 0024: Pro superset, create_keo Pro-gate, free 1-active-keo cap,
-- open-mode auto-approve.
begin;
select plan(10);

set local role postgres;
-- Users: pro host, free A, free B, free C (approval-mode test), see_likes-only user (superset no-leak).
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000a1'),
  ('00000000-0000-0000-0000-0000000000b1'),
  ('00000000-0000-0000-0000-0000000000b2'),
  ('00000000-0000-0000-0000-0000000000b3'),
  ('00000000-0000-0000-0000-0000000000c1')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000a1','Pro Host','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000b1','Free A','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000b2','Free B','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000b3','Free C','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000c1','SeeLikes Only','1990-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000a1','pro','promo'),
  ('00000000-0000-0000-0000-0000000000c1','see_likes','promo')
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

-- Case 6: approval-mode join -> join_status='requested' (NOT auto-approved).
-- Pro host creates an 'approval' keo; fresh free C requests -> stays 'requested'.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
set local role authenticated;
create temp table _ta (keo uuid);
insert into _ta select public.create_keo('Approval KEO',21.0,105.8,'HN',now()+interval '1 day',now()+interval '1 day 2 hours',5,null,null,array[]::text[],'approval');
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b3"}';
set local role authenticated;
select public.request_join_keo((select keo from _ta));
set local role postgres;
select is(
  (select join_status from public.keo_members m, _ta t where m.keo_id=t.keo and m.user_id='00000000-0000-0000-0000-0000000000b3'),
  'requested', 'approval-mode join stays requested');

-- Case 7: re-join after leaving — a member who left an active keo is no longer counted
-- by the free cap, so B (capped in Case 5) can leave Open KEO then join _t2's keo -> lives_ok.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000b2"}';
set local role authenticated;
select public.leave_keo((select keo from _t));
select lives_ok(
  $$ select public.request_join_keo((select keo from _t2)) $$,
  'free user can join after leaving prior keo (cap frees up)');

-- Case 8 & 9: superset no-leak — see_likes-only user is NOT pro and cannot reach 'boost'.
-- app_private.* called as owner with the JWT claim set.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000c1"}';
select ok(not app_private.has_entitlement('boost'), 'see_likes-only user lacks boost (no superset leak)');
select ok(not app_private.is_pro(), 'see_likes-only user is not pro');

select * from finish();
rollback;
