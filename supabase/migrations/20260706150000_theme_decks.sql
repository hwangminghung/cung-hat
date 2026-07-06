-- Deck chu de nhac (Tinder-parity muc 9): mini-Kham Pha loc theo gu nhac +
-- so nguoi dang "live" moi chu de. get_discovery_candidates gan them tham so
-- p_genre (default null = deck chinh, khong loc).
--
-- SIGNATURE CHANGE: them p_genre la tham so THU BA -> phai DROP ham 2-tham-so
-- cu truoc, neu khong "create or replace" se tao OVERLOAD (2-arg + 3-arg cung
-- ton tai), khien PostgREST/schema cache mo ho ve ham nao duoc goi.
drop function public.get_discovery_candidates(int, int);

-- copy VERBATIM tu 20260706130000_profile_prompts.sql (ban moi nhat, co
-- clamp + bio + prompts) + THEM DUY NHAT: tham so p_genre va dieu kien loc
-- theo genre trong CTE cand.
create or replace function public.get_discovery_candidates(p_limit int default 20, p_radius_km int default 50, p_genre text default null)
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
           p.bio,
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
      and (p_genre is null or exists (select 1 from public.user_genres ug
             where ug.user_id = p.id and ug.genre_id = p_genre))
  )
  select c.id, c.display_name,
         extract(year from age(c.dob))::int as age,
         app_private.dist_band(c.dist_m) as distance_band,
         coalesce(c.shared_g, '{}') as shared_genres,
         coalesce(c.shared_s, '{}') as shared_baitu,
         c.verified, (c.last_active > now() - interval '1 day') as active_today, c.bio,
         app_private.prompts_json(c.id) as prompts
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
revoke execute on function public.get_discovery_candidates(int,int,text) from public, anon;
grant execute on function public.get_discovery_candidates(int,int,text) to authenticated;

-- Dem nguoi "live" moi chu de trong ban kinh 50km (chi con so, khong identity
-- -> khong lo privacy; van loai tai khoan xoa mem).
create or replace function public.get_theme_deck_counts(p_genres text[])
returns table (genre_id text, live_count int)
language sql security definer set search_path='' as $$
  with me as (select location as loc from public.user_locations where user_id = auth.uid())
  select g.genre_id,
         -- Subquery tuong quan thay vi LEFT JOIN + WHERE: genre 0-nguoi van
         -- tra ve hang voi live_count = 0 (WHERE ngoai se nuot mat hang).
         (select count(*)::int
            from public.user_genres ug
            join public.profiles p on p.id = ug.user_id
            join public.user_locations ul on ul.user_id = p.id
            cross join me
           where ug.genre_id = g.genre_id
             and p.id <> auth.uid()
             and p.soft_deleted_at is null
             and p.last_active > now() - interval '7 days'
             and public.ST_DWithin(ul.location, me.loc, 50000)) as live_count
  from unnest(p_genres) as g(genre_id);
$$;
revoke execute on function public.get_theme_deck_counts(text[]) from public, anon;
grant execute on function public.get_theme_deck_counts(text[]) to authenticated;
