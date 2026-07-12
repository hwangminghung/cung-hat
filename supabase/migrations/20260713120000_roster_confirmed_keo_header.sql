-- Fix 2 gap mockup-14 tren man Chi tiet keo (so khop design 2026-07-13):
-- 1) get_keo_roster tra them cot `confirmed` — thieu no thi client khong biet
--    thanh vien da bam "Dong y tham gia" hay chua, nut confirm tro trang thai.
-- 2) get_keo_header: man chi tiet can gio + khu vuc cho CA keo khong con 'open'
--    (list_open_keos khong phu keo planning/full/confirmed; bang keo khong co
--    SELECT policy nen client khong the query truc tiep).

-- (1) Them attribute vao composite type: phai drop function phu thuoc truoc.
drop function public.get_keo_roster(uuid);
alter type public.keo_member_row add attribute confirmed boolean;

-- Giu NGUYEN gating [A-I3] cua 20260708140000: requested rows chi host va
-- chinh requester thay; nguoi khac chi thay approved.
create or replace function public.get_keo_roster(p_keo uuid)
returns setof public.keo_member_row language sql security definer set search_path='' as $$
  select m.user_id, p.display_name, p.age_verified, m.role, m.join_status, m.confirmed
  from public.keo_members m
  join public.profiles p on p.id = m.user_id
  where m.keo_id = p_keo
    and (m.join_status = 'approved'
         or (m.join_status = 'requested'
             and (m.user_id = auth.uid()
                  or exists (select 1 from public.keo k where k.id = p_keo and k.host_id = auth.uid()))))
  order by case m.role when 'host' then 0 else 1 end, m.joined_at;
$$;
revoke execute on function public.get_keo_roster(uuid) from public, anon;
grant execute on function public.get_keo_roster(uuid) to authenticated;

-- (2) Header keo cho man chi tiet. Cot alias khop JsonKey model `Keo` phia
-- Flutter (size_target). Gate: keo 'open' ai cung xem duoc (ngang list_open_keos);
-- keo da dong discovery thi chi host hoac nguoi co chan trong keo_members
-- (approved/requested — requester dang cho duyet van can thay gio/khu vuc).
create or replace function public.get_keo_header(p_keo uuid)
returns table (
  id uuid,
  title text,
  status text,
  join_mode text,
  time_window_start timestamptz,
  time_window_end timestamptz,
  area_label text,
  size_target int
) language sql security definer set search_path='' as $$
  select k.id, k.title, k.status, k.join_mode,
         k.time_window_start, k.time_window_end,
         k.area_label, k.group_size_target
  from public.keo k
  where k.id = p_keo
    and k.soft_deleted_at is null
    and (k.status = 'open'
         or k.host_id = auth.uid()
         or exists (select 1 from public.keo_members m
                    where m.keo_id = k.id
                      and m.user_id = auth.uid()
                      and m.join_status in ('approved', 'requested')));
$$;
revoke execute on function public.get_keo_header(uuid) from public, anon;
grant execute on function public.get_keo_header(uuid) to authenticated;
