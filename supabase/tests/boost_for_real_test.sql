-- Run with: supabase test db
-- [MATCH-AUDIT #1a] Boost 49k phải làm được điều đã bán.
-- Trước migration 20260801130000: activate_boost đòi Pro (người mua boost lẻ
-- bị pro_required trên chính thứ vừa trả tiền) và list_open_keos không có
-- term boost nào (chức năng "đẩy kèo lên top" không tồn tại).
begin;
select plan(5);

-- B = người MUA BOOST LẺ (không Pro), N = host thường, V = viewer.
set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000b7'),
  ('00000000-0000-0000-0000-0000000000c7'),
  ('00000000-0000-0000-0000-0000000000d7')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name) values
  ('00000000-0000-0000-0000-0000000000b7', 'BoostHost'),
  ('00000000-0000-0000-0000-0000000000c7', 'PlainHost'),
  ('00000000-0000-0000-0000-0000000000d7', 'Viewer')
  on conflict (id) do nothing;
insert into public.user_locations (user_id, location) values
  ('00000000-0000-0000-0000-0000000000d7',
   public.ST_SetSRID(public.ST_MakePoint(105.800, 21.000),4326)::public.geography)
  on conflict (user_id) do update set location = excluded.location;
-- B có entitlement boost còn hạn (đúng thứ validate-iap cấp khi mua).
insert into public.entitlements (user_id, feature, source, active_until) values
  ('00000000-0000-0000-0000-0000000000b7', 'boost', 'play_billing', now() + interval '24 hours')
  on conflict (user_id, feature) do update set active_until = excluded.active_until;
-- Kèo của N bắt đầu SỚM HƠN kèo của B — theo sắp xếp cũ (thuần giờ) N đứng
-- trước; "lên top" nghĩa là B phải vượt N.
insert into public.keo (id, host_id, title, area_geo, time_window_start, time_window_end,
                        group_size_target, join_mode) values
  ('00000000-0000-0000-0000-0000000000f7',
   '00000000-0000-0000-0000-0000000000c7', 'Keo thuong som',
   public.ST_SetSRID(public.ST_MakePoint(105.801, 21.001),4326)::public.geography,
   now() + interval '1 hour', now() + interval '3 hours', 4, 'open'),
  ('00000000-0000-0000-0000-0000000000f8',
   '00000000-0000-0000-0000-0000000000b7', 'Keo boost muon',
   public.ST_SetSRID(public.ST_MakePoint(105.801, 21.001),4326)::public.geography,
   now() + interval '2 hours', now() + interval '4 hours', 4, 'open');
insert into public.keo_members (keo_id, user_id, role, join_status, confirmed) values
  ('00000000-0000-0000-0000-0000000000f7', '00000000-0000-0000-0000-0000000000c7', 'host', 'approved', true),
  ('00000000-0000-0000-0000-0000000000f8', '00000000-0000-0000-0000-0000000000b7', 'host', 'approved', true);
reset role;

-- 1) Kèo của host có boost đứng TRÊN kèo thường dù bắt đầu muộn hơn.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000d7"}';
select is(
  (select array_agg(title order by rn)
     from (select title, row_number() over () as rn
             from public.list_open_keos(10, 50)
            where title in ('Keo thuong som','Keo boost muon')) t),
  array['Keo boost muon','Keo thuong som'],
  'kèo của host có boost lên đầu bảng');
reset role;

-- 2) Người mua boost lẻ (KHÔNG Pro) kích hoạt được boost deck Đôi.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000b7"}';
select lives_ok(
  $$ select public.activate_boost() $$,
  'mua boost lẻ → activate_boost sống (hết thời pro_required)');
reset role;

-- 3) Người KHÔNG mua gì bị chặn với mã boost_required (không phải pro_required).
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000c7"}';
select throws_ok(
  $$ select public.activate_boost() $$,
  '23514', null, 'chưa mua boost → raise');
reset role;

-- 4) get_my_entitlements lọc entitlement hết hạn.
set local role postgres;
insert into public.entitlements (user_id, feature, source, active_until) values
  ('00000000-0000-0000-0000-0000000000c7', 'boost', 'play_billing', now() - interval '1 hour')
  on conflict (user_id, feature) do update set active_until = excluded.active_until;
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000c7"}';
select is(
  (select count(*)::int from public.get_my_entitlements() where feature='boost'),
  0, 'boost hết hạn không còn xuất hiện trong get_my_entitlements');
reset role;

-- 5) Kèo của host boost HẾT HẠN không được ưu tiên: sau khi entitlement của B
--    hết hạn, kèo sớm hơn của N phải đứng trước trở lại.
set local role postgres;
update public.entitlements set active_until = now() - interval '1 minute'
 where user_id = '00000000-0000-0000-0000-0000000000b7' and feature = 'boost';
reset role;
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000d7"}';
select is(
  (select array_agg(title order by rn)
     from (select title, row_number() over () as rn
             from public.list_open_keos(10, 50)
            where title in ('Keo thuong som','Keo boost muon')) t),
  array['Keo thuong som','Keo boost muon'],
  'boost hết hạn → trở về xếp theo giờ');
reset role;

select * from finish();
rollback;
