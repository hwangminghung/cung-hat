-- Run with: supabase test db
-- [MATCH-AUDIT #4a] who_liked_me phải loại người mình đã vuốt (pass).
begin;
select plan(2);

-- M = chủ tài khoản (có see_likes), L1 = liker chưa bị đụng, L2 = liker mình ĐÃ pass.
set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000a8'),
  ('00000000-0000-0000-0000-0000000000b8'),
  ('00000000-0000-0000-0000-0000000000c8')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name) values
  ('00000000-0000-0000-0000-0000000000a8', 'M8'),
  ('00000000-0000-0000-0000-0000000000b8', 'L1-cho'),
  ('00000000-0000-0000-0000-0000000000c8', 'L2-passed')
  on conflict (id) do nothing;
insert into public.user_locations (user_id, location)
select id, public.ST_SetSRID(public.ST_MakePoint(105.80, 21.00),4326)::public.geography
  from auth.users
 where id in ('00000000-0000-0000-0000-0000000000a8',
              '00000000-0000-0000-0000-0000000000b8',
              '00000000-0000-0000-0000-0000000000c8')
    on conflict (user_id) do update set location = excluded.location;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000a8', 'see_likes', 'promo')
  on conflict (user_id, feature) do nothing;
-- Cả hai liker đều đã like M; M đã PASS L2.
insert into public.swipes (swiper_id, target_type, target_id, direction) values
  ('00000000-0000-0000-0000-0000000000b8', 'user', '00000000-0000-0000-0000-0000000000a8', 'like'),
  ('00000000-0000-0000-0000-0000000000c8', 'user', '00000000-0000-0000-0000-0000000000a8', 'like'),
  ('00000000-0000-0000-0000-0000000000a8', 'user', '00000000-0000-0000-0000-0000000000c8', 'pass')
  on conflict do nothing;
reset role;

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000a8"}';
select ok(
  exists (select 1 from public.who_liked_me(20) where display_name = 'L1-cho'),
  'liker mình chưa đụng tới vẫn hiện');
select ok(
  not exists (select 1 from public.who_liked_me(20) where display_name = 'L2-passed'),
  'liker mình ĐÃ pass không còn hiện trong danh sách trả phí');
reset role;

select * from finish();
rollback;
