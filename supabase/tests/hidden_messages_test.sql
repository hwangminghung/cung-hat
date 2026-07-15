-- Run with: supabase test db
-- Chung minh fix audit H1+L2:
--   * policy select messages loc hidden/soft_deleted_at (ca match lan keo)
--   * get_my_matches unread KHONG dem tin hidden
--   * mark_match_read tu choi non-member (23514), member van lives_ok
-- Harness jwt-claims gia giong chat_test.sql.
begin;
select plan(6);

-- A = 00000000-0000-0000-0000-0000000000a1 (user_a < user_b theo CHECK cua matches)
-- B = 00000000-0000-0000-0000-0000000000a2
-- C = 00000000-0000-0000-0000-0000000000c3 (nguoi ngoai)
-- match id = 00000000-0000-0000-0000-0000000000d4
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
-- A gui 2 tin: 1 tin thuong + 1 tin bi moderation an (hidden=true).
insert into public.messages (id, thread_type, thread_id, sender_id, body, hidden) values
  ('00000000-0000-0000-0000-0000000000e1', 'match',
   '00000000-0000-0000-0000-0000000000d4',
   '00000000-0000-0000-0000-0000000000a1', 'tin thuong', false),
  ('00000000-0000-0000-0000-0000000000e2', 'match',
   '00000000-0000-0000-0000-0000000000d4',
   '00000000-0000-0000-0000-0000000000a1', 'tin bi an', true);

-- 1) participant (B) chi thay tin KHONG hidden.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a2"}';
set local role authenticated;
select is((select count(*)::int from public.messages
           where thread_id='00000000-0000-0000-0000-0000000000d4'),
          1, 'participant khong thay tin hidden');

-- 2) policy keo cung loc hidden (kiem tra qual, khoi seed ca keo).
reset role;
set local role postgres;
select ok((select qual ilike '%hidden%' from pg_policies
           where schemaname='public' and tablename='messages'
             and policyname='messages_select_keo'),
          'messages_select_keo loc hidden');

-- 3) get_my_matches: unread cua B chi dem tin KHONG hidden (=1, khong phai 2).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a2"}';
set local role authenticated;
select is((select unread from public.get_my_matches() limit 1),
          1, 'unread khong dem tin hidden');

-- 4) mark_match_read: nguoi ngoai (C) bi tu choi 23514.
reset role;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000c3"}';
set local role authenticated;
select throws_ok(
  $$ select public.mark_match_read('00000000-0000-0000-0000-0000000000d4'::uuid) $$,
  '23514', null, 'non-member khong mark read duoc');

-- 5) member (A) mark read lives_ok.
reset role;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
set local role authenticated;
select lives_ok(
  $$ select public.mark_match_read('00000000-0000-0000-0000-0000000000d4'::uuid) $$,
  'member mark read lives_ok');

-- 6) row message_reads da ghi cho A.
reset role;
set local role postgres;
select is((select count(*)::int from public.message_reads
           where thread_id='00000000-0000-0000-0000-0000000000d4'
             and user_id='00000000-0000-0000-0000-0000000000a1'),
          1, 'message_reads row ghi cho A');

reset role;
select * from finish();
rollback;
