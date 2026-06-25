-- scripts/seed_launch.sql
-- 3-city launch seed for Cùng Hát: makes each launch city's Kèo board "alive" on
-- day one with a few curated K-style venues and a handful of founding host-created
-- open kèo for HN, HCM and TN.
--
-- OPERATOR: replace placeholder venue names/addresses + founding host content with
-- real curated data before launch. Idempotent — safe to re-run.
--
-- PostGIS note: postgis lives in the `public` schema (0001_foundation.sql). This
-- script does NOT set search_path='', so PostGIS symbols are reachable unqualified,
-- but we schema-qualify them anyway (public.ST_*) to mirror the migrations and stay
-- robust regardless of the caller's search_path.
--
-- Idempotency: the seeded auth.users / profiles / user_locations carry FIXED uuids,
-- and venues / kèo have no natural unique key for ON CONFLICT, so every insert is
-- guarded with `where not exists (...)`. Re-running inserts nothing new.

begin;

-- ---------------------------------------------------------------------------
-- 1. Founding host users (one per city). Fixed uuids → idempotent.
--    City centres: HN 105.795,21.030 · HCM 106.700,10.776 · TN 105.842,21.594
-- ---------------------------------------------------------------------------

-- auth.users
insert into auth.users (id, aud, role, email)
select 'a0000000-0000-4000-8000-0000000000a1'::uuid, 'authenticated', 'authenticated', 'founder.hn@cunghat.local'
where not exists (select 1 from auth.users u where u.id = 'a0000000-0000-4000-8000-0000000000a1'::uuid);

insert into auth.users (id, aud, role, email)
select 'a0000000-0000-4000-8000-0000000000a2'::uuid, 'authenticated', 'authenticated', 'founder.hcm@cunghat.local'
where not exists (select 1 from auth.users u where u.id = 'a0000000-0000-4000-8000-0000000000a2'::uuid);

insert into auth.users (id, aud, role, email)
select 'a0000000-0000-4000-8000-0000000000a3'::uuid, 'authenticated', 'authenticated', 'founder.tn@cunghat.local'
where not exists (select 1 from auth.users u where u.id = 'a0000000-0000-4000-8000-0000000000a3'::uuid);

-- public.profiles (age-verified founders)
insert into public.profiles (id, display_name, dob, age_verified)
select 'a0000000-0000-4000-8000-0000000000a1'::uuid, 'Cùng Hát Hà Nội', date '1995-01-01', true
where not exists (select 1 from public.profiles p where p.id = 'a0000000-0000-4000-8000-0000000000a1'::uuid);

insert into public.profiles (id, display_name, dob, age_verified)
select 'a0000000-0000-4000-8000-0000000000a2'::uuid, 'Cùng Hát Sài Gòn', date '1995-01-01', true
where not exists (select 1 from public.profiles p where p.id = 'a0000000-0000-4000-8000-0000000000a2'::uuid);

insert into public.profiles (id, display_name, dob, age_verified)
select 'a0000000-0000-4000-8000-0000000000a3'::uuid, 'Cùng Hát Thái Nguyên', date '1995-01-01', true
where not exists (select 1 from public.profiles p where p.id = 'a0000000-0000-4000-8000-0000000000a3'::uuid);

-- public.user_locations (city centre, so list_open_keos distance bands work)
insert into public.user_locations (user_id, location, area_label)
select 'a0000000-0000-4000-8000-0000000000a1'::uuid,
       public.ST_SetSRID(public.ST_MakePoint(105.795, 21.030), 4326)::public.geography, 'Cầu Giấy, Hà Nội'
where not exists (select 1 from public.user_locations ul where ul.user_id = 'a0000000-0000-4000-8000-0000000000a1'::uuid);

insert into public.user_locations (user_id, location, area_label)
select 'a0000000-0000-4000-8000-0000000000a2'::uuid,
       public.ST_SetSRID(public.ST_MakePoint(106.700, 10.776), 4326)::public.geography, 'Quận 1, TP.HCM'
where not exists (select 1 from public.user_locations ul where ul.user_id = 'a0000000-0000-4000-8000-0000000000a2'::uuid);

insert into public.user_locations (user_id, location, area_label)
select 'a0000000-0000-4000-8000-0000000000a3'::uuid,
       public.ST_SetSRID(public.ST_MakePoint(105.842, 21.594), 4326)::public.geography, 'TP. Thái Nguyên'
where not exists (select 1 from public.user_locations ul where ul.user_id = 'a0000000-0000-4000-8000-0000000000a3'::uuid);

-- ---------------------------------------------------------------------------
-- 2. Curated venues (2-3 per city). Additional to the 6 baseline seeds in 0015.
--    OPERATOR: replace with real, verified venues before launch.
-- ---------------------------------------------------------------------------

-- HN
insert into public.venues (name, address, city, location, style_tag)
select 'Mây Karaoke', 'Cầu Giấy, Hà Nội', 'HN',
       public.ST_SetSRID(public.ST_MakePoint(105.798, 21.033), 4326)::public.geography, 'k_style'
where not exists (select 1 from public.venues v where v.name = 'Mây Karaoke' and v.city = 'HN');

insert into public.venues (name, address, city, location, style_tag)
select 'Seoul K-Box', 'Ba Đình, Hà Nội', 'HN',
       public.ST_SetSRID(public.ST_MakePoint(105.812, 21.035), 4326)::public.geography, 'k_style'
where not exists (select 1 from public.venues v where v.name = 'Seoul K-Box' and v.city = 'HN');

insert into public.venues (name, address, city, location, style_tag)
select 'Gia Đình Karaoke HN', 'Thanh Xuân, Hà Nội', 'HN',
       public.ST_SetSRID(public.ST_MakePoint(105.804, 21.000), 4326)::public.geography, 'family'
where not exists (select 1 from public.venues v where v.name = 'Gia Đình Karaoke HN' and v.city = 'HN');

-- HCM
insert into public.venues (name, address, city, location, style_tag)
select 'Icool Karaoke', 'Quận 1, TP.HCM', 'HCM',
       public.ST_SetSRID(public.ST_MakePoint(106.698, 10.778), 4326)::public.geography, 'k_style'
where not exists (select 1 from public.venues v where v.name = 'Icool Karaoke' and v.city = 'HCM');

insert into public.venues (name, address, city, location, style_tag)
select 'K-Live Box', 'Quận 3, TP.HCM', 'HCM',
       public.ST_SetSRID(public.ST_MakePoint(106.685, 10.782), 4326)::public.geography, 'k_style'
where not exists (select 1 from public.venues v where v.name = 'K-Live Box' and v.city = 'HCM');

insert into public.venues (name, address, city, location, style_tag)
select 'Gia Đình Karaoke SG', 'Phú Nhuận, TP.HCM', 'HCM',
       public.ST_SetSRID(public.ST_MakePoint(106.680, 10.795), 4326)::public.geography, 'family'
where not exists (select 1 from public.venues v where v.name = 'Gia Đình Karaoke SG' and v.city = 'HCM');

-- TN
insert into public.venues (name, address, city, location, style_tag)
select 'Thái Nguyên K-Box', 'TP. Thái Nguyên', 'TN',
       public.ST_SetSRID(public.ST_MakePoint(105.845, 21.596), 4326)::public.geography, 'k_style'
where not exists (select 1 from public.venues v where v.name = 'Thái Nguyên K-Box' and v.city = 'TN');

insert into public.venues (name, address, city, location, style_tag)
select 'Sông Cầu Karaoke', 'TP. Thái Nguyên', 'TN',
       public.ST_SetSRID(public.ST_MakePoint(105.838, 21.590), 4326)::public.geography, 'k_style'
where not exists (select 1 from public.venues v where v.name = 'Sông Cầu Karaoke' and v.city = 'TN');

-- ---------------------------------------------------------------------------
-- 3. Founding open kèo (1-2 per city), hosted by the city founder.
--    status='open', time window starts in 2 days. Plus the host's keo_members row.
--    OPERATOR: replace titles / vibe with real curated founding events.
-- ---------------------------------------------------------------------------

-- HN kèo #1
insert into public.keo (host_id, title, area_label, area_geo, time_window_start, time_window_end,
                        group_size_target, status, genres)
select 'a0000000-0000-4000-8000-0000000000a1'::uuid, 'Kèo hát K-Pop cuối tuần (Hà Nội)', 'Cầu Giấy, Hà Nội',
       public.ST_SetSRID(public.ST_MakePoint(105.795, 21.030), 4326)::public.geography,
       now() + interval '2 days', now() + interval '2 days' + interval '2 hours',
       4, 'open', array['kpop','vpop']
where not exists (select 1 from public.keo k
                  where k.title = 'Kèo hát K-Pop cuối tuần (Hà Nội)'
                    and k.host_id = 'a0000000-0000-4000-8000-0000000000a1'::uuid);

insert into public.keo_members (keo_id, user_id, role, join_status, confirmed)
select k.id, k.host_id, 'host', 'approved', true
from public.keo k
where k.title = 'Kèo hát K-Pop cuối tuần (Hà Nội)'
  and k.host_id = 'a0000000-0000-4000-8000-0000000000a1'::uuid
  and not exists (select 1 from public.keo_members m where m.keo_id = k.id and m.user_id = k.host_id);

-- HN kèo #2
insert into public.keo (host_id, title, area_label, area_geo, time_window_start, time_window_end,
                        group_size_target, status, genres)
select 'a0000000-0000-4000-8000-0000000000a1'::uuid, 'Tối thứ 6 hát Ballad (Hà Nội)', 'Ba Đình, Hà Nội',
       public.ST_SetSRID(public.ST_MakePoint(105.812, 21.035), 4326)::public.geography,
       now() + interval '2 days', now() + interval '2 days' + interval '2 hours',
       3, 'open', array['ballad','vpop']
where not exists (select 1 from public.keo k
                  where k.title = 'Tối thứ 6 hát Ballad (Hà Nội)'
                    and k.host_id = 'a0000000-0000-4000-8000-0000000000a1'::uuid);

insert into public.keo_members (keo_id, user_id, role, join_status, confirmed)
select k.id, k.host_id, 'host', 'approved', true
from public.keo k
where k.title = 'Tối thứ 6 hát Ballad (Hà Nội)'
  and k.host_id = 'a0000000-0000-4000-8000-0000000000a1'::uuid
  and not exists (select 1 from public.keo_members m where m.keo_id = k.id and m.user_id = k.host_id);

-- HCM kèo #1
insert into public.keo (host_id, title, area_label, area_geo, time_window_start, time_window_end,
                        group_size_target, status, genres)
select 'a0000000-0000-4000-8000-0000000000a2'::uuid, 'Kèo hát V-Pop trung tâm (Sài Gòn)', 'Quận 1, TP.HCM',
       public.ST_SetSRID(public.ST_MakePoint(106.700, 10.776), 4326)::public.geography,
       now() + interval '2 days', now() + interval '2 days' + interval '2 hours',
       5, 'open', array['vpop','kpop']
where not exists (select 1 from public.keo k
                  where k.title = 'Kèo hát V-Pop trung tâm (Sài Gòn)'
                    and k.host_id = 'a0000000-0000-4000-8000-0000000000a2'::uuid);

insert into public.keo_members (keo_id, user_id, role, join_status, confirmed)
select k.id, k.host_id, 'host', 'approved', true
from public.keo k
where k.title = 'Kèo hát V-Pop trung tâm (Sài Gòn)'
  and k.host_id = 'a0000000-0000-4000-8000-0000000000a2'::uuid
  and not exists (select 1 from public.keo_members m where m.keo_id = k.id and m.user_id = k.host_id);

-- HCM kèo #2
insert into public.keo (host_id, title, area_label, area_geo, time_window_start, time_window_end,
                        group_size_target, status, genres)
select 'a0000000-0000-4000-8000-0000000000a2'::uuid, 'Hát chữa lành tối Chủ Nhật (Sài Gòn)', 'Quận 3, TP.HCM',
       public.ST_SetSRID(public.ST_MakePoint(106.685, 10.782), 4326)::public.geography,
       now() + interval '2 days', now() + interval '2 days' + interval '2 hours',
       4, 'open', array['ballad','acoustic']
where not exists (select 1 from public.keo k
                  where k.title = 'Hát chữa lành tối Chủ Nhật (Sài Gòn)'
                    and k.host_id = 'a0000000-0000-4000-8000-0000000000a2'::uuid);

insert into public.keo_members (keo_id, user_id, role, join_status, confirmed)
select k.id, k.host_id, 'host', 'approved', true
from public.keo k
where k.title = 'Hát chữa lành tối Chủ Nhật (Sài Gòn)'
  and k.host_id = 'a0000000-0000-4000-8000-0000000000a2'::uuid
  and not exists (select 1 from public.keo_members m where m.keo_id = k.id and m.user_id = k.host_id);

-- TN kèo #1
insert into public.keo (host_id, title, area_label, area_geo, time_window_start, time_window_end,
                        group_size_target, status, genres)
select 'a0000000-0000-4000-8000-0000000000a3'::uuid, 'Kèo hát sinh viên (Thái Nguyên)', 'TP. Thái Nguyên',
       public.ST_SetSRID(public.ST_MakePoint(105.842, 21.594), 4326)::public.geography,
       now() + interval '2 days', now() + interval '2 days' + interval '2 hours',
       5, 'open', array['vpop','kpop']
where not exists (select 1 from public.keo k
                  where k.title = 'Kèo hát sinh viên (Thái Nguyên)'
                    and k.host_id = 'a0000000-0000-4000-8000-0000000000a3'::uuid);

insert into public.keo_members (keo_id, user_id, role, join_status, confirmed)
select k.id, k.host_id, 'host', 'approved', true
from public.keo k
where k.title = 'Kèo hát sinh viên (Thái Nguyên)'
  and k.host_id = 'a0000000-0000-4000-8000-0000000000a3'::uuid
  and not exists (select 1 from public.keo_members m where m.keo_id = k.id and m.user_id = k.host_id);

commit;
