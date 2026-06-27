-- 0024_pro_keo.sql
-- Pro gating: 'pro' entitlement is a superset; only Pro can create keo;
-- per-keo join mode (open/approval); free users capped at 1 active keo.

-- 1) Allow the 'pro' feature + product type (inline CHECKs are auto-named <table>_<col>_check).
alter table public.entitlements drop constraint entitlements_feature_check;
alter table public.entitlements add constraint entitlements_feature_check
  check (feature in ('boost','see_likes','premium_filters','pro'));
alter table public.products drop constraint products_type_check;
alter table public.products add constraint products_type_check
  check (type in ('boost','see_likes','premium_filters','pro'));
insert into public.products (sku, type, platform, store_product_id, price_minor) values
  ('pro_ios','pro','ios','com.cunghat.pro',199000),
  ('pro_android','pro','android','pro',199000)
  on conflict (sku) do nothing;

-- 2) is_pro() + has_entitlement superset.
create or replace function app_private.is_pro()
returns boolean language sql security definer set search_path='' stable as $$
  select exists (select 1 from public.entitlements e
                 where e.user_id = auth.uid() and e.feature = 'pro'
                   and (e.active_until is null or e.active_until > now()));
$$;

create or replace function app_private.has_entitlement(p_feature text)
returns boolean language sql security definer set search_path='' stable as $$
  select app_private.is_pro() or exists (
    select 1 from public.entitlements e
    where e.user_id = auth.uid() and e.feature = p_feature
      and (e.active_until is null or e.active_until > now()));
$$;

-- 3) Per-keo join mode.
alter table public.keo add column if not exists join_mode text not null default 'approval'
  check (join_mode in ('open','approval'));

-- 4) create_keo: Pro-only + join mode. Drop the old 10-arg signature, recreate with p_join_mode.
drop function if exists public.create_keo(text,double precision,double precision,text,timestamptz,timestamptz,int,text,text,text[]);

create or replace function public.create_keo(
  p_title text, p_lat double precision, p_lng double precision, p_area text,
  p_start timestamptz, p_end timestamptz, p_size int, p_intent text, p_vibe text,
  p_genres text[], p_join_mode text default 'approval'
) returns uuid language plpgsql security definer set search_path='' as $$
declare kid uuid;
begin
  if not app_private.is_pro() then
    raise exception 'pro_required' using errcode='check_violation';
  end if;
  perform app_private.enforce_rate_limit('create_keo', 10, interval '1 day');
  insert into public.keo(host_id, title, area_label, area_geo, time_window_start, time_window_end,
                         group_size_target, intent_tag, vibe, genres, join_mode)
  values (auth.uid(), p_title, p_area,
          public.ST_SetSRID(public.ST_MakePoint(round(p_lng::numeric,3)::double precision,
                                  round(p_lat::numeric,3)::double precision),4326)::public.geography,
          p_start, p_end, p_size, p_intent, p_vibe, coalesce(p_genres,'{}'),
          case when p_join_mode in ('open','approval') then p_join_mode else 'approval' end)
  returning id into kid;
  insert into public.keo_members(keo_id, user_id, role, join_status, confirmed)
  values (kid, auth.uid(), 'host', 'approved', true);
  return kid;
end; $$;

revoke execute on function public.create_keo(text,double precision,double precision,text,timestamptz,timestamptz,int,text,text,text[],text) from public, anon;
grant execute on function public.create_keo(text,double precision,double precision,text,timestamptz,timestamptz,int,text,text,text[],text) to authenticated;

-- 5) request_join_keo: free-user cap (1 active) + open-mode auto-approve.
create or replace function public.request_join_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
declare filled int; target int; st text; mode text; active_n int; new_status text;
begin
  perform app_private.enforce_rate_limit('join_keo', 50, interval '1 day');
  perform pg_advisory_xact_lock(hashtextextended(p_keo::text, 0));
  select status, group_size_target, join_mode into st, target, mode from public.keo where id = p_keo;
  if st <> 'open' then raise exception 'keo_not_open' using errcode='check_violation'; end if;
  if exists (select 1 from public.keo where id=p_keo and host_id=auth.uid()) then
    raise exception 'is_host' using errcode='check_violation';
  end if;
  if not app_private.is_pro() then
    select count(*) into active_n
      from public.keo_members m join public.keo k on k.id = m.keo_id
     where m.user_id = auth.uid() and m.keo_id <> p_keo
       and m.join_status in ('requested','approved')
       and k.status = 'open' and k.time_window_end > now();
    if active_n >= 1 then raise exception 'free_join_limit' using errcode='check_violation'; end if;
  end if;
  if exists (select 1 from public.blocks b
             where (b.blocker_id=auth.uid() and b.blocked_id=(select host_id from public.keo where id=p_keo))
                or (b.blocked_id=auth.uid() and b.blocker_id=(select host_id from public.keo where id=p_keo)))
  then raise exception 'blocked' using errcode='check_violation'; end if;
  select count(*) into filled from public.keo_members where keo_id=p_keo and join_status='approved';
  if filled >= target then raise exception 'keo_full' using errcode='check_violation'; end if;
  if exists (select 1 from public.keo_members where keo_id=p_keo and user_id=auth.uid() and join_status='declined') then
    raise exception 'already_declined' using errcode='check_violation';
  end if;
  new_status := case when mode = 'open' then 'approved' else 'requested' end;
  insert into public.keo_members(keo_id, user_id, role, join_status)
  values (p_keo, auth.uid(), 'member', new_status)
  on conflict (keo_id, user_id) do update set join_status=excluded.join_status;
  if new_status = 'approved' and filled + 1 >= target then
    update public.keo set status='full' where id=p_keo;
  end if;
end; $$;
