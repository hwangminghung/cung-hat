-- supabase/tests/unmatch_test.sql
-- Proves 20260708130000: unmatch RPC — thanh vien cat duoc, idempotent, nguoi ngoai bi chan.
begin;
select plan(4);
set local role postgres;
insert into auth.users (id) values
  ('dddddddd-dddd-4ddd-8ddd-dddddddddd01'),('dddddddd-dddd-4ddd-8ddd-dddddddddd02'),('dddddddd-dddd-4ddd-8ddd-dddddddddd03')
  on conflict do nothing;
insert into public.profiles (id, display_name, dob) values
  ('dddddddd-dddd-4ddd-8ddd-dddddddddd01','Um A','1990-01-01'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddd02','Um B','1991-01-01'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddd03','Um C','1992-01-01')
  on conflict do nothing;
insert into public.matches (user_a, user_b)
  values ('dddddddd-dddd-4ddd-8ddd-dddddddddd01','dddddddd-dddd-4ddd-8ddd-dddddddddd02');

select ok(exists(select 1 from pg_proc where proname='unmatch'), 'unmatch ton tai');

set local request.jwt.claims to '{"sub":"dddddddd-dddd-4ddd-8ddd-dddddddddd01","role":"authenticated"}';
set local role authenticated;
-- Temp table PHAI tao SAU khi doi role: temp table do role hien tai so huu,
-- tao no truoc luc con la postgres se lam "authenticated" bi permission
-- denied khi doc lai no ben duoi (tap phat hien qua chay that, khong phai
-- tu suy).
create temp table _um as
  select id from public.matches
  where user_a='dddddddd-dddd-4ddd-8ddd-dddddddddd01'
    and user_b='dddddddd-dddd-4ddd-8ddd-dddddddddd02';
select public.unmatch((select id from _um));
select is((select status from public.matches where id=(select id from _um)), 'unmatched', 'thanh vien unmatch duoc');
select lives_ok($$ select public.unmatch((select id from _um)) $$, 'goi lai idempotent');

set local request.jwt.claims to '{"sub":"dddddddd-dddd-4ddd-8ddd-dddddddddd03","role":"authenticated"}';
select throws_ok($$ select public.unmatch((select id from _um)) $$, '23514', 'not_in_match', 'nguoi ngoai bi chan');

select * from finish();
rollback;
