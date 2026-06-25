create table public.products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  type text not null check (type in ('boost','see_likes','premium_filters')),
  platform text not null check (platform in ('ios','android')),
  store_product_id text not null,
  price_minor int not null,
  is_active boolean not null default true
);
alter table public.products enable row level security;
create policy products_read on public.products for select using (is_active);
insert into public.products (sku, type, platform, store_product_id, price_minor) values
  ('boost_ios','boost','ios','com.cunghat.boost',49000),
  ('boost_android','boost','android','boost',49000),
  ('see_likes_ios','see_likes','ios','com.cunghat.see_likes',99000),
  ('see_likes_android','see_likes','android','see_likes',99000),
  ('filters_ios','premium_filters','ios','com.cunghat.filters',79000),
  ('filters_android','premium_filters','android','filters',79000);

create table public.purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid references public.products(id),
  platform text not null check (platform in ('ios','android')),
  store_txn_id text not null,
  receipt_ref text,
  state text not null default 'pending' check (state in ('pending','validated','refunded')),
  created_at timestamptz not null default now(),
  unique (platform, store_txn_id)
);
alter table public.purchases enable row level security;
create policy purchases_read_self on public.purchases for select using (auth.uid()=user_id);

create table public.entitlements (
  user_id uuid references auth.users(id) on delete cascade,
  feature text not null check (feature in ('boost','see_likes','premium_filters')),
  source text not null check (source in ('ios_iap','play_billing','promo')),
  active_until timestamptz,
  created_at timestamptz not null default now(),
  primary key (user_id, feature)
);
alter table public.entitlements enable row level security;
create policy entitlements_read_self on public.entitlements for select using (auth.uid()=user_id);

create table public.venue_bookings (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid references public.plans(id) on delete cascade,
  venue_id uuid references public.venues(id),
  user_id uuid references auth.users(id) on delete cascade,
  amount_minor int not null,
  gateway text not null check (gateway in ('momo','zalopay')),
  gateway_ref text,
  commission_minor int not null default 0,
  state text not null default 'initiated' check (state in ('initiated','paid','failed','refunded')),
  created_at timestamptz not null default now()
);
alter table public.venue_bookings enable row level security;
create policy venue_bookings_self on public.venue_bookings for select using (auth.uid()=user_id);

create or replace function app_private.has_entitlement(p_feature text)
returns boolean language sql security definer set search_path='' stable as $$
  select exists (select 1 from public.entitlements e
                 where e.user_id = auth.uid() and e.feature = p_feature
                   and (e.active_until is null or e.active_until > now()));
$$;

create or replace function public.get_my_entitlements()
returns setof public.entitlements language sql security definer set search_path='' as $$
  select * from public.entitlements where user_id = auth.uid();
$$;

-- Entitlement-gated "see who liked you" (sanitized; requires see_likes).
create or replace function public.who_liked_me(p_limit int default 20)
returns setof public.discovery_candidate language plpgsql security definer set search_path='' as $$
begin
  if not app_private.has_entitlement('see_likes') then
    raise exception 'entitlement_required' using errcode='check_violation';
  end if;
  return query
    with me as (select location as loc from public.user_locations where user_id=auth.uid())
    select p.id, p.display_name, extract(year from age(p.dob))::int,
           app_private.dist_band(public.ST_Distance(ul.location, me.loc)),
           '{}'::text[], '{}'::text[], p.verified_badge,
           (p.last_active > now() - interval '1 day')
    from public.swipes s
    join public.profiles p on p.id = s.swiper_id
    join public.user_locations ul on ul.user_id = p.id
    cross join me
    where s.target_type='user' and s.target_id = auth.uid()::text
      and s.direction in ('like','super') and p.soft_deleted_at is null
      and not exists (select 1 from public.matches m
        where (m.user_a=least(auth.uid(),p.id) and m.user_b=greatest(auth.uid(),p.id)))
    limit greatest(p_limit,1);
end; $$;

revoke execute on function public.get_my_entitlements() from public, anon;
revoke execute on function public.who_liked_me(int) from public, anon;
grant execute on function public.get_my_entitlements() to authenticated;
grant execute on function public.who_liked_me(int) to authenticated;
