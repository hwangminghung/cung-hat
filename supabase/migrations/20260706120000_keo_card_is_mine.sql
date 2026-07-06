-- Interleave card Keo vao deck Doi (muc 13): can loai keo cua chinh minh.
do $$
begin
  alter type public.keo_card add attribute is_mine boolean cascade;
exception
  when duplicate_column then null;
end $$;

-- list_open_keos returns setof keo_card, so drop the function before altering the type.
-- Body copied verbatim from 0024_pro_keo.sql (the latest definition), plus one new
-- final select column: is_mine.
drop function if exists public.list_open_keos(int,int);
create or replace function public.list_open_keos(p_limit int default 30, p_radius_km int default 50)
returns setof public.keo_card language sql security definer set search_path='' as $$
  with me as (select location as loc from public.user_locations where user_id = auth.uid())
  select k.id, k.title, k.area_label,
         app_private.dist_band(public.ST_Distance(k.area_geo, me.loc)) as distance_band,
         k.time_window_start, k.time_window_end, k.group_size_target,
         (select count(*)::int from public.keo_members m
            where m.keo_id = k.id and m.join_status = 'approved') as slots_filled,
         k.genres,
         (select display_name from public.profiles p where p.id = k.host_id) as host_name,
         k.status,
         k.join_mode,
         exists (select 1 from public.keo_members m3
                   where m3.keo_id = k.id and m3.user_id = auth.uid()
                     and m3.join_status in ('requested','approved'))
           or k.host_id = auth.uid()  as is_mine
  from public.keo k cross join me
  where k.status = 'open'
    and k.soft_deleted_at is null
    and k.time_window_end > now()
    and public.ST_DWithin(k.area_geo, me.loc, p_radius_km * 1000)
    and not exists (select 1 from public.blocks b
                    where (b.blocker_id = auth.uid() and b.blocked_id = k.host_id)
                       or (b.blocker_id = k.host_id and b.blocked_id = auth.uid()))
  order by k.time_window_start asc
  limit greatest(p_limit, 1);
$$;
revoke execute on function public.list_open_keos(int,int) from public, anon;
grant execute on function public.list_open_keos(int,int) to authenticated;
