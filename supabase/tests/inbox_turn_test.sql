-- Run with: supabase test db
-- Proves migration 20260706140000_inbox_turn_pill.sql: get_my_matches() exposes
-- last_sender_id so the inbox can render the "Den luot ban" / "Nhan truoc di" pill.
--   1) no messages yet -> last_sender_id is null (brand-new match).
--   2) after A sends -> A's own inbox row shows last_sender_id = A.
--   3) same message -> B's inbox row also shows last_sender_id = A (both sides
--      agree on who sent last).
begin;
select plan(3);

-- Fixed uuids. user_a < user_b required by matches' canonical-ordering CHECK.
-- A = 00000000-0000-0000-0000-0000000000e1
-- B = 00000000-0000-0000-0000-0000000000e2
-- match id = 00000000-0000-0000-0000-0000000000e9

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000e1'),
  ('00000000-0000-0000-0000-0000000000e2')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, age_verified) values
  ('00000000-0000-0000-0000-0000000000e1','Turn A','1990-01-01', true),
  ('00000000-0000-0000-0000-0000000000e2','Turn B','1990-01-01', true)
  on conflict (id) do nothing;
insert into public.matches (id, user_a, user_b, status) values
  ('00000000-0000-0000-0000-0000000000e9',
   '00000000-0000-0000-0000-0000000000e1',
   '00000000-0000-0000-0000-0000000000e2',
   'active')
  on conflict (id) do nothing;

-- 1) no messages yet -> A's inbox row has last_sender_id null.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select is(
  (select last_sender_id from public.get_my_matches()
     where match_id = '00000000-0000-0000-0000-0000000000e9'),
  null,
  'brand-new match: last_sender_id is null');
reset role;

-- (action, not an assertion) A sends a message via the real send_message RPC
-- (membership-checked path) so the next two assertions have a message to read.
set local role authenticated;
select public.send_message('00000000-0000-0000-0000-0000000000e9'::uuid, 'chao ban nhe');
reset role;

-- 2) A reads own inbox -> last_sender_id = A.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select is(
  (select last_sender_id from public.get_my_matches()
     where match_id = '00000000-0000-0000-0000-0000000000e9'),
  '00000000-0000-0000-0000-0000000000e1'::uuid,
  'after A sends: A''s own inbox row shows last_sender_id = A');
reset role;

-- 3) B reads inbox -> same last_sender_id = A (both sides see who sent last).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e2"}';
set local role authenticated;
select is(
  (select last_sender_id from public.get_my_matches()
     where match_id = '00000000-0000-0000-0000-0000000000e9'),
  '00000000-0000-0000-0000-0000000000e1'::uuid,
  'B''s inbox row also shows last_sender_id = A');
reset role;

select * from finish();
rollback;
