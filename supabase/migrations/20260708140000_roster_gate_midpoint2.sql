-- [A-I3] requested rows chi host VA chinh requester thay; nguoi khac chi thay approved
-- (giu preview san pham). Requester phai thay row cua minh: KeoDetailScreen lay _myRow
-- tu roster; thieu no thi nut "Xin vao keo" hien lai voi nguoi dang cho duyet.
create or replace function public.get_keo_roster(p_keo uuid)
returns setof public.keo_member_row language sql security definer set search_path='' as $$
  select m.user_id, p.display_name, p.age_verified, m.role, m.join_status
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

-- [A-M3] midpoint doi >= 2 thanh vien co vi tri (1 nguoi = lo vi tri ~110m cua chinh ho).
create or replace function public.get_keo_midpoint(p_keo uuid)
returns table (lat double precision, lng double precision)
language plpgsql security definer set search_path='' as $$
declare mid public.geometry;
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;
  select case when count(ul.user_id) >= 2
              then public.ST_GeometricMedian(public.ST_Collect(ul.location::public.geometry)) end
    into mid
  from public.keo_members m
  join public.user_locations ul on ul.user_id = m.user_id
  where m.keo_id = p_keo and m.join_status = 'approved' and m.confirmed;
  if mid is null then return; end if;
  return query select
    round(public.ST_Y(mid)::numeric, 3)::double precision,
    round(public.ST_X(mid)::numeric, 3)::double precision;
end; $$;
revoke execute on function public.get_keo_midpoint(uuid) from public, anon;
grant execute on function public.get_keo_midpoint(uuid) to authenticated;
