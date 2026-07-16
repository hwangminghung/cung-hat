-- Run with: supabase test db
-- P1-5 (product call 2026-07-16): DAO GATE tao keo — free duoc HOST 1 keo
-- active cung luc (status open/full/planning/confirmed, chua het gio, chua
-- xoa mem), Pro khong gioi han. Ap cho CA create_keo lan
-- create_auto_matched_keo (truoc day ca hai raise pro_required).
begin;
select plan(7);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000e1'), -- free host f1
  ('00000000-0000-0000-0000-0000000000e2'), -- free user f2 (auto-match, chua co keo)
  ('00000000-0000-0000-0000-0000000000e3')  -- pro host p1
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, age_verified) values
  ('00000000-0000-0000-0000-0000000000e1', 'Free Host', '1990-01-01', true),
  ('00000000-0000-0000-0000-0000000000e2', 'Free Auto', '1991-01-01', true),
  ('00000000-0000-0000-0000-0000000000e3', 'Pro Host', '1992-01-01', true)
  on conflict (id) do nothing;
insert into public.user_locations (user_id, location) values
  ('00000000-0000-0000-0000-0000000000e1', 'SRID=4326;POINT(0.5 0.5)'::public.geography),
  ('00000000-0000-0000-0000-0000000000e2', 'SRID=4326;POINT(0.5 0.5)'::public.geography)
  on conflict (user_id) do update set location = excluded.location;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000e3', 'pro', 'promo')
  on conflict do nothing;

-- 1) Free tao keo DAU TIEN: OK (truoc P1-5 cho nay raise pro_required).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
create temp table _f1_keos (id uuid);
insert into _f1_keos
select public.create_keo('Keo free 1', 0.5, 0.5, 'Test',
  now() + interval '1 day', now() + interval '1 day 2 hours',
  4, null, null, array[]::text[], 'approval');
select ok((select count(*) from _f1_keos) = 1, 'free tao duoc keo dau tien');

-- 2) Free tao keo THU HAI khi keo 1 con active -> free_host_limit.
select throws_like(
  $$select public.create_keo('Keo free 2', 0.5, 0.5, 'Test',
      now() + interval '2 days', now() + interval '2 days 2 hours',
      4, null, null, array[]::text[], 'approval')$$,
  '%free_host_limit%', 'free dang giu 1 keo active -> khong tao them duoc');

-- 3) Duong auto-match cung bi chan boi cung gate.
select throws_like(
  $$select public.create_auto_matched_keo('Keo auto', now() + interval '3 hours',
      now() + interval '5 hours', 4, array[]::text[], 'open')$$,
  '%free_host_limit%', 'auto-match cung tinh vao gioi han host cua free');

-- 4) Huy keo 1 -> free tao lai duoc (gioi han chi dem keo ACTIVE).
set local role postgres;
update public.keo set status = 'cancelled' where id in (select id from _f1_keos);
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
insert into _f1_keos
select public.create_keo('Keo free sau huy', 0.5, 0.5, 'Test',
  now() + interval '2 days', now() + interval '2 days 2 hours',
  4, null, null, array[]::text[], 'approval');
select ok((select count(*) from _f1_keos) = 2, 'huy keo cu -> free tao keo moi duoc');

-- 5) Keo da QUA GIO cung khong tinh: day keo 2 ve qua khu -> tao tiep OK.
set local role postgres;
update public.keo
   set time_window_start = now() - interval '2 days',
       time_window_end   = now() - interval '2 days' + interval '2 hours'
 where host_id = '00000000-0000-0000-0000-0000000000e1' and status <> 'cancelled';
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
insert into _f1_keos
select public.create_keo('Keo free sau khi keo cu het gio', 0.5, 0.5, 'Test',
  now() + interval '3 days', now() + interval '3 days 2 hours',
  4, null, null, array[]::text[], 'approval');
select ok((select count(*) from _f1_keos) = 3, 'keo het gio khong tinh vao gioi han');

-- 6) Free CHUA co keo nao: duong auto-match tao duoc (pro_required da go).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e2"}';
set local role authenticated;
select ok(
  public.create_auto_matched_keo('Keo auto f2', now() + interval '3 hours',
    now() + interval '5 hours', 3, array[]::text[], 'open') is not null,
  'free chua giu keo nao -> auto-match tao duoc');

-- 7) Pro khong gioi han: tao 2 keo lien tiep deu OK.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e3"}';
set local role authenticated;
create temp table _p1_keos (id uuid);
insert into _p1_keos
select public.create_keo('Keo pro 1', 0.5, 0.5, 'Test',
  now() + interval '1 day', now() + interval '1 day 2 hours',
  4, null, null, array[]::text[], 'approval');
insert into _p1_keos
select public.create_keo('Keo pro 2', 0.5, 0.5, 'Test',
  now() + interval '2 days', now() + interval '2 days 2 hours',
  4, null, null, array[]::text[], 'approval');
select ok((select count(*) from _p1_keos) = 2, 'pro tao nhieu keo khong gioi han');

select * from finish();
rollback;
