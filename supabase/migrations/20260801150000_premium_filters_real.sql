-- [MATCH-AUDIT #1b] premium_filters 79k phải MỞ KHOÁ được thứ gì đó thật.
--
-- Store bán "Bộ lọc nâng cao — lọc theo gu nhạc, độ tuổi, khu vực và trạng
-- thái hoạt động" nhưng entitlement premium_filters không được RPC/màn hình
-- nào kiểm tra: bộ lọc duy nhất (bán kính + auto-expand) miễn phí cho tất cả.
-- Bán 79k mà không giao gì.
--
-- Triển khai: get_discovery_candidates nhận thêm 3 filter nâng cao
--   p_min_age / p_max_age  — khoảng tuổi (server đã có dob);
--   p_active_only          — chỉ người hoạt động trong 24h.
-- Server-authoritative: truyền bất kỳ filter nâng cao nào mà không có
-- entitlement premium_filters (Pro là superset) → raise entitlement_required
-- (fail-closed, cùng khuôn who_liked_me). Gu nhạc (p_genre) và bán kính giữ
-- MIỄN PHÍ như hiện trạng: theme decks + slider bán kính là tính năng free
-- sẵn có, khoá lại là lấy đi thứ user đang có.
--
-- SIGNATURE CHANGE (3 → 6 tham số): drop hàm cũ trước để tránh overload làm
-- PostgREST schema-cache mơ hồ (cùng lý do 20260706150000). Body copy
-- VERBATIM từ 20260801120000_taste_scoring + gate + 3 điều kiện lọc; đổi
-- sang plpgsql vì cần RAISE có điều kiện.
drop function if exists public.get_discovery_candidates(int, int, text);

create or replace function public.get_discovery_candidates(
  p_limit int default 20, p_radius_km int default 50, p_genre text default null,
  p_min_age int default null, p_max_age int default null, p_active_only boolean default false
) returns setof public.discovery_candidate
language plpgsql security definer set search_path='' as $$
begin
  if (p_min_age is not null or p_max_age is not null or coalesce(p_active_only, false))
     and not app_private.has_entitlement('premium_filters') then
    raise exception 'entitlement_required' using errcode='check_violation';
  end if;
  return query
  with me as (
    select l.location as loc,
      (select array_agg(genre_id) from public.user_genres where user_id = auth.uid()) as genres,
      (select array_agg(song_id) from public.user_baitu where user_id = auth.uid()) as songs,
      (select array_agg(artist_id) from public.user_artists where user_id = auth.uid()) as artists
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
              where s.user_id = p.id and s.song_id = any(me.songs)) as shared_s,
           (select array_agg(a.artist_id) from public.user_artists a
              where a.user_id = p.id and a.artist_id = any(me.artists)) as shared_a
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
      and (p_min_age is null or extract(year from age(p.dob))::int >= p_min_age)
      and (p_max_age is null or extract(year from age(p.dob))::int <= p_max_age)
      and (not coalesce(p_active_only, false) or p.last_active > now() - interval '1 day')
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
    + (select weight from public.ranking_weights where key='baitu') * coalesce(array_length(c.shared_s,1),0)
    + (select weight from public.ranking_weights where key='artist') * coalesce(array_length(c.shared_a,1),0)
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
end; $$;
revoke execute on function public.get_discovery_candidates(int,int,text,int,int,boolean)
  from public, anon;
grant execute on function public.get_discovery_candidates(int,int,text,int,int,boolean)
  to authenticated;
