-- Run with: supabase test db
-- Proves the chat security crux of migration 0010:
--   * send_message exists
--   * a non-member's send is rejected by the membership CHECK (23514)
--   * app_private.in_match truth-table: TRUE for a member, FALSE for a non-member
--   * a member can actually send (lives_ok) and the message row is durably inserted
--     (the AFTER INSERT broadcast trigger is best-effort, so realtime not being
--      fully wired in the test tx must NOT fail the send).
--
-- We fake an authenticated user via JWT claims (request.jwt.claims->>'sub') so
-- auth.uid() resolves to a seeded uuid, mirroring consent_gate_test.sql.
begin;
select plan(6);

-- Fixed uuids. user_a < user_b is required by matches' canonical-ordering CHECK,
-- so A (...a1) < B (...a2); C (...c3) is the non-member third party.
-- A = 00000000-0000-0000-0000-0000000000a1
-- B = 00000000-0000-0000-0000-0000000000a2
-- C = 00000000-0000-0000-0000-0000000000c3
-- match id = 00000000-0000-0000-0000-0000000000d4

-- matches/messages FK to auth.users(id); seed as owner (postgres bypasses RLS/priv).
set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000a1'),
  ('00000000-0000-0000-0000-0000000000a2'),
  ('00000000-0000-0000-0000-0000000000c3')
  on conflict (id) do nothing;
insert into public.matches (id, user_a, user_b, status) values
  ('00000000-0000-0000-0000-0000000000d4',
   '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000a2',
   'active')
  on conflict (id) do nothing;

-- 1) send_message exists.
select ok(exists(select 1 from pg_proc where proname='send_message'), 'send_message exists');

-- 2) non-member send -> membership CHECK rejects with 23514.
-- (no jwt sub set yet, so auth.uid() is null -> not a member)
set local role authenticated;
select throws_ok(
  $$ select public.send_message('00000000-0000-0000-0000-000000000000'::uuid, 'hi') $$,
  '23514', null, 'non-member cannot send');
reset role;

-- 3) in_match TRUE for a member (A).
-- app_private is not granted to `authenticated` (callers reach it only via
-- definer public.* RPCs), so call it directly as owner. auth.uid() reads the
-- request.jwt.claims GUC, which resolves regardless of the active role.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
select is(app_private.in_match('00000000-0000-0000-0000-0000000000d4'), true,
  'member (A) is in match');

-- 4) in_match FALSE for a non-member (C).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000c3"}';
select is(app_private.in_match('00000000-0000-0000-0000-0000000000d4'), false,
  'non-member (C) is not in match');

-- 5) member-send SUCCESS: as A, send lives_ok (broadcast trigger is best-effort).
-- send_message is a definer RPC granted to authenticated; call it as authenticated.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
set local role authenticated;
select lives_ok(
  $$ select public.send_message('00000000-0000-0000-0000-0000000000d4'::uuid, 'xin chào') $$,
  'member (A) send lives_ok');

-- 6) the message row was durably inserted for that thread.
select is((select count(*)::int from public.messages
           where thread_id='00000000-0000-0000-0000-0000000000d4'),
          1, 'message row inserted');

reset role;
select * from finish();
rollback;
