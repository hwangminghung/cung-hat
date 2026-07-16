-- Run with: supabase test db
-- P1-4: 2 push chu dong (migration 20260716120000_proactive_push.sql):
--   1) app_private.keo_tonight_recipients: chi keo bat dau trong 8h toi,
--      du member approved (host + member), khong tinh keo ngay mai/da huy.
--   2) app_private.new_singers_counts: dem profile MOI (7 ngay) quanh 50km
--      chung >=1 the loai, chi cho user active 14 ngay; nguong p_min.
--   3) notify_* chay duoc khi GUC fanout chua cau hinh (no-op HTTP).
--   4) 2 cron job da duoc dang ky.
-- Chay duoc tren DB local CO SAN DATA: cluster vi tri test dat o (0,0) giua
-- bien (khong dinh seed HN/HCM/TN) va moi assertion scope theo id cua test.
begin;
select plan(8);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000a1'), -- active cu, vpop (nguoi NHAN push new_singers)
  ('00000000-0000-0000-0000-0000000000b1'), -- profile MOI, gan, vpop (duoc dem)
  ('00000000-0000-0000-0000-0000000000b2'), -- profile MOI, gan, ballad (khac gu -> khong dem)
  ('00000000-0000-0000-0000-0000000000b3'), -- profile MOI, xa 150km, vpop (khong dem)
  ('00000000-0000-0000-0000-0000000000c1'), -- host keo toi nay
  ('00000000-0000-0000-0000-0000000000c2')  -- member approved keo toi nay
  on conflict (id) do nothing;

insert into public.profiles (id, display_name, dob, created_at, last_active) values
  ('00000000-0000-0000-0000-0000000000a1', 'Push A1', '1990-01-01', now() - interval '90 days', now()),
  ('00000000-0000-0000-0000-0000000000b1', 'Push B1', '1991-01-01', now() - interval '1 day', now()),
  ('00000000-0000-0000-0000-0000000000b2', 'Push B2', '1992-01-01', now() - interval '1 day', now()),
  ('00000000-0000-0000-0000-0000000000b3', 'Push B3', '1993-01-01', now() - interval '1 day', now()),
  ('00000000-0000-0000-0000-0000000000c1', 'Push C1', '1990-01-01', now() - interval '90 days', now()),
  ('00000000-0000-0000-0000-0000000000c2', 'Push C2', '1990-01-01', now() - interval '90 days', now())
  on conflict (id) do nothing;

insert into public.user_locations (user_id, location) values
  ('00000000-0000-0000-0000-0000000000a1', 'SRID=4326;POINT(0 0)'::public.geography),
  ('00000000-0000-0000-0000-0000000000b1', 'SRID=4326;POINT(0.01 0.01)'::public.geography),
  ('00000000-0000-0000-0000-0000000000b2', 'SRID=4326;POINT(0.02 0)'::public.geography),
  ('00000000-0000-0000-0000-0000000000b3', 'SRID=4326;POINT(1.2 1.2)'::public.geography)
  on conflict (user_id) do update set location = excluded.location;

insert into public.user_genres (user_id, genre_id) values
  ('00000000-0000-0000-0000-0000000000a1', 'vpop'),
  ('00000000-0000-0000-0000-0000000000b1', 'vpop'),
  ('00000000-0000-0000-0000-0000000000b2', 'ballad'),
  ('00000000-0000-0000-0000-0000000000b3', 'vpop')
  on conflict do nothing;

-- 1-3) new_singers_counts (scope theo user cua test — DB local co data that)
select is(
  (select count(*)::int from app_private.new_singers_counts(7, 1)
   where user_id in ('00000000-0000-0000-0000-0000000000a1',
                     '00000000-0000-0000-0000-0000000000b1',
                     '00000000-0000-0000-0000-0000000000b2',
                     '00000000-0000-0000-0000-0000000000b3')),
  1, 'trong cluster test chi A1 co nguoi hat moi hop gu quanh minh');
select is(
  (select cnt from app_private.new_singers_counts(7, 1)
   where user_id = '00000000-0000-0000-0000-0000000000a1'),
  1, 'A1 dem duoc dung 1 nguoi moi (B1 — B2 khac gu, B3 o xa)');
select is(
  (select count(*)::int from app_private.new_singers_counts(7, 3)
   where user_id in ('00000000-0000-0000-0000-0000000000a1',
                     '00000000-0000-0000-0000-0000000000b1',
                     '00000000-0000-0000-0000-0000000000b2',
                     '00000000-0000-0000-0000-0000000000b3')),
  0, 'nguong mac dinh >=3 -> chua du de push');

-- 4-6) keo_tonight_recipients: keo TOI NAY (..d1) vs NGAY MAI (..d2) vs
-- TOI NAY nhung cancelled (..d3) — scope theo 3 keo cua test.
insert into public.keo (id, host_id, title, area_geo, time_window_start, time_window_end, group_size_target, status) values
  ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000c1',
   'Keo toi nay', 'SRID=4326;POINT(0 0)'::public.geography,
   now() + interval '2 hours', now() + interval '4 hours', 4, 'planning'),
  ('00000000-0000-0000-0000-0000000000d2', '00000000-0000-0000-0000-0000000000c1',
   'Keo ngay mai', 'SRID=4326;POINT(0 0)'::public.geography,
   now() + interval '1 day', now() + interval '1 day 2 hours', 4, 'open'),
  ('00000000-0000-0000-0000-0000000000d3', '00000000-0000-0000-0000-0000000000c1',
   'Keo toi nay cancelled', 'SRID=4326;POINT(0 0)'::public.geography,
   now() + interval '2 hours', now() + interval '4 hours', 4, 'cancelled');

insert into public.keo_members (keo_id, user_id, role, join_status, confirmed) values
  ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000c1', 'host', 'approved', true),
  ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000c2', 'member', 'approved', false),
  ('00000000-0000-0000-0000-0000000000d2', '00000000-0000-0000-0000-0000000000c1', 'host', 'approved', true),
  ('00000000-0000-0000-0000-0000000000d3', '00000000-0000-0000-0000-0000000000c1', 'host', 'approved', true)
  on conflict (keo_id, user_id) do nothing;

select is(
  (select count(*)::int from app_private.keo_tonight_recipients()
   where keo_id in ('00000000-0000-0000-0000-0000000000d1',
                    '00000000-0000-0000-0000-0000000000d2',
                    '00000000-0000-0000-0000-0000000000d3')),
  1, 'trong 3 keo test, chi keo bat dau trong 8h toi va chua huy duoc nhac');
select is(
  (select keo_id from app_private.keo_tonight_recipients()
   where keo_id in ('00000000-0000-0000-0000-0000000000d1',
                    '00000000-0000-0000-0000-0000000000d2',
                    '00000000-0000-0000-0000-0000000000d3')),
  '00000000-0000-0000-0000-0000000000d1'::uuid, 'dung keo toi nay');
select is(
  (select array_length(user_ids, 1) from app_private.keo_tonight_recipients()
   where keo_id = '00000000-0000-0000-0000-0000000000d1'),
  2, 'du ca host lan member approved (chua confirm van duoc nhac)');

-- 7) notify_keo_tonight khong no khi app.fanout_url chua cau hinh; >=1 vi
-- DB local/CI co the co keo that trong 8h toi.
select ok(app_private.notify_keo_tonight() >= 1,
  'notify_keo_tonight xu ly it nhat keo test (GUC unset -> khong HTTP)');

-- 8) cron jobs dang ky du 2.
select is(
  (select count(*)::int from cron.job where jobname in ('keo-tonight-daily','new-singers-weekly')),
  2, 'du 2 cron job push chu dong');

select * from finish();
rollback;
