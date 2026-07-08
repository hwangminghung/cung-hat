-- Run with: supabase test db
-- Proves 20260708150000: consume_service_rate_limit — dem dung, vuot -> false,
-- service_role duoc goi (positive grant, khong dua vao superuser bypass),
-- authenticated bi cam.
begin;
select plan(5);
set local role postgres;
insert into auth.users (id) values ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01') on conflict do nothing;
select ok(exists(select 1 from pg_proc where proname='consume_service_rate_limit'), 'ham ton tai');
select is(public.consume_service_rate_limit('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01','t',2,'1 day'), true, 'lan 1 ok');
select public.consume_service_rate_limit('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01','t',2,'1 day');
select is(public.consume_service_rate_limit('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01','t',2,'1 day'), false, 'vuot limit -> false');
-- Positive path duoi DUNG role edge dung (service_role) — bat regression neu ai do
-- drop dong grant: as postgres o tren van xanh (superuser bypass grant), con day thi fail.
-- Bucket 't2' rieng de khong dinh count cua bucket 't' o tren.
set local role service_role;
select is(public.consume_service_rate_limit('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01','t2',2,'1 day'), true, 'service_role duoc goi');
set local role authenticated;
select throws_ok($$ select public.consume_service_rate_limit('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01','t',2,'1 day') $$,
  '42501', null, 'authenticated khong duoc goi');
select * from finish();
rollback;
