begin;
select plan(2);
select throws_ok(
  $$ select public.upsert_my_profile('X', 'X Y', current_date, null, 'vi') $$,
  '23514', null, 'under-18 DOB is rejected');
select ok(
  exists(select 1 from pg_proc where proname='upsert_my_taste'),
  'upsert_my_taste exists');
select * from finish();
rollback;
