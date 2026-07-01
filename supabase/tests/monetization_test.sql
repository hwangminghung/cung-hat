begin;
select plan(3);
select ok((select count(*) from public.products) >= 14, 'products seeded');
select ok(
  exists (select 1 from public.products where sku='pro_monthly_ios' and price_minor=79000),
  'Pro monthly seeded'
);
set local role authenticated;
select throws_ok($$ select public.who_liked_me() $$, '23514', null,
  'who_liked_me requires see_likes entitlement');
select * from finish();
rollback;
