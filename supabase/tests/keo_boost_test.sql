-- Run with: supabase test db
begin;
select plan(34);

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

set local role postgres;

insert into public.entitlements (user_id, feature, source)
values ('30000000-0000-0000-0000-000000000001','pro','promo')
on conflict (user_id, feature) do update set active_until = null;

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000001"}';
set local role authenticated;

select public.update_my_location(21.0, 105.8, 'HN');

create temp table _boost_keo (id uuid);
insert into _boost_keo
select public.create_keo(
  'Boostable Keo',
  21.0,
  105.8,
  'HN',
  now() + interval '1 day',
  now() + interval '1 day 2 hours',
  4,
  null,
  null,
  array['vpop'],
  'open'
);

select has_function('public', 'apply_keo_boost', array['uuid']::name[], 'apply_keo_boost exists');
select has_function('public', 'get_keo_detail', array['uuid']::name[], 'get_keo_detail exists');

select lives_ok(
  $$ select * from public.apply_keo_boost((select id from _boost_keo)) $$,
  'host can apply boost with available credit'
);

set local role postgres;
select is(
  (select count(*)::int from public.keo_boosts where keo_id=(select id from _boost_keo) and status='active'),
  1,
  'apply boost creates active boost row'
);

select is(
  (select count(*)::int from public.keo_boost_credits where user_id='30000000-0000-0000-0000-000000000001' and status='used'),
  1,
  'apply boost spends one credit'
);

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000001"}';
set local role authenticated;

select throws_ok(
  $$ select * from public.apply_keo_boost((select id from _boost_keo)) $$,
  '23514',
  null,
  'cannot stack active boosts on one keo'
);

select ok(
  (select is_boosted from public.get_keo_detail((select id from _boost_keo))),
  'get_keo_detail exposes active boost state'
);

select ok(
  (select is_boosted from public.list_open_keos(5, 50) where id=(select id from _boost_keo)),
  'list_open_keos exposes boosted keo'
);

create temp table _plain_keo (id uuid);
insert into _plain_keo
select public.create_keo(
  'Earlier Plain Keo',
  21.0,
  105.8,
  'HN',
  now() + interval '12 hours',
  now() + interval '13 hours',
  4,
  null,
  null,
  array['vpop'],
  'open'
);

select is(
  (select id from public.list_open_keos(5, 50) limit 1),
  (select id from _boost_keo),
  'boosted keo ranks before earlier non-boosted keo'
);

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000002"}';
set local role authenticated;

select throws_ok(
  $$ select * from public.apply_keo_boost((select id from _boost_keo)) $$,
  '23514',
  'not_keo_host',
  'non-host cannot boost another user keo'
);

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000001"}';
set local role authenticated;

create temp table _closed_keo (id uuid);
insert into _closed_keo
select public.create_keo(
  'Closed Keo',
  21.0,
  105.8,
  'HN',
  now() + interval '2 days',
  now() + interval '2 days 2 hours',
  4,
  null,
  null,
  array['vpop'],
  'open'
);

set local role postgres;
update public.keo set status = 'cancelled' where id = (select id from _closed_keo);

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000001"}';
set local role authenticated;

select throws_ok(
  $$ select * from public.apply_keo_boost((select id from _closed_keo)) $$,
  '23514',
  'keo_not_boostable',
  'cancelled keo cannot be boosted'
);

create temp table _expired_keo (id uuid);
insert into _expired_keo
select public.create_keo(
  'Expired Keo',
  21.0,
  105.8,
  'HN',
  now() - interval '2 hours',
  now() - interval '1 hour',
  4,
  null,
  null,
  array['vpop'],
  'open'
);

select throws_ok(
  $$ select * from public.apply_keo_boost((select id from _expired_keo)) $$,
  '23514',
  'keo_not_boostable',
  'expired keo cannot be boosted'
);

create temp table _full_keo (id uuid);
insert into _full_keo
select public.create_keo(
  'Full Keo',
  21.0,
  105.8,
  'HN',
  now() + interval '3 days',
  now() + interval '3 days 2 hours',
  2,
  null,
  null,
  array['vpop'],
  'open'
);

set local role postgres;
insert into public.keo_members (keo_id, user_id, role, join_status, confirmed)
values ((select id from _full_keo), '30000000-0000-0000-0000-000000000002', 'member', 'approved', true)
on conflict (keo_id, user_id) do update set join_status = 'approved';

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000001"}';
set local role authenticated;

select throws_ok(
  $$ select * from public.apply_keo_boost((select id from _full_keo)) $$,
  '23514',
  'keo_not_boostable',
  'full keo cannot be boosted'
);

set local role postgres;

insert into auth.users (id) values
  ('30000000-0000-0000-0000-000000000003')
on conflict (id) do nothing;

insert into public.profiles (id, display_name, dob) values
  ('30000000-0000-0000-0000-000000000003','Bonus Pro Host','1990-01-01')
on conflict (id) do nothing;

insert into public.entitlements (user_id, feature, source)
values ('30000000-0000-0000-0000-000000000003','pro','promo')
on conflict (user_id, feature) do update set active_until = null;

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000003"}';
set local role authenticated;

select public.update_my_location(21.0, 105.8, 'HN');

create temp table _bonus_keo_one (id uuid);
insert into _bonus_keo_one
select public.create_keo(
  'Bonus Keo One',
  21.0,
  105.8,
  'HN',
  now() + interval '1 day',
  now() + interval '1 day 2 hours',
  4,
  null,
  null,
  array['vpop'],
  'open'
);

select lives_ok(
  $$ select * from public.apply_keo_boost((select id from _bonus_keo_one)) $$,
  'Pro host can use one monthly bonus boost credit'
);

set local role postgres;
select is(
  (select count(*)::int
    from public.keo_boost_credits
    where user_id='30000000-0000-0000-0000-000000000003'
      and source='pro_monthly_bonus'
      and status='used'),
  1,
  'Pro monthly bonus is created and immediately spent'
);

set local request.jwt.claims to '{"sub":"30000000-0000-0000-0000-000000000003"}';
set local role authenticated;

create temp table _bonus_keo_two (id uuid);
insert into _bonus_keo_two
select public.create_keo(
  'Bonus Keo Two',
  21.0,
  105.8,
  'HN',
  now() + interval '2 days',
  now() + interval '2 days 2 hours',
  4,
  null,
  null,
  array['vpop'],
  'open'
);

select throws_ok(
  $$ select * from public.apply_keo_boost((select id from _bonus_keo_two)) $$,
  '23514',
  'no_boost_credit',
  'Pro monthly bonus cannot be used twice in the same month'
);

select * from finish();
rollback;
