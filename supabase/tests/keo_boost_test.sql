-- Run with: supabase test db
begin;
select plan(18);

set local role postgres;

insert into auth.users (id) values
  ('30000000-0000-0000-0000-000000000001'),
  ('30000000-0000-0000-0000-000000000002')
on conflict (id) do nothing;

insert into public.profiles (id, display_name, dob) values
  ('30000000-0000-0000-0000-000000000001','Boost Host','1990-01-01'),
  ('30000000-0000-0000-0000-000000000002','Other User','1990-01-01')
on conflict (id) do nothing;

select has_table('public', 'keo_boost_credits', 'keo_boost_credits exists');
select has_table('public', 'keo_boosts', 'keo_boosts exists');
select has_function('public', 'record_validated_purchase', array['uuid','uuid','text','text','text']::name[], 'record_validated_purchase exists');
select has_function('public', 'get_my_boost_credits', array[]::name[], 'get_my_boost_credits exists');

select public.record_validated_purchase(
  '30000000-0000-0000-0000-000000000001',
  (select id from public.products where sku='keo_boost_3_ios'),
  'ios',
  'boost-pack-txn-1',
  'stored'
);

select is(
  (select count(*)::int from public.keo_boost_credits where user_id='30000000-0000-0000-0000-000000000001' and status='available'),
  3,
  'boost 3-pack creates three available credits'
);

select public.record_validated_purchase(
  '30000000-0000-0000-0000-000000000001',
  (select id from public.products where sku='keo_boost_3_ios'),
  'ios',
  'boost-pack-txn-1',
  'stored'
);

select is(
  (select count(*)::int from public.keo_boost_credits where user_id='30000000-0000-0000-0000-000000000001' and status='available'),
  3,
  'delivery retry does not duplicate boost credits'
);

select public.record_validated_purchase(
  '30000000-0000-0000-0000-000000000001',
  (select id from public.products where sku='pro_monthly_ios'),
  'ios',
  'pro-monthly-txn-1',
  'stored'
);

select ok(
  (select active_until from public.entitlements where user_id='30000000-0000-0000-0000-000000000001' and feature='pro') > now(),
  'monthly Pro creates expiring Pro entitlement'
);

select public.record_validated_purchase(
  '30000000-0000-0000-0000-000000000002',
  (select id from public.products where sku='pro_lifetime_launch_ios'),
  'ios',
  'pro-lifetime-txn-1',
  'stored'
);

select is(
  (select active_until from public.entitlements where user_id='30000000-0000-0000-0000-000000000002' and feature='pro'),
  null,
  'lifetime Pro creates permanent Pro entitlement'
);

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000001"}';
set local role authenticated;

select is(
  (select available_count from public.get_my_boost_credits()),
  3,
  'get_my_boost_credits returns own available count'
);

select throws_ok(
  $$ select public.record_validated_purchase(
    '30000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'ios',
    'auth-direct-txn',
    'stored'
  ) $$,
  '42501',
  null,
  'authenticated cannot execute record_validated_purchase directly'
);

select throws_ok(
  $$ insert into public.keo_boost_credits(user_id, source)
    values ('30000000-0000-0000-0000-000000000001', 'promo') $$,
  '42501',
  null,
  'authenticated cannot insert boost credits directly'
);

set local role postgres;
create temp table _before_retry as
select active_until
from public.entitlements
where user_id = '30000000-0000-0000-0000-000000000001'
  and feature = 'pro';

insert into auth.users (id)
select ('31000000-0000-0000-0000-' || lpad(gs::text, 12, '0'))::uuid
from generate_series(1, 1498) gs
on conflict (id) do nothing;

insert into public.purchases (user_id, product_id, platform, store_txn_id, state)
select
  ('31000000-0000-0000-0000-' || lpad(gs::text, 12, '0'))::uuid,
  (select id from public.products where sku = 'pro_monthly_ios'),
  'ios',
  'pro-threshold-extra-' || gs::text,
  'validated'
from generate_series(1, 1498) gs
on conflict (platform, store_txn_id) do nothing;

select throws_ok(
  $$ select public.record_validated_purchase(
    '30000000-0000-0000-0000-000000000001',
    (select id from public.products where sku='pro_lifetime_final_ios'),
    'ios',
    'late-lifetime-txn-1',
    'stored'
  ) $$,
  '23514',
  'product_unavailable',
  'new lifetime purchase is rejected after lifetime threshold'
);

select lives_ok(
  $$ select public.record_validated_purchase(
    '30000000-0000-0000-0000-000000000002',
    (select id from public.products where sku='pro_lifetime_launch_ios'),
    'ios',
    'pro-lifetime-txn-1',
    'stored'
  ) $$,
  'exact retry of existing lifetime purchase is allowed after threshold'
);

select is(
  (select active_until from public.entitlements
    where user_id = '30000000-0000-0000-0000-000000000001'
      and feature = 'pro'),
  (select active_until from _before_retry),
  'retrying a previous monthly purchase does not extend Pro'
);

select throws_ok(
  $$ select public.record_validated_purchase(
    '30000000-0000-0000-0000-000000000002',
    (select id from public.products where sku='keo_boost_3_ios'),
    'ios',
    'boost-pack-txn-1',
    'stored'
  ) $$,
  '23514',
  'purchase_mismatch',
  'same store transaction cannot be reassigned to another user or product'
);

create temp table _before_extend as
select active_until
from public.entitlements
where user_id = '30000000-0000-0000-0000-000000000001'
  and feature = 'pro';

select public.record_validated_purchase(
  '30000000-0000-0000-0000-000000000001',
  (select id from public.products where sku='pro_monthly_ios'),
  'ios',
  'pro-monthly-txn-2',
  'stored'
);

select ok(
  (select active_until from public.entitlements
    where user_id = '30000000-0000-0000-0000-000000000001'
      and feature = 'pro')
    > (select active_until from _before_extend) + interval '30 days',
  'new monthly Pro purchase extends active entitlement by another period'
);

create temp table _after_extend as
select active_until
from public.entitlements
where user_id = '30000000-0000-0000-0000-000000000001'
  and feature = 'pro';

select public.record_validated_purchase(
  '30000000-0000-0000-0000-000000000001',
  (select id from public.products where sku='pro_monthly_ios'),
  'ios',
  'pro-monthly-txn-2',
  'stored'
);

select is(
  (select active_until from public.entitlements
    where user_id = '30000000-0000-0000-0000-000000000001'
      and feature = 'pro'),
  (select active_until from _after_extend),
  'retrying extended monthly purchase does not extend again'
);

select public.record_validated_purchase(
  '30000000-0000-0000-0000-000000000002',
  (select id from public.products where sku='pro_monthly_ios'),
  'ios',
  'pro-monthly-after-lifetime-txn',
  'stored'
);

select is(
  (select active_until from public.entitlements
    where user_id = '30000000-0000-0000-0000-000000000002'
      and feature = 'pro'),
  null,
  'monthly purchase does not downgrade existing lifetime Pro'
);

select * from finish();
rollback;
