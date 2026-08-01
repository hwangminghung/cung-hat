-- [MATCH-AUDIT #5] Bài tủ + nghệ sĩ phải THAM GIA điểm ghép.
--
-- Onboarding thu 3 loại gu nhạc (genre / nghệ sĩ / bài tủ) nhưng công thức
-- xếp hạng deck Đôi chỉ dùng genre: shared_baitu được TÍNH ra để vẽ chip
-- "cùng N bài tủ" mà không cộng điểm, còn user_artists không được đọc ở bất
-- kỳ đâu ngoài % hoàn thiện hồ sơ. Tức 2/3 dữ liệu taste không có tác dụng
-- ghép — sai với lời hứa "ghép theo gu nhạc" của sản phẩm.
--
-- Trọng số mới (cùng bảng ranking_weights để đổi không cần migration):
--   baitu  2.0/bài  — cùng bài tủ = hát chung được ngay, tín hiệu mạnh chỉ
--                     sau genre;
--   artist 1.0/nghệ sĩ — cùng thần tượng là tín hiệu mềm.
-- Giữ music 3.0 đứng đầu: thứ tự music > baitu > artist được pgTAP khoá lại
-- (taste_scoring_test.sql) — trước đây KHÔNG có test nào chốt công thức nhạc.

insert into public.ranking_weights (key, weight) values
  ('baitu', 2.0), ('artist', 1.0)
  on conflict (key) do nothing;

-- Body copy VERBATIM từ 20260706150000_theme_decks.sql (bản mới nhất, có
-- p_genre + clamp bán kính + bio/prompts) + thêm DUY NHẤT: artists vào CTE
-- me, shared_a vào CTE cand, và 2 term baitu/artist trong ORDER BY.
create or replace function public.get_discovery_candidates(p_limit int default 20, p_radius_km int default 50, p_genre text default null)
returns setof public.discovery_candidate
language sql security definer set search_path='' as $$
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
$$;
revoke execute on function public.get_discovery_candidates(int,int,text) from public, anon;
grant execute on function public.get_discovery_candidates(int,int,text) to authenticated;
