create or replace function public.apply_keo_boost(p_keo uuid)
returns table (boost_id uuid, ends_at timestamptz)
language plpgsql
security definer
set search_path=''
as $$
declare
  v_user_id uuid := auth.uid();
  v_keo public.keo%rowtype;
  v_credit_id uuid;
  v_month_start timestamptz;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_keo::text, 0));

  select * into v_keo
  from public.keo
  where id = p_keo
  for update;

  if v_user_id is null or not found or v_keo.host_id <> v_user_id then
    raise exception 'not_keo_host' using errcode='check_violation';
  end if;

  if v_keo.status <> 'open'
     or v_keo.soft_deleted_at is not null
     or v_keo.time_window_end <= now()
     or (
       select count(*) from public.keo_members m
       where m.keo_id = p_keo and m.join_status = 'approved'
     ) >= v_keo.group_size_target then
    raise exception 'keo_not_boostable' using errcode='check_violation';
  end if;

  if exists (
    select 1 from public.keo_boosts b
    where b.keo_id = p_keo
      and b.status = 'active'
      and b.starts_at <= now()
      and b.ends_at > now()
  ) then
    raise exception 'boost_already_active' using errcode='check_violation';
  end if;

  select id into v_credit_id
  from public.keo_boost_credits
  where user_id = v_user_id
    and status = 'available'
    and (expires_at is null or expires_at > now())
  order by expires_at asc nulls last, created_at asc
  limit 1
  for update skip locked;

  if v_credit_id is null and app_private.is_pro() then
    v_month_start := date_trunc('month', timezone('Asia/Bangkok', now())) at time zone 'Asia/Bangkok';
    perform pg_advisory_xact_lock(hashtextextended(v_user_id::text || ':' || v_month_start::text, 0));

    if not exists (
      select 1
      from public.keo_boost_credits c
      where c.user_id = v_user_id
        and c.source = 'pro_monthly_bonus'
        and c.created_at >= v_month_start
    ) then
      insert into public.keo_boost_credits(user_id, source, status, expires_at)
      values (v_user_id, 'pro_monthly_bonus', 'available', v_month_start + interval '1 month')
      returning id into v_credit_id;
    end if;
  end if;

  if v_credit_id is null then
    raise exception 'no_boost_credit' using errcode='check_violation';
  end if;

  insert into public.keo_boosts(keo_id, user_id, credit_id, starts_at, ends_at, status)
  values (p_keo, v_user_id, v_credit_id, now(), now() + interval '24 hours', 'active')
  returning id, keo_boosts.ends_at into boost_id, ends_at;

  update public.keo_boost_credits
  set status = 'used',
      used_at = now(),
      used_on_keo_id = p_keo
  where id = v_credit_id;

  return next;
end;
$$;

revoke execute on function public.apply_keo_boost(uuid) from public, anon;
grant execute on function public.apply_keo_boost(uuid) to authenticated;

drop function if exists public.list_open_keos(int,int);
drop function if exists public.get_keo_detail(uuid);
drop type if exists public.keo_card;

create type public.keo_card as (
  id uuid,
  title text,
  area_label text,
  distance_band text,
  time_window_start timestamptz,
  time_window_end timestamptz,
  size_target int,
  slots_filled int,
  genres text[],
  host_name text,
  status text,
  join_mode text,
  is_boosted boolean,
  boost_ends_at timestamptz
);

create or replace function public.list_open_keos(p_limit int default 30, p_radius_km int default 50)
returns setof public.keo_card
language sql
security definer
set search_path=''
stable
as $$
  with me as (
    select location as loc from public.user_locations where user_id = auth.uid()
  ),
  cards as (
    select
      k.id,
      k.title,
      k.area_label,
      app_private.dist_band(public.ST_Distance(k.area_geo, me.loc)) as distance_band,
      k.time_window_start,
      k.time_window_end,
      k.group_size_target as size_target,
      (select count(*)::int from public.keo_members m
        where m.keo_id = k.id and m.join_status = 'approved') as slots_filled,
      k.genres,
      (select display_name from public.profiles p where p.id = k.host_id) as host_name,
      k.status,
      k.join_mode,
      b.id is not null as is_boosted,
      b.ends_at as boost_ends_at,
      b.starts_at as boost_starts_at
    from public.keo k
    cross join me
    left join lateral (
      select id, starts_at, ends_at
      from public.keo_boosts kb
      where kb.keo_id = k.id
        and kb.status = 'active'
        and kb.starts_at <= now()
        and kb.ends_at > now()
      order by kb.starts_at desc
      limit 1
    ) b on true
    where k.status = 'open'
      and k.soft_deleted_at is null
      and k.time_window_end > now()
      and public.ST_DWithin(k.area_geo, me.loc, p_radius_km * 1000)
      and not exists (
        select 1 from public.blocks bl
        where (bl.blocker_id = auth.uid() and bl.blocked_id = k.host_id)
           or (bl.blocker_id = k.host_id and bl.blocked_id = auth.uid())
      )
  )
  select
    id,
    title,
    area_label,
    distance_band,
    time_window_start,
    time_window_end,
    size_target,
    slots_filled,
    genres,
    host_name,
    status,
    join_mode,
    is_boosted,
    boost_ends_at
  from cards
  order by is_boosted desc, boost_starts_at desc nulls last, time_window_start asc
  limit greatest(p_limit, 1);
$$;

revoke execute on function public.list_open_keos(int,int) from public, anon;
grant execute on function public.list_open_keos(int,int) to authenticated;

create or replace function public.get_keo_detail(p_keo uuid)
returns public.keo_card
language sql
security definer
set search_path=''
stable
as $$
  select
    k.id,
    k.title,
    k.area_label,
    null::text as distance_band,
    k.time_window_start,
    k.time_window_end,
    k.group_size_target as size_target,
    (select count(*)::int from public.keo_members m
      where m.keo_id = k.id and m.join_status = 'approved') as slots_filled,
    k.genres,
    (select display_name from public.profiles p where p.id = k.host_id) as host_name,
    k.status,
    k.join_mode,
    b.id is not null as is_boosted,
    b.ends_at as boost_ends_at
  from public.keo k
  left join lateral (
    select id, ends_at
    from public.keo_boosts kb
    where kb.keo_id = k.id
      and kb.status = 'active'
      and kb.starts_at <= now()
      and kb.ends_at > now()
    order by kb.starts_at desc
    limit 1
  ) b on true
  where k.id = p_keo
    and k.soft_deleted_at is null
    and not exists (
      select 1 from public.blocks bl
      where (bl.blocker_id = auth.uid() and bl.blocked_id = k.host_id)
         or (bl.blocker_id = k.host_id and bl.blocked_id = auth.uid())
    );
$$;

revoke execute on function public.get_keo_detail(uuid) from public, anon;
grant execute on function public.get_keo_detail(uuid) to authenticated;
