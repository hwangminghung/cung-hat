alter table public.products
  add column if not exists billing_period text not null default 'lifetime',
  add column if not exists entitlement_days int,
  add column if not exists boost_credits int not null default 0,
  add column if not exists sort_order int not null default 0,
  add column if not exists badge text,
  add column if not exists min_paid_pro_users int not null default 0,
  add column if not exists max_paid_pro_users int;

alter table public.products drop constraint if exists products_billing_period_check;
alter table public.products add constraint products_billing_period_check
  check (billing_period in ('monthly','yearly','lifetime','consumable'));

alter table public.products drop constraint if exists products_entitlement_days_check;
alter table public.products add constraint products_entitlement_days_check
  check (entitlement_days is null or entitlement_days > 0);

alter table public.products drop constraint if exists products_boost_credits_check;
alter table public.products add constraint products_boost_credits_check
  check (boost_credits >= 0);

alter table public.products drop constraint if exists products_paid_pro_window_check;
alter table public.products add constraint products_paid_pro_window_check
  check (max_paid_pro_users is null or max_paid_pro_users >= min_paid_pro_users);

update public.products
set billing_period = case
      when type = 'boost' then 'consumable'
      else 'lifetime'
    end,
    entitlement_days = null,
    boost_credits = case when type = 'boost' then 1 else 0 end,
    sort_order = case type
      when 'pro' then 10
      when 'boost' then 40
      when 'see_likes' then 80
      when 'premium_filters' then 90
      else 100
    end,
    badge = null,
    min_paid_pro_users = 0,
    max_paid_pro_users = null;

update public.products
set is_active = false
where sku in ('pro_ios','pro_android','boost_ios','boost_android');

insert into public.products (
  sku, type, platform, store_product_id, price_minor, is_active,
  billing_period, entitlement_days, boost_credits, sort_order, badge,
  min_paid_pro_users, max_paid_pro_users
) values
  ('pro_monthly_ios','pro','ios','com.cunghat.pro.monthly',79000,true,'monthly',31,0,10,null,0,null),
  ('pro_monthly_android','pro','android','pro_monthly',79000,true,'monthly',31,0,10,null,0,null),
  ('pro_yearly_ios','pro','ios','com.cunghat.pro.yearly',599000,true,'yearly',366,0,20,'best_value',0,null),
  ('pro_yearly_android','pro','android','pro_yearly',599000,true,'yearly',366,0,20,'best_value',0,null),
  ('pro_lifetime_launch_ios','pro','ios','com.cunghat.pro.lifetime.launch',249000,true,'lifetime',null,0,30,'launch',0,499),
  ('pro_lifetime_launch_android','pro','android','pro_lifetime_launch',249000,true,'lifetime',null,0,30,'launch',0,499),
  ('pro_lifetime_final_ios','pro','ios','com.cunghat.pro.lifetime.final',299000,true,'lifetime',null,0,31,'ending_soon',500,1499),
  ('pro_lifetime_final_android','pro','android','pro_lifetime_final',299000,true,'lifetime',null,0,31,'ending_soon',500,1499),
  ('keo_boost_24h_ios','boost','ios','com.cunghat.keo.boost.24h',29000,true,'consumable',null,1,40,null,0,null),
  ('keo_boost_24h_android','boost','android','keo_boost_24h',29000,true,'consumable',null,1,40,null,0,null),
  ('keo_boost_3_ios','boost','ios','com.cunghat.keo.boost.3',79000,true,'consumable',null,3,41,'best_value',0,null),
  ('keo_boost_3_android','boost','android','keo_boost_3',79000,true,'consumable',null,3,41,'best_value',0,null)
on conflict (sku) do update set
  type = excluded.type,
  platform = excluded.platform,
  store_product_id = excluded.store_product_id,
  price_minor = excluded.price_minor,
  is_active = excluded.is_active,
  billing_period = excluded.billing_period,
  entitlement_days = excluded.entitlement_days,
  boost_credits = excluded.boost_credits,
  sort_order = excluded.sort_order,
  badge = excluded.badge,
  min_paid_pro_users = excluded.min_paid_pro_users,
  max_paid_pro_users = excluded.max_paid_pro_users;

drop type if exists public.store_product;
create type public.store_product as (
  sku text,
  type text,
  platform text,
  store_product_id text,
  price_minor int,
  billing_period text,
  entitlement_days int,
  boost_credits int,
  badge text,
  sort_order int
);

create or replace function app_private.paid_pro_user_count()
returns int
language sql
security definer
set search_path=''
stable
as $$
  select count(distinct pu.user_id)::int
  from public.purchases pu
  join public.products pr on pr.id = pu.product_id
  where pu.state = 'validated'
    and pr.type = 'pro';
$$;

create or replace function public.get_store_products(p_platform text)
returns setof public.store_product
language sql
security definer
set search_path=''
stable
as $$
  with paid as (
    select app_private.paid_pro_user_count() as n
  )
  select
    pr.sku,
    pr.type,
    pr.platform,
    pr.store_product_id,
    pr.price_minor,
    pr.billing_period,
    pr.entitlement_days,
    pr.boost_credits,
    pr.badge,
    pr.sort_order
  from public.products pr
  cross join paid
  where pr.is_active
    and pr.platform = p_platform
    and pr.type in ('pro','boost')
    and paid.n >= pr.min_paid_pro_users
    and (pr.max_paid_pro_users is null or paid.n <= pr.max_paid_pro_users)
  order by pr.sort_order asc, pr.price_minor asc, pr.sku asc;
$$;

revoke execute on function public.get_store_products(text) from public, anon;
grant execute on function public.get_store_products(text) to authenticated;

grant select on public.products to authenticated;
