-- Run with: supabase test db
begin;
select plan(9);

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

select * from finish();
rollback;
