do $$
begin
  alter type public.venue_suggestion add attribute lat double precision;
exception
  when duplicate_column then null;
end $$;

do $$
begin
  alter type public.venue_suggestion add attribute lng double precision;
exception
  when duplicate_column then null;
end $$;

create or replace function public.nearest_venues_for_keo(
  p_keo uuid,
  p_limit int default 5
)
returns setof public.venue_suggestion
language plpgsql
security definer
set search_path=''
as $$
declare
  mid public.geography;
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;

  select public.ST_GeometricMedian(public.ST_Collect(ul.location::public.geometry))::public.geography
    into mid
  from public.keo_members m
  join public.user_locations ul on ul.user_id = m.user_id
  where m.keo_id = p_keo
    and m.join_status = 'approved'
    and m.confirmed;

  return query
    select
      v.id,
      v.name,
      v.address,
      v.style_tag,
      v.photos,
      app_private.dist_band(public.ST_Distance(v.location, mid)) as distance_band,
      public.ST_Y(v.location::public.geometry)::double precision as lat,
      public.ST_X(v.location::public.geometry)::double precision as lng
    from public.venues v
    where v.is_active
    order by public.ST_Distance(v.location, mid) asc
    limit greatest(p_limit, 1);
end;
$$;
