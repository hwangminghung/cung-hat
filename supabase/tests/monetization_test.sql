begin;
select plan(2);
select ok((select count(*) from public.products) >= 6, 'products seeded');
set local role authenticated;
select throws_ok($$ select public.who_liked_me() $$, '23514', null,
  'who_liked_me requires see_likes entitlement');
select * from finish();
rollback;
