-- Boost: quyen loi Pro. Pro user co the "boost" ho so 30 phut, toi da 1 lan/ngay.
-- Trong luc boost con hieu luc, ho so duoc cong them diem xep hang trong
-- get_discovery_candidates (xuat hien truoc cac ho so khong boost o cung khoang cach).
--
-- Helpers (verified against DB, migrations 0007/0024):
--   app_private.is_pro() -> boolean            : entitlement 'pro' con hieu luc cho auth.uid()
--   app_private.enforce_rate_limit(text,int,interval) : tumbling window; raise 23514
--     (check_violation, message 'rate_limit_exceeded') khi count > limit.
--   public.rate_limits(user_id, bucket, window_start, count) : backing table cua rate limit.

-- Part A: bang boosts + RPC activate_boost.
create table public.boosts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  expires_at timestamptz not null
);
alter table public.boosts enable row level security;
create policy boosts_read_self on public.boosts for select using (auth.uid() = user_id);
-- writes only via RPC (no write policy)

create or replace function public.activate_boost()
returns timestamptz language plpgsql security definer set search_path='' as $$
declare new_expiry timestamptz;
begin
  if not app_private.is_pro() then
    raise exception 'pro_required' using errcode='check_violation';
  end if;
  if exists (select 1 from public.boosts b where b.user_id = auth.uid() and b.expires_at > now()) then
    raise exception 'boost_active' using errcode='check_violation';
  end if;
  begin
    perform app_private.enforce_rate_limit('daily_boost', 1, interval '1 day');
  exception when sqlstate '23514' then
    raise exception 'boost_limit' using errcode='check_violation';
  end;
  new_expiry := now() + interval '30 minutes';
  insert into public.boosts (user_id, expires_at) values (auth.uid(), new_expiry)
  on conflict (user_id) do update set expires_at = excluded.expires_at;
  return new_expiry;
end; $$;
revoke execute on function public.activate_boost() from public, anon;
grant execute on function public.activate_boost() to authenticated;

-- Part B: get_discovery_candidates -- copy VERBATIM tu 20260703100000_doi_swipe_upgrade
-- (ban da co term super-liker) + them DUY NHAT mot term boost (+3.0) canh cac term `+ case`.
-- Candidate alias trong body la `c`. Chi them term boost, khong doi gi khac.
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
    + case when exists (
        select 1 from public.boosts b
        where b.user_id = c.id and b.expires_at > now()
      ) then 3.0 else 0 end
  ) desc
  limit greatest(p_limit, 1);
$$;
revoke execute on function public.get_discovery_candidates(int,int) from public, anon;
grant execute on function public.get_discovery_candidates(int,int) to authenticated;
