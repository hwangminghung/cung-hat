-- Run with: supabase test db
-- [MATCH-AUDIT #1b] premium_filters phải mở khoá filter nâng cao THẬT, và
-- filter nâng cao phải bị khoá server-side với người chưa mua (fail-closed).
begin;
select plan(6);

-- M = caller, Y = 20 tuổi active hôm nay, O = 40 tuổi im ắng 3 ngày.
set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000a9'),
  ('00000000-0000-0000-0000-0000000000b9'),
  ('00000000-0000-0000-0000-0000000000c9')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, last_active) values
  ('00000000-0000-0000-0000-0000000000a9', 'M9', '1995-01-01', now()),
  ('00000000-0000-0000-0000-0000000000b9', 'Y-20-active', (current_date - interval '20 years')::date, now()),
  ('00000000-0000-0000-0000-0000000000c9', 'O-40-quiet', (current_date - interval '40 years')::date, now() - interval '3 days')
  on conflict (id) do update set dob = excluded.dob, last_active = excluded.last_active;
insert into public.user_locations (user_id, location)
select id, public.ST_SetSRID(public.ST_MakePoint(105.80, 21.00),4326)::public.geography
  from auth.users
 where id in ('00000000-0000-0000-0000-0000000000a9',
              '00000000-0000-0000-0000-0000000000b9',
              '00000000-0000-0000-0000-0000000000c9')
    on conflict (user_id) do update set location = excluded.location;
reset role;

-- 1) CHƯA mua: filter nâng cao bị chặn (từng loại tham số).
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000a9"}';
select throws_ok(
  $$ select * from public.get_discovery_candidates(20, 50, null, 25, null, false) $$,
  '23514', null, 'min_age không entitlement → entitlement_required');
select throws_ok(
  $$ select * from public.get_discovery_candidates(20, 50, null, null, null, true) $$,
  '23514', null, 'active_only không entitlement → entitlement_required');

-- 2) Không truyền filter nâng cao → deck thường vẫn chạy miễn phí như cũ.
select lives_ok(
  $$ select * from public.get_discovery_candidates(20, 50, null, null, null, false) $$,
  'deck thường (không filter nâng cao) vẫn miễn phí');
reset role;

-- 3) ĐÃ mua: lọc tuổi + lọc active hoạt động đúng.
set local role postgres;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000a9', 'premium_filters', 'promo')
  on conflict (user_id, feature) do nothing;
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000a9"}';
select is(
  (select count(*)::int from public.get_discovery_candidates(20, 50, null, 30, null, false)
    where display_name in ('Y-20-active','O-40-quiet')),
  1, 'min_age=30 loại người 20 tuổi, giữ người 40');
select is(
  (select display_name from public.get_discovery_candidates(20, 50, null, null, 30, false)
    where display_name in ('Y-20-active','O-40-quiet')),
  'Y-20-active', 'max_age=30 giữ người 20 tuổi, loại người 40');
select is(
  (select display_name from public.get_discovery_candidates(20, 50, null, null, null, true)
    where display_name in ('Y-20-active','O-40-quiet')),
  'Y-20-active', 'active_only chỉ giữ người hoạt động 24h');
reset role;

select * from finish();
rollback;
