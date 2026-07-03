-- Doi tab upgrade: quota kieu dating-app cho like/super (Pro qua app_private.is_pro()),
-- undo_last_swipe (Pro-only rewind), get_match_id_with helper, va uu tien super-liker
-- trong get_discovery_candidates.

-- Part 1: record_swipe voi quota (copy nguyen body tu 0009, chi them quota block).
create or replace function public.record_swipe(p_target uuid, p_direction text)
returns boolean language plpgsql security definer set search_path='' as $$
declare a uuid; b uuid; reciprocal boolean; matched boolean := false;
begin
  perform app_private.enforce_rate_limit('swipe', 200, interval '1 day');
  -- Quota kieu dating-app (server-authoritative, Pro qua app_private.is_pro()).
  -- Quota is deliberately consumed BEFORE the on-conflict-do-nothing insert (fail-closed;
  -- moving it after the insert would open a concurrent-check TOCTOU window).
  if p_direction = 'like' and not app_private.is_pro() then
    begin
      perform app_private.enforce_rate_limit('daily_like', 30, interval '1 day');
    exception when sqlstate '23514' then
      raise exception 'like_limit' using errcode='check_violation';
    end;
  end if;
  if p_direction = 'super' then
    begin
      perform app_private.enforce_rate_limit(
        'daily_super',
        case when app_private.is_pro() then 5 else 1 end,
        interval '1 day');
    exception when sqlstate '23514' then
      raise exception 'super_limit' using errcode='check_violation';
    end;
  end if;
  -- Serialize the two reciprocal swipers on their canonical pair key so a concurrent
  -- opposite swipe is committed-visible before the reciprocity check (prevents lost matches).
  perform pg_advisory_xact_lock(
    hashtextextended(
      least(auth.uid(), p_target)::text || ':' || greatest(auth.uid(), p_target)::text, 0));
  insert into public.swipes(swiper_id, target_type, target_id, direction)
  values (auth.uid(), 'user', p_target::text, p_direction)
  on conflict (swiper_id, target_type, target_id) do nothing;

  if p_direction in ('like','super') then
    select exists(
      select 1 from public.swipes s
      where s.swiper_id = p_target and s.target_type='user'
        and s.target_id = auth.uid()::text and s.direction in ('like','super')
    ) into reciprocal;
    if reciprocal then
      a := least(auth.uid(), p_target); b := greatest(auth.uid(), p_target);
      insert into public.matches(user_a, user_b) values (a, b)
      on conflict (user_a, user_b) do nothing;
      matched := true;
    end if;
  end if;
  return matched;
end; $$;
revoke execute on function public.record_swipe(uuid,text) from public, anon;
grant execute on function public.record_swipe(uuid,text) to authenticated;

-- Part 2: undo_last_swipe() -- Pro-only rewind.
create or replace function public.undo_last_swipe()
returns boolean language plpgsql security definer set search_path='' as $$
declare last_target text;
begin
  if not app_private.is_pro() then
    raise exception 'pro_required' using errcode='check_violation';
  end if;
  select s.target_id into last_target
  from public.swipes s
  where s.swiper_id = auth.uid() and s.target_type = 'user'
  order by s.created_at desc limit 1;
  if last_target is null then
    return false;
  end if;
  -- Mirror record_swipe's canonical-pair advisory lock: serializes against a concurrent
  -- reciprocal swipe so a match can't be created between the check below and the delete.
  perform pg_advisory_xact_lock(
    hashtextextended(
      least(auth.uid(), last_target::uuid)::text || ':' || greatest(auth.uid(), last_target::uuid)::text, 0));
  if exists (
    select 1 from public.matches m
    where m.status = 'active'
      and m.user_a = least(auth.uid(), last_target::uuid)
      and m.user_b = greatest(auth.uid(), last_target::uuid)
  ) then
    return false; -- da match thi khong rut lai duoc
  end if;
  delete from public.swipes s
  where s.swiper_id = auth.uid() and s.target_type = 'user'
    and s.target_id = last_target;
  return true;
end; $$;
revoke execute on function public.undo_last_swipe() from public, anon;
grant execute on function public.undo_last_swipe() to authenticated;

-- Part 3: get_match_id_with -- lookup canonical match id with another user.
create or replace function public.get_match_id_with(p_other uuid)
returns uuid language sql security definer set search_path='' stable as $$
  select m.id from public.matches m
  where m.status = 'active'
    and m.user_a = least(auth.uid(), p_other)
    and m.user_b = greatest(auth.uid(), p_other);
$$;
revoke execute on function public.get_match_id_with(uuid) from public, anon;
grant execute on function public.get_match_id_with(uuid) to authenticated;

-- Part 4: get_discovery_candidates -- uu tien super-liker (verbatim copy from 0008 +
-- one scoring term). discovery_candidate has no reason_labels-style array field, so
-- no label is added to the composite type (would require altering the type, out of scope).
create or replace function public.get_discovery_candidates(p_limit int default 20, p_radius_km int default 50)
returns setof public.discovery_candidate
language sql security definer set search_path='' as $$
  with me as (
    select l.location as loc,
      (select array_agg(genre_id) from public.user_genres where user_id = auth.uid()) as genres,
      (select array_agg(song_id) from public.user_baitu where user_id = auth.uid()) as songs
    from public.user_locations l where l.user_id = auth.uid()
  ),
  cand as (
    select p.id, p.display_name, p.dob, p.verified_badge as verified, p.last_active,
           coalesce(p.report_risk, 0) as report_risk,
           public.ST_Distance(ul.location, me.loc) as dist_m,
           (select array_agg(g.genre_id) from public.user_genres g
              where g.user_id = p.id and g.genre_id = any(me.genres)) as shared_g,
           (select array_agg(s.song_id) from public.user_baitu s
              where s.user_id = p.id and s.song_id = any(me.songs)) as shared_s
    from public.profiles p
    join public.user_locations ul on ul.user_id = p.id
    cross join me
    where p.id <> auth.uid()
      and p.soft_deleted_at is null
      and public.ST_DWithin(ul.location, me.loc, p_radius_km * 1000)
      and not exists (select 1 from public.blocks b
                        where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
                           or (b.blocker_id = p.id and b.blocked_id = auth.uid()))
      and not exists (select 1 from public.swipes sw
                        where sw.swiper_id = auth.uid() and sw.target_type = 'user' and sw.target_id = p.id::text)
  )
  select c.id, c.display_name,
         extract(year from age(c.dob))::int as age,
         app_private.dist_band(c.dist_m) as distance_band,
         coalesce(c.shared_g, '{}') as shared_genres,
         coalesce(c.shared_s, '{}') as shared_baitu,
         c.verified, (c.last_active > now() - interval '1 day') as active_today
  from cand c
  order by (
      (select weight from public.ranking_weights where key='music') * coalesce(array_length(c.shared_g,1),0)
    + (select weight from public.ranking_weights where key='nearness') * (1.0 / (1 + c.dist_m/1000))
    + (select weight from public.ranking_weights where key='activity') * (case when c.last_active > now() - interval '1 day' then 1 else 0 end)
    - (select weight from public.ranking_weights where key='report_risk') * c.report_risk
    + case when exists (
        select 1 from public.swipes ss
        where ss.swiper_id = c.id and ss.target_type = 'user'
          and ss.target_id = auth.uid()::text and ss.direction = 'super'
      ) then 5.0 else 0 end
  ) desc
  limit greatest(p_limit, 1);
$$;
revoke execute on function public.get_discovery_candidates(int,int) from public, anon;
grant execute on function public.get_discovery_candidates(int,int) to authenticated;
