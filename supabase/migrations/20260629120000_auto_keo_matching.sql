create type public.keo_match_suggestion as (
  suggestion_type text,
  keo_id uuid,
  title text,
  area_label text,
  distance_band text,
  time_window_start timestamptz,
  time_window_end timestamptz,
  size_target int,
  slots_filled int,
  genres text[],
  host_name text,
  join_mode text,
  reason_labels text[],
  proposed_start timestamptz,
  proposed_end timestamptz
);

create or replace function public.suggest_keo_match(p_limit int default 3)
returns setof public.keo_match_suggestion
language plpgsql
security definer
set search_path=''
as $$
declare
  matched_count int := 0;
  caller_verified boolean;
  caller_loc public.geography;
  caller_area text;
  caller_genres text[];
  local_now timestamp;
  proposal_local timestamp;
  proposal_start timestamptz;
  proposal_end timestamptz;
begin
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

  select coalesce(array_agg(ug.genre_id), '{}'::text[])
    into caller_genres
  from public.user_genres ug
  where ug.user_id = auth.uid();

  return query
  with ranked as (
    select
      'existing_keo'::text as suggestion_type,
      k.id as keo_id,
      k.title,
      k.area_label,
      app_private.dist_band(public.ST_Distance(k.area_geo, caller_loc)) as distance_band,
      k.time_window_start,
      k.time_window_end,
      k.group_size_target as size_target,
      (
        select count(*)::int
        from public.keo_members km
        where km.keo_id = k.id
          and km.join_status = 'approved'
      ) as slots_filled,
      k.genres,
      hp.display_name as host_name,
      k.join_mode,
      array_remove(array[
        case when (
          select count(*)::int
          from (
            select unnest(k.genres)
            intersect
            select unnest(caller_genres)
          ) shared_genres
        ) > 0 then 'shared_genres'::text end,
        case when public.ST_Distance(k.area_geo, caller_loc) < 5000 then 'near_you'::text end,
        case when extract(hour from k.time_window_start at time zone 'Asia/Bangkok') between 18 and 22 then 'evening_slot'::text end,
        case when k.join_mode = 'open' then 'open_join'::text end,
        case when (
          select count(*)::int
          from public.keo_members km
          where km.keo_id = k.id
            and km.join_status = 'approved'
        ) < k.group_size_target then 'available_slots'::text end,
        case when hp.last_active > now() - interval '1 day' then 'active_host'::text end
      ], null) as reason_labels,
      null::timestamptz as proposed_start,
      null::timestamptz as proposed_end,
      (
        3.0 * (
          select count(*)::numeric
          from (
            select unnest(k.genres)
            intersect
            select unnest(caller_genres)
          ) shared_genres
        )
        + case when cardinality(k.genres) = 0 then 0.5 else 0 end
        + case
            when public.ST_Distance(k.area_geo, caller_loc) < 1000 then 3.0
            when public.ST_Distance(k.area_geo, caller_loc) < 3000 then 2.0
            when public.ST_Distance(k.area_geo, caller_loc) < 5000 then 1.0
            else 0.25
          end
        + case when extract(hour from k.time_window_start at time zone 'Asia/Bangkok') between 18 and 22 then 1.0 else 0 end
        + case when hp.last_active > now() - interval '1 day' then 0.5 else 0 end
        - coalesce(hp.report_risk, 0) * 2.0
      ) as score
    from public.keo k
    join public.profiles hp on hp.id = k.host_id
    where k.status = 'open'
      and k.soft_deleted_at is null
      and k.time_window_end > now()
      and k.time_window_start < now() + interval '7 days'
      and k.host_id <> auth.uid()
      and hp.soft_deleted_at is null
      and hp.age_verified = true
      and public.ST_DWithin(k.area_geo, caller_loc, 50000)
      and (
        select count(*)::int
        from public.keo_members km
        where km.keo_id = k.id
          and km.join_status = 'approved'
      ) < k.group_size_target
      and not exists (
        select 1
        from public.keo_members mine
        where mine.keo_id = k.id
          and mine.user_id = auth.uid()
          and mine.join_status in ('requested','approved')
      )
      and not exists (
        select 1
        from public.blocks b
        where (b.blocker_id = auth.uid() and b.blocked_id = k.host_id)
           or (b.blocker_id = k.host_id and b.blocked_id = auth.uid())
      )
  )
  select
    r.suggestion_type,
    r.keo_id,
    r.title,
    r.area_label,
    r.distance_band,
    r.time_window_start,
    r.time_window_end,
    r.size_target,
    r.slots_filled,
    r.genres,
    r.host_name,
    r.join_mode,
    r.reason_labels,
    r.proposed_start,
    r.proposed_end
  from ranked r
  where r.score >= 1.0
  order by r.score desc, r.time_window_start asc
  limit greatest(coalesce(p_limit, 3), 1);

  get diagnostics matched_count = row_count;
  if matched_count > 0 then
    return;
  end if;

  local_now := timezone('Asia/Bangkok', now());
  proposal_local := date_trunc('day', local_now) + interval '19 hours';
  if proposal_local <= local_now then
    proposal_local := proposal_local + interval '1 day';
  end if;
  proposal_start := proposal_local at time zone 'Asia/Bangkok';
  proposal_end := proposal_start + interval '3 hours';

  return query
  select
    'new_keo_proposal'::text,
    null::uuid,
    'Keo goi y toi nay'::text,
    caller_area,
    null::text,
    null::timestamptz,
    null::timestamptz,
    4,
    1,
    coalesce(caller_genres, '{}'::text[]),
    null::text,
    'open'::text,
    array_remove(array[
      case when cardinality(coalesce(caller_genres, '{}'::text[])) > 0 then 'shared_genres'::text end,
      'evening_slot'::text,
      'open_join'::text
    ], null),
    proposal_start,
    proposal_end;
end;
$$;

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
  if not app_private.is_pro() then
    raise exception 'pro_required' using errcode='check_violation';
  end if;

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

  if p_size < 2 or p_size > 5 then
    raise exception 'invalid_group_size' using errcode='check_violation';
  end if;

  clean_title := nullif(trim(p_title), '');
  if clean_title is null then
    clean_title := 'Keo goi y toi nay';
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

revoke execute on function public.suggest_keo_match(int) from public, anon;
revoke execute on function public.create_auto_matched_keo(text,timestamptz,timestamptz,int,text[],text) from public, anon;
grant execute on function public.suggest_keo_match(int) to authenticated;
grant execute on function public.create_auto_matched_keo(text,timestamptz,timestamptz,int,text[],text) to authenticated;
