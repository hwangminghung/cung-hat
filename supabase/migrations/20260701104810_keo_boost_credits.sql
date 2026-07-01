create table if not exists public.keo_boost_credits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  purchase_id uuid references public.purchases(id),
  source text not null check (source in ('purchase','pro_monthly_bonus','promo')),
  status text not null default 'available' check (status in ('available','used','expired')),
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  used_at timestamptz,
  used_on_keo_id uuid references public.keo(id)
);

create index if not exists keo_boost_credits_user_status_idx
  on public.keo_boost_credits(user_id, status, expires_at);

alter table public.keo_boost_credits enable row level security;

drop policy if exists keo_boost_credits_read_self on public.keo_boost_credits;
create policy keo_boost_credits_read_self
  on public.keo_boost_credits
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

grant select on public.keo_boost_credits to authenticated;

create table if not exists public.keo_boosts (
  id uuid primary key default gen_random_uuid(),
  keo_id uuid not null references public.keo(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  credit_id uuid not null references public.keo_boost_credits(id),
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  status text not null default 'active' check (status in ('active','expired','cancelled')),
  created_at timestamptz not null default now()
);

create index if not exists keo_boosts_active_idx
  on public.keo_boosts(keo_id, status, starts_at desc, ends_at desc);

alter table public.keo_boosts enable row level security;

create or replace function public.record_validated_purchase(
  p_user_id uuid,
  p_product_id uuid,
  p_platform text,
  p_store_txn_id text,
  p_receipt_ref text default 'stored'
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_product public.products%rowtype;
  v_purchase public.purchases%rowtype;
  v_purchase_id uuid;
  v_new_until timestamptz;
  v_paid_pro_users int;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_platform || ':' || p_store_txn_id, 0));

  select * into v_product
  from public.products
  where id = p_product_id
    and platform = p_platform
    and is_active;

  if not found then
    raise exception 'unknown_product' using errcode='check_violation';
  end if;

  select * into v_purchase
  from public.purchases
  where platform = p_platform
    and store_txn_id = p_store_txn_id
  for update;

  if found then
    if v_purchase.user_id <> p_user_id
       or v_purchase.product_id <> p_product_id
       or v_purchase.platform <> p_platform then
      raise exception 'purchase_mismatch' using errcode='check_violation';
    end if;

    return jsonb_build_object(
      'ok', true,
      'feature', v_product.type,
      'purchase_id', v_purchase.id,
      'created', false
    );
  end if;

  v_paid_pro_users := app_private.paid_pro_user_count();
  if v_paid_pro_users < v_product.min_paid_pro_users
     or (v_product.max_paid_pro_users is not null and v_paid_pro_users > v_product.max_paid_pro_users) then
    raise exception 'product_unavailable' using errcode='check_violation';
  end if;

  insert into public.purchases(user_id, product_id, platform, store_txn_id, receipt_ref, state)
  values (p_user_id, p_product_id, p_platform, p_store_txn_id, p_receipt_ref, 'validated')
  on conflict (platform, store_txn_id) do nothing
  returning id into v_purchase_id;

  if v_purchase_id is null then
    select * into v_purchase
    from public.purchases
    where platform = p_platform
      and store_txn_id = p_store_txn_id
    for update;

    if not found
       or v_purchase.user_id <> p_user_id
       or v_purchase.product_id <> p_product_id
       or v_purchase.platform <> p_platform then
      raise exception 'purchase_mismatch' using errcode='check_violation';
    end if;

    return jsonb_build_object(
      'ok', true,
      'feature', v_product.type,
      'purchase_id', v_purchase.id,
      'created', false
    );
  end if;

  if v_product.type = 'pro' then
    if v_product.billing_period = 'lifetime' then
      v_new_until := null;
    else
      v_new_until := now() + make_interval(days => coalesce(v_product.entitlement_days, 31));
    end if;

    insert into public.entitlements(user_id, feature, source, active_until)
    values (
      p_user_id,
      'pro',
      case when p_platform = 'ios' then 'ios_iap' else 'play_billing' end,
      v_new_until
    )
    on conflict (user_id, feature) do update set
      source = excluded.source,
      active_until = case
        when public.entitlements.active_until is null or excluded.active_until is null then null
        else greatest(public.entitlements.active_until, now())
          + make_interval(days => coalesce(v_product.entitlement_days, 31))
      end;
  elsif v_product.type = 'boost' then
    insert into public.keo_boost_credits(user_id, purchase_id, source, status)
    select p_user_id, v_purchase_id, 'purchase', 'available'
    from generate_series(1, v_product.boost_credits);
  end if;

  return jsonb_build_object(
    'ok', true,
    'feature', v_product.type,
    'purchase_id', v_purchase_id,
    'created', true
  );
end;
$$;

revoke execute on function public.record_validated_purchase(uuid,uuid,text,text,text) from public, anon, authenticated;
grant execute on function public.record_validated_purchase(uuid,uuid,text,text,text) to service_role;

create or replace function public.get_my_boost_credits()
returns table (available_count int, next_expiring_at timestamptz)
language sql
security definer
set search_path=''
stable
as $$
  select
    count(*)::int as available_count,
    min(expires_at) filter (where expires_at is not null) as next_expiring_at
  from public.keo_boost_credits
  where user_id = auth.uid()
    and status = 'available'
    and (expires_at is null or expires_at > now());
$$;

revoke execute on function public.get_my_boost_credits() from public, anon;
grant execute on function public.get_my_boost_credits() to authenticated;
