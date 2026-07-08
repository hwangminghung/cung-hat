-- Midpoint da tinh cua nhom (ST_GeometricMedian) cho map PlanScreen.
-- RIENG TU: chi tra diem giua da snap round(,3) ~110m — cung muc snap voi
-- user_locations luc ghi; KHONG BAO GIO tra vi tri tung thanh vien.
create or replace function public.get_keo_midpoint(p_keo uuid)
returns table (lat double precision, lng double precision)
language plpgsql
security definer
set search_path=''
as $$
declare
  mid public.geometry;
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;

  select public.ST_GeometricMedian(public.ST_Collect(ul.location::public.geometry))
    into mid
  from public.keo_members m
  join public.user_locations ul on ul.user_id = m.user_id
  where m.keo_id = p_keo
    and m.join_status = 'approved'
    and m.confirmed;

  if mid is null then
    return;
  end if;

  return query select
    round(public.ST_Y(mid)::numeric, 3)::double precision,
    round(public.ST_X(mid)::numeric, 3)::double precision;
end;
$$;

revoke execute on function public.get_keo_midpoint(uuid) from public, anon;
grant execute on function public.get_keo_midpoint(uuid) to authenticated;
