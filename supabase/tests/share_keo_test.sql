-- Run with: supabase test db
-- Covers migration 20260707110000_share_keo.sql: create_keo_share_link (host or
-- approved member only, mirrors share_plans 0016) + resolve_share_keo (anon-readable
-- sanitized composite, mirrors 0023 resolve_share_plan).
-- plan(7): the 5 conceptual cases from the plan doc, with case 4 ("resolve token
-- correctly -> title match + expired=false + slots_filled correct") split into 3
-- separate `is()` subtests for clearer failure messages (same pattern photos_test.sql
-- uses for its multi-part cases).
begin;
select plan(7);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000e1'), -- pro host
  ('00000000-0000-0000-0000-0000000000e2'), -- approved member
  ('00000000-0000-0000-0000-0000000000e3')  -- bystander
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000e1','Share Host','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000e2','Share Member','1990-01-01'),
  ('00000000-0000-0000-0000-0000000000e3','Share Bystander','1990-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000e1','pro','promo')
  on conflict do nothing;

-- Pro host creates an approval-mode keo (create_keo is Pro-gated as of 0024).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
create temp table _share_keo (id uuid);
insert into _share_keo select public.create_keo('Share KEO',21.0,105.8,'HN',
  now()+interval '1 day', now()+interval '1 day 2 hours', 4, null, null,
  array['vpop']::text[], 'approval');

-- Member requests to join, then host approves -> join_status='approved'.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e2"}';
set local role authenticated;
select public.request_join_keo((select id from _share_keo));
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select public.approve_join((select id from _share_keo), '00000000-0000-0000-0000-0000000000e2');

-- 1) Host creates a share link. share_keos has RLS enabled with NO client policies
--    (by design — see migration comment), so the token can only be read back through
--    a temp table capturing the RPC's own return value, not by querying share_keos
--    directly as `authenticated` afterwards (that would see zero rows under RLS).
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
create temp table _host_tok (tok text);
select lives_ok(
  $$ insert into _host_tok select public.create_keo_share_link((select id from _share_keo)) $$,
  'host can create a share link for their own keo');

-- 2) Approved member also creates a link -> total 2 rows in share_keos for this keo.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e2"}';
set local role authenticated;
select public.create_keo_share_link((select id from _share_keo));
set local role postgres;
select is(
  (select count(*)::int from public.share_keos where keo_id = (select id from _share_keo)),
  2,
  'host + approved member each produced one share_keos row');

-- 3) Bystander (not host, not approved member) -> check_violation (23514, not_keo_member).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e3"}';
set local role authenticated;
select throws_ok(
  $$ select public.create_keo_share_link((select id from _share_keo)) $$,
  '23514', 'not_keo_member', 'bystander is blocked from creating a share link');

-- 4) Resolve the captured host token (as authenticated bystander — resolve_share_keo is
--    also granted to anon, but pgTAP's own assertion functions are not executable under
--    `role anon` so we exercise the identical code path via a granted authenticated role
--    instead; the RPC itself does not gate on caller identity). _host_tok is a temp
--    table from case 1 and stays readable across role switches within this session.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e3"}';
set local role authenticated;
select is(
  (select (public.resolve_share_keo((select tok from _host_tok))).title),
  'Share KEO',
  'resolve_share_keo returns the correct title for a valid token');
select is(
  (select (public.resolve_share_keo((select tok from _host_tok))).expired),
  false,
  'resolve_share_keo reports expired=false for a freshly created token');
select is(
  (select (public.resolve_share_keo((select tok from _host_tok))).slots_filled),
  2,
  'resolve_share_keo counts approved members (host + approved member = 2)');

-- 5) Bogus token -> no matching row -> composite is a NULL row (all fields null).
select is(
  (select (public.resolve_share_keo('deadbeef')).keo_id),
  null,
  'resolve_share_keo returns a null composite for a bogus token');

select * from finish();
rollback;
