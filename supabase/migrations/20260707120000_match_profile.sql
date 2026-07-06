-- Icebreaker sau match (muc 8): xem ho so nguoi DA match tu chat.
-- Tra dung composite discovery_candidate hien co (10 cot: id, display_name, age,
-- distance_band, shared_genres, shared_baitu, verified, active_today, bio,
-- prompts) -- KHONG alter type.
--
-- Gate: app_private.in_match(p_thread) (0010_chat.sql) da tu kiem tra
-- `m.status='active'` BEN TRONG dinh nghia cua no -- nen o day KHONG lap lai
-- dieu kien status trong FROM/JOIN chinh, tranh 2 noi cung gate 1 thu ma co
-- the lech nhau sau nay (vd. neu in_match doi dinh nghia "active match" thi
-- chi 1 cho phai sua). WHERE chi can loc theo m.id.
--
-- dist_band(NULL) KHONG null-safe: CASE cua no (0006_locations.sql) khi m la
-- NULL thi moi nhanh deu unknown -> roi vao ELSE '5+' (da xac nhan qua psql:
-- `select app_private.dist_band(NULL)` tra ve '5+' chu khong phai NULL). Vi
-- vay boc them CASE ... IS NULL o day de tranh bao sai distance_band khi 1
-- trong 2 ben chua co user_locations.
create or replace function public.get_match_profile(p_match uuid)
returns public.discovery_candidate
language plpgsql security definer set search_path='' as $$
declare result public.discovery_candidate;
begin
  if not app_private.in_match(p_match) then
    raise exception 'not_match_member' using errcode='check_violation';
  end if;
  select p.id, p.display_name,
         extract(year from age(p.dob))::int,
         case when ul_me.location is null or ul_other.location is null then null
              else app_private.dist_band(public.ST_Distance(ul_me.location, ul_other.location)) end,
         coalesce((select array_agg(g.genre_id) from public.user_genres g
            where g.user_id = p.id and g.genre_id in
              (select genre_id from public.user_genres where user_id = auth.uid())), '{}'),
         coalesce((select array_agg(s.song_id) from public.user_baitu s
            where s.user_id = p.id and s.song_id in
              (select song_id from public.user_baitu where user_id = auth.uid())), '{}'),
         p.verified_badge, (p.last_active > now() - interval '1 day'),
         p.bio, app_private.prompts_json(p.id)
    into result
  from public.matches m
  join public.profiles p
    on p.id = case when m.user_a = auth.uid() then m.user_b else m.user_a end
  left join public.user_locations ul_me on ul_me.user_id = auth.uid()
  left join public.user_locations ul_other on ul_other.user_id = p.id
  where m.id = p_match and p.soft_deleted_at is null;
  return result; -- NULL row (id null) neu doi phuong da xoa mem
end; $$;
revoke execute on function public.get_match_profile(uuid) from public, anon;
grant execute on function public.get_match_profile(uuid) to authenticated;
