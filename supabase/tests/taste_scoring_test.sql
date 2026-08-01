-- Run with: supabase test db
-- [MATCH-AUDIT #5] Khoá công thức điểm gu nhạc của deck Đôi.
-- Trước đây KHÔNG có test nào chốt trọng số nhạc (boost_test cố tình dựng
-- 0-genre-trùng để cô lập boost) — sửa nhầm trọng số là không ai bắt được.
--
-- Kịch bản: caller M và 3 ứng viên A/B/C đứng CÙNG toạ độ (triệt tiêu
-- nearness), cùng last_active cũ (triệt tiêu activity), không boost/super:
--   A trùng 1 GENRE  → music  3.0
--   B trùng 1 BÀI TỦ → baitu  2.0
--   C trùng 1 NGHỆ SĨ→ artist 1.0
-- Thứ tự bắt buộc: A, B, C — khoá cả việc baitu/artist CÓ điểm lẫn việc
-- genre vẫn nặng nhất.
begin;
select plan(4);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000a5'),
  ('00000000-0000-0000-0000-0000000000b5'),
  ('00000000-0000-0000-0000-0000000000c5'),
  ('00000000-0000-0000-0000-0000000000d5')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, last_active) values
  ('00000000-0000-0000-0000-0000000000a5', 'M',  '1995-01-01', now() - interval '3 days'),
  ('00000000-0000-0000-0000-0000000000b5', 'A-genre',  '1995-01-01', now() - interval '3 days'),
  ('00000000-0000-0000-0000-0000000000c5', 'B-baitu',  '1995-01-01', now() - interval '3 days'),
  ('00000000-0000-0000-0000-0000000000d5', 'C-artist', '1995-01-01', now() - interval '3 days')
  on conflict (id) do update set last_active = excluded.last_active;
insert into public.user_locations (user_id, location) values
  ('00000000-0000-0000-0000-0000000000a5', public.ST_SetSRID(public.ST_MakePoint(105.800, 21.000),4326)::public.geography),
  ('00000000-0000-0000-0000-0000000000b5', public.ST_SetSRID(public.ST_MakePoint(105.800, 21.000),4326)::public.geography),
  ('00000000-0000-0000-0000-0000000000c5', public.ST_SetSRID(public.ST_MakePoint(105.800, 21.000),4326)::public.geography),
  ('00000000-0000-0000-0000-0000000000d5', public.ST_SetSRID(public.ST_MakePoint(105.800, 21.000),4326)::public.geography)
  on conflict (user_id) do update set location = excluded.location;
-- Gu của M: 1 genre + 1 bài + 1 nghệ sĩ (seed 0003/0004 có sẵn vpop/s1/son_tung).
insert into public.user_genres (user_id, genre_id) values
  ('00000000-0000-0000-0000-0000000000a5', 'vpop'),
  ('00000000-0000-0000-0000-0000000000b5', 'vpop')
  on conflict do nothing;
insert into public.user_baitu (user_id, song_id, position) values
  ('00000000-0000-0000-0000-0000000000a5', 's1', 0),
  ('00000000-0000-0000-0000-0000000000c5', 's1', 0)
  on conflict do nothing;
insert into public.user_artists (user_id, artist_id) values
  ('00000000-0000-0000-0000-0000000000a5', 'son_tung'),
  ('00000000-0000-0000-0000-0000000000d5', 'son_tung')
  on conflict do nothing;
reset role;

-- Trọng số mới phải tồn tại.
select ok(
  (select weight from public.ranking_weights where key='baitu') = 2.0,
  'ranking_weights có baitu = 2.0');
select ok(
  (select weight from public.ranking_weights where key='artist') = 1.0,
  'ranking_weights có artist = 1.0');

set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000a5"}';
select is(
  (select array_agg(display_name order by rn)
     from (select display_name, row_number() over () as rn
             from public.get_discovery_candidates(10, 50, null)
            where display_name in ('A-genre','B-baitu','C-artist')) t),
  array['A-genre','B-baitu','C-artist'],
  'thứ tự điểm: genre(3.0) > bài tủ(2.0) > nghệ sĩ(1.0)');

-- Chip "cùng bài tủ" vẫn trả dữ liệu như cũ (không vỡ UI).
select is(
  (select shared_baitu from public.get_discovery_candidates(10, 50, null)
    where display_name = 'B-baitu'),
  array['s1'],
  'shared_baitu vẫn được expose cho chip UI');
reset role;

select * from finish();
rollback;
