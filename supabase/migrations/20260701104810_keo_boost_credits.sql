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
  v_purchase_id uuid;
  v_created boolean := false;
  v_existing_until timestamptz;
  v_new_until timestamptz;
begin
  select * into v_product
  from public.products
  where id = p_product_id
    and platform = p_platform
    and is_active;

  if not found then
    raise exception 'unknown_product' using errcode='check_violation';
  end if;

  select id into v_purchase_id
  from public.purchases
  where platform = p_platform
    and store_txn_id = p_store_txn_id;

  if v_purchase_id is null then
    insert into public.purchases(user_id, product_id, platform, store_txn_id, receipt_ref, state)
    values (p_user_id, p_product_id, p_platform, p_store_txn_id, p_receipt_ref, 'validated')
    returning id into v_purchase_id;
    v_created := true;
  else
    update public.purchases
    set user_id = p_user_id,
        product_id = p_product_id,
        receipt_ref = p_receipt_ref,
        state = 'validated'
    where id = v_purchase_id;
  end if;

  if v_product.type = 'pro' then
    select active_until into v_existing_until
    from public.entitlements
    where user_id = p_user_id and feature = 'pro';

    if v_existing_until is null and exists (
      select 1 from public.entitlements where user_id = p_user_id and feature = 'pro'
    ) then
      v_new_until := null;
    elsif v_product.billing_period = 'lifetime' then
      v_new_until := null;
    else
      v_new_until := greatest(coalesce(v_existing_until, now()), now())
        + make_interval(days => coalesce(v_product.entitlement_days, 31));
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
      active_until = excluded.active_until;
  elsif v_product.type = 'boost' and v_created then
    insert into public.keo_boost_credits(user_id, purchase_id, source, status)
    select p_user_id, v_purchase_id, 'purchase', 'available'
    from generate_series(1, v_product.boost_credits);
  end if;

  return jsonb_build_object(
    'ok', true,
    'feature', v_product.type,
    'purchase_id', v_purchase_id,
    'created', v_created
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
