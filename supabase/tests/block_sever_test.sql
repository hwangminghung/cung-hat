-- supabase/tests/block_sever_test.sql
-- Proves 20260708120000: block unmatch cap dang active; record_swipe chan cap da block;
-- who_liked_me loc block 2 chieu; unblock->reswipe KHONG hoi sinh (ghost) match cu.
begin;
select plan(10);
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

-- 7) unblock -> reswipe: KHONG hoi sinh (ghost) match cu.
-- Seed swipe nguoc B->A 'like' de nhanh reciprocity chay that (match A-B von seed
-- truc tiep vao matches, khong co swipe row nao cua B) -- thieu no thi duong ghost
-- khong bao gio duoc thuc thi va test xanh gia tren code loi.
set local role postgres;
delete from public.blocks
 where blocker_id='cccccccc-cccc-4ccc-8ccc-cccccccccc01'
   and blocked_id='cccccccc-cccc-4ccc-8ccc-cccccccccc02';
insert into public.swipes (swiper_id, target_type, target_id, direction) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc02','user','cccccccc-cccc-4ccc-8ccc-cccccccccc01','like');
set local request.jwt.claims to '{"sub":"cccccccc-cccc-4ccc-8ccc-cccccccccc01","role":"authenticated"}';
set local role authenticated;
select is(
  public.record_swipe('cccccccc-cccc-4ccc-8ccc-cccccccccc02', 'like'),
  false, 'reswipe sau unblock: KHONG celebrate ghost match');

-- 8) row van unmatched sau reswipe (khong bi hoi sinh):
select is(
  (select status from public.matches
    where user_a='cccccccc-cccc-4ccc-8ccc-cccccccccc01' and user_b='cccccccc-cccc-4ccc-8ccc-cccccccccc02'),
  'unmatched', 'row van unmatched sau reswipe');

-- 9) send_message van bi chan tren thread da cat (in_match doi status=active;
--    0010_chat: raise not_a_member, errcode check_violation = 23514):
select throws_ok(
  $$ select public.send_message(
       (select id from public.matches
         where user_a='cccccccc-cccc-4ccc-8ccc-cccccccccc01'
           and user_b='cccccccc-cccc-4ccc-8ccc-cccccccccc02'), 'hi') $$,
  '23514', null, 'send_message van bi chan tren thread da cat');

-- 10) A-C: bo block roi swipe lai -- C da like A tu dau file, nen day la
--     nhanh insert-MOI (A-C chua tung co matches row nao, khac voi nhanh
--     "reswipe ghost" o assertion 7-8 tren cap A-B). Positive control cho
--     record_swipe: chung minh no VAN tao match that khi khong con block,
--     chu khong phai lam ham luon tra false/loi.
set local role postgres;
delete from public.blocks
 where blocker_id='cccccccc-cccc-4ccc-8ccc-cccccccccc01'
   and blocked_id='cccccccc-cccc-4ccc-8ccc-cccccccccc03';
set local request.jwt.claims to '{"sub":"cccccccc-cccc-4ccc-8ccc-cccccccccc01","role":"authenticated"}';
set local role authenticated;
select is(
  public.record_swipe('cccccccc-cccc-4ccc-8ccc-cccccccccc03', 'like'),
  true, 'fresh mutual match tra true (positive control)');

select * from finish();
rollback;
