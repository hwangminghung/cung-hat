begin;
select plan(1);
-- With no consents granted for the (nonexistent) anon user, upsert_my_taste must reject.
select throws_ok(
  $$ select public.upsert_my_taste(array[]::text[], array[]::text[], array[]::text[]) $$,
  '23514', null, 'upsert_my_taste requires matching+cross_border consent');
select * from finish();
rollback;
