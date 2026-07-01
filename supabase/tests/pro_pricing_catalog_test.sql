-- Run with: supabase test db
begin;
select plan(9);

set local role postgres;

select has_column('public', 'products', 'billing_period', 'products.billing_period exists');
select has_column('public', 'products', 'boost_credits', 'products.boost_credits exists');
select has_function('app_private', 'paid_pro_user_count', array[]::name[], 'paid_pro_user_count exists');
select has_function('public', 'get_store_products', array['text']::name[], 'get_store_products exists');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa01"}';
set local role authenticated;

select throws_ok(
  $$ select * from public.products limit 1 $$,
  '42501',
  null,
  'authenticated cannot read products directly'
);

select ok(
  exists (
    select 1
    from public.get_store_products('ios')
    where sku = 'pro_lifetime_launch_ios'
      and price_minor = 249000
      and badge = 'launch'
  ),
  'below 500 paid Pro users shows lifetime launch'
);

set local role postgres;
insert into auth.users (id)
select ('10000000-0000-0000-0000-' || lpad(gs::text, 12, '0'))::uuid
from generate_series(1, 500) gs
on conflict (id) do nothing;

insert into public.purchases (user_id, product_id, platform, store_txn_id, state)
select
  ('10000000-0000-0000-0000-' || lpad(gs::text, 12, '0'))::uuid,
  (select id from public.products where sku = 'pro_monthly_ios'),
  'ios',
  'pro-threshold-500-' || gs::text,
  'validated'
from generate_series(1, 500) gs
on conflict (platform, store_txn_id) do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa01"}';
set local role authenticated;

select ok(
  exists (
    select 1
    from public.get_store_products('ios')
    where sku = 'pro_lifetime_final_ios'
      and price_minor = 299000
      and badge = 'ending_soon'
  ),
  'at 500 paid Pro users shows lifetime final'
);

set local role postgres;
insert into auth.users (id)
select ('20000000-0000-0000-0000-' || lpad(gs::text, 12, '0'))::uuid
from generate_series(1, 1000) gs
on conflict (id) do nothing;

insert into public.purchases (user_id, product_id, platform, store_txn_id, state)
select
  ('20000000-0000-0000-0000-' || lpad(gs::text, 12, '0'))::uuid,
  (select id from public.products where sku = 'pro_yearly_ios'),
  'ios',
  'pro-threshold-1500-' || gs::text,
  'validated'
from generate_series(1, 1000) gs
on conflict (platform, store_txn_id) do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa01"}';
set local role authenticated;

select ok(
  not exists (
    select 1
    from public.get_store_products('ios')
    where billing_period = 'lifetime'
  ),
  'at 1500 paid Pro users hides lifetime'
);

select ok(
  exists (
    select 1
    from public.get_store_products('android')
    where sku = 'keo_boost_3_android'
      and boost_credits = 3
      and price_minor = 79000
  ),
  'boost 3-pack is returned for android'
);

select * from finish();
rollback;
