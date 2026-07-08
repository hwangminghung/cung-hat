-- supabase/tests/block_sever_test.sql
-- Proves 20260708120000: block unmatch cap dang active; record_swipe chan cap da block;
-- who_liked_me loc block 2 chieu.
begin;
select plan(6);
set local role postgres;
insert into auth.users (id) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc02'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc03')
  on conflict do nothing;
insert into public.profiles (id, display_name, dob) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01','Blk A','1990-01-01'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc02','Blk B','1991-01-01'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc03','Blk C','1992-01-01')
  on conflict do nothing;
-- A & B match san:
insert into public.matches (user_a, user_b) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01','cccccccc-cccc-4ccc-8ccc-cccccccccc02');
-- C like A (cho who_liked_me):
insert into public.swipes (swiper_id, target_type, target_id, direction) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc03','user','cccccccc-cccc-4ccc-8ccc-cccccccccc01','like');
-- A co see_likes + vi tri (who_liked_me can):
insert into public.entitlements (user_id, feature, source) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01','see_likes','promo');
insert into public.user_locations (user_id, location) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01', ST_SetSRID(ST_MakePoint(105.85,21.02),4326)::geography),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc03', ST_SetSRID(ST_MakePoint(105.86,21.03),4326)::geography);

set local request.jwt.claims to '{"sub":"cccccccc-cccc-4ccc-8ccc-cccccccccc01","role":"authenticated"}';
set local role authenticated;

-- 1) truoc block: who_liked_me co C:
select is((select count(*)::int from public.who_liked_me(20)), 1, 'truoc block: C hien trong who_liked_me');

-- 2) A block B -> match A-B unmatched:
select public.block_user('cccccccc-cccc-4ccc-8ccc-cccccccccc02');
select is(
  (select status from public.matches
    where user_a='cccccccc-cccc-4ccc-8ccc-cccccccccc01' and user_b='cccccccc-cccc-4ccc-8ccc-cccccccccc02'),
  'unmatched', 'block cat match dang active');

-- 3) A swipe B sau block -> blocked_pair:
select throws_ok(
  $$ select public.record_swipe('cccccccc-cccc-4ccc-8ccc-cccccccccc02', 'like') $$,
  '23514', 'blocked_pair', 'record_swipe chan cap da block');

-- 4) chieu nguoc: B swipe A cung bi chan:
set local request.jwt.claims to '{"sub":"cccccccc-cccc-4ccc-8ccc-cccccccccc02","role":"authenticated"}';
select throws_ok(
  $$ select public.record_swipe('cccccccc-cccc-4ccc-8ccc-cccccccccc01', 'like') $$,
  '23514', 'blocked_pair', 'chieu nguoc cung bi chan');

-- 5) A block C -> who_liked_me khong con C:
set local request.jwt.claims to '{"sub":"cccccccc-cccc-4ccc-8ccc-cccccccccc01","role":"authenticated"}';
select public.block_user('cccccccc-cccc-4ccc-8ccc-cccccccccc03');
select is((select count(*)::int from public.who_liked_me(20)), 0, 'who_liked_me loc nguoi da block');

-- 6) block van idempotent (goi lai khong loi):
select lives_ok($$ select public.block_user('cccccccc-cccc-4ccc-8ccc-cccccccccc03') $$, 'block idempotent');

select * from finish();
rollback;
