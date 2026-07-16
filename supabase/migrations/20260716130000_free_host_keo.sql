-- P1-5 (product call 2026-07-16): DAO GATE tao keo de mo supply luc cold
-- start — free duoc HOST 1 keo active cung luc, Pro khong gioi han.
-- "Active" = status open/full/planning/confirmed AND chua het gio AND chua
-- xoa mem. Ap dung cho CA create_keo lan create_auto_matched_keo (truoc day
-- ca hai raise pro_required cho non-Pro).

create or replace function app_private.assert_can_host_keo()
returns void language plpgsql security definer set search_path='' as $$
begin
  if app_private.is_pro() then
    return;
  end if;
  if exists (
    select 1 from public.keo k
    where k.host_id = auth.uid()
      and k.soft_deleted_at is null
      and k.status in ('open','full','planning','confirmed')
      and k.time_window_end > now()
  ) then
    raise exception 'free_host_limit' using errcode='check_violation';
  end if;
end; $$;

-- Recreate create_keo (body 0024) — thay khoi pro_required bang gate moi.
create or replace function public.create_keo(
  p_title text, p_lat double precision, p_lng double precision, p_area text,
  p_start timestamptz, p_end timestamptz, p_size int, p_intent text, p_vibe text,
  p_genres text[], p_join_mode text default 'approval'
) returns uuid language plpgsql security definer set search_path='' as $$
declare kid uuid;
begin
  perform app_private.assert_can_host_keo();
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

-- Recreate create_auto_matched_keo (body 20260629120000) — cung gate moi.
create or replace function public.create_auto_matched_keo(
  p_title text,
  p_start timestamptz,
  p_end timestamptz,
  p_size int,
  p_genres text[],
  p_join_mode text default 'open'
)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
  kid uuid;
  caller_verified boolean;
  caller_loc public.geography;
  caller_area text;
  clean_title text;
begin
  perform app_private.assert_can_host_keo();

  select p.age_verified
    into caller_verified
  from public.profiles p
  where p.id = auth.uid()
    and p.soft_deleted_at is null;

  if coalesce(caller_verified, false) = false then
    raise exception 'age_not_verified' using errcode='check_violation';
  end if;

  select ul.location, ul.area_label
    into caller_loc, caller_area
  from public.user_locations ul
  where ul.user_id = auth.uid();

  if caller_loc is null then
    raise exception 'location_required' using errcode='check_violation';
  end if;

  if p_start is null or p_end is null or p_end <= p_start or p_start <= now() then
    raise exception 'invalid_time_window' using errcode='check_violation';
  end if;

  if p_size is null or p_size < 2 or p_size > 5 then
    raise exception 'invalid_group_size' using errcode='check_violation';
  end if;

  clean_title := nullif(trim(p_title), '');
  if clean_title is null then
    clean_title := 'Kèo gợi ý tối nay';
  end if;

  perform app_private.enforce_rate_limit('create_keo', 10, interval '1 day');

  insert into public.keo(
    host_id,
    title,
    area_label,
    area_geo,
    time_window_start,
    time_window_end,
    group_size_target,
    intent_tag,
    vibe,
    genres,
    join_mode
  )
  values (
    auth.uid(),
    left(clean_title, 100),
    caller_area,
    caller_loc,
    p_start,
    p_end,
    p_size,
    null,
    null,
    coalesce(p_genres, '{}'::text[]),
    case when p_join_mode in ('open','approval') then p_join_mode else 'open' end
  )
  returning id into kid;

  insert into public.keo_members(keo_id, user_id, role, join_status, confirmed)
  values (kid, auth.uid(), 'host', 'approved', true);

  return kid;
end;
$$;
