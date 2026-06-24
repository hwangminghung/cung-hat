-- Venues catalog + seed + midpoint venue picker for kèo groups.
-- PostGIS note: postgis is installed into the `public` schema (see 0001_foundation.sql),
-- and the function below uses `set search_path=''`, so EVERY PostGIS symbol — the geography
-- type, the geometry cast, and all ST_* functions — must be schema-qualified as `public.*`,
-- mirroring 0006_locations.sql / 0012_keo.sql. The KNN `<->` operator likewise cannot
-- resolve under an empty search_path, so the picker orders by public.ST_Distance(...) instead
-- (the venue table is tiny — correctness over the KNN index).

create table public.venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null,
  city text not null check (city in ('HCM','HN','TN')),
  location public.geography(Point,4326) not null,
  style_tag text not null default 'k_style' check (style_tag in ('k_style','family','bar_karaoke')),
  photos text[] not null default '{}',
  source text not null default 'seed' check (source in ('seed','places')),
  places_id text,
  is_active boolean not null default true
);
create index venues_geo_gix on public.venues using gist (location);
alter table public.venues enable row level security;
create policy venues_read on public.venues for select using (is_active);

insert into public.venues (name, address, city, location, style_tag) values
  ('Kingdom Karaoke','Q1, TP.HCM','HCM', public.ST_SetSRID(public.ST_MakePoint(106.700,10.776),4326)::public.geography,'k_style'),
  ('Nnice Karaoke','Bình Thạnh, TP.HCM','HCM', public.ST_SetSRID(public.ST_MakePoint(106.712,10.804),4326)::public.geography,'k_style'),
  ('Kpop Karaoke','Cầu Giấy, Hà Nội','HN', public.ST_SetSRID(public.ST_MakePoint(105.795,21.030),4326)::public.geography,'k_style'),
  ('Idol Karaoke','Đống Đa, Hà Nội','HN', public.ST_SetSRID(public.ST_MakePoint(105.825,21.012),4326)::public.geography,'k_style'),
  ('Sao Mai Karaoke','TP. Thái Nguyên','TN', public.ST_SetSRID(public.ST_MakePoint(105.842,21.594),4326)::public.geography,'k_style'),
  ('Galaxy Karaoke','ĐH Thái Nguyên','TN', public.ST_SetSRID(public.ST_MakePoint(105.800,21.567),4326)::public.geography,'k_style');

create type public.venue_suggestion as (
  id uuid, name text, address text, style_tag text, photos text[], distance_band text
);

create or replace function public.nearest_venues_for_keo(p_keo uuid, p_limit int default 5)
returns setof public.venue_suggestion language plpgsql security definer set search_path='' as $$
declare mid public.geography;
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;
  select public.ST_GeometricMedian(public.ST_Collect(ul.location::public.geometry))::public.geography
    into mid
  from public.keo_members m
  join public.user_locations ul on ul.user_id = m.user_id
  where m.keo_id = p_keo and m.join_status='approved' and m.confirmed;

  return query
    select v.id, v.name, v.address, v.style_tag, v.photos,
           app_private.dist_band(public.ST_Distance(v.location, mid)) as distance_band
    from public.venues v
    where v.is_active
    order by public.ST_Distance(v.location, mid) asc
    limit greatest(p_limit, 1);
end; $$;
revoke execute on function public.nearest_venues_for_keo(uuid,int) from public, anon;
grant execute on function public.nearest_venues_for_keo(uuid,int) to authenticated;
