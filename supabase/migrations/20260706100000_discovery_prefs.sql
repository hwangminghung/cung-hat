-- Mo rong ban kinh khi het deck (Tinder-parity muc 2).
-- discovery_prefs: 1 dong/user, auto_expand = tu dong tim 100km khi 50km rong.
create table public.discovery_prefs (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  auto_expand boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table public.discovery_prefs enable row level security;
create policy discovery_prefs_read_self on public.discovery_prefs
  for select using (auth.uid() = user_id);
-- writes chi qua RPC (khong co write policy)
-- grant tuong minh: local DB tung thieu default grant cho authenticated
-- (chat_test/locations_test fail vi ly do nay).
grant select on public.discovery_prefs to authenticated;

create or replace function public.set_discovery_auto_expand(p_on boolean)
returns void language sql security definer set search_path='' as $$
  insert into public.discovery_prefs (user_id, auto_expand, updated_at)
  values (auth.uid(), p_on, now())
  on conflict (user_id) do update set auto_expand = excluded.auto_expand, updated_at = now();
$$;
create or replace function public.get_discovery_auto_expand()
returns boolean language sql security definer set search_path='' as $$
  select coalesce((select auto_expand from public.discovery_prefs where user_id = auth.uid()), false);
$$;
revoke execute on function public.set_discovery_auto_expand(boolean) from public, anon;
revoke execute on function public.get_discovery_auto_expand() from public, anon;
grant execute on function public.set_discovery_auto_expand(boolean) to authenticated;
grant execute on function public.get_discovery_auto_expand() to authenticated;

-- get_discovery_candidates -- copy VERBATIM tu 20260704110000_boost.sql (ban moi nhat,
-- da co term boost) + doi DUY NHAT dong ST_DWithin de clamp p_radius_km trong [1,100]km
-- (server-side guard: client khong the yeu cau ban kinh vuot 100km).
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
      and public.ST_DWithin(ul.location, me.loc, least(greatest(p_radius_km, 1), 100) * 1000)
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
