-- Private user locations. Exact coords are never client-readable; access via RPC only.
-- PostGIS note: in this project postgis is installed into the `public` schema
-- (see 0001_foundation.sql `create extension if not exists postgis;` which lands in
-- public). Because the functions below use `set search_path=''`, every PostGIS symbol
-- (functions AND the geography type) must be schema-qualified as `public.*`, otherwise
-- it fails to resolve under the empty search_path.

create table public.user_locations (
  user_id uuid primary key references auth.users(id) on delete cascade,
  location public.geography(Point,4326) not null,
  area_label text,
  updated_at timestamptz not null default now()
);
create index user_locations_gix on public.user_locations using gist (location);
alter table public.user_locations enable row level security;
-- No client policy at all → exact coords are never directly selectable. Access via RPC only.

-- Distance → privacy band (the only distance form clients ever see).
create or replace function app_private.dist_band(m double precision)
returns text language sql immutable set search_path='' as $$
  select case when m < 1000 then '<1' when m < 3000 then '1-3'
              when m < 5000 then '3-5' else '5+' end;
$$;

-- Snap to ~100m at write (k-anonymity), store the snapped point only.
create or replace function public.update_my_location(p_lat double precision, p_lng double precision, p_area text default null)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.user_locations (user_id, location, area_label)
  values (
    auth.uid(),
    public.ST_SetSRID(public.ST_MakePoint(round(p_lng::numeric, 3)::double precision,
                            round(p_lat::numeric, 3)::double precision), 4326)::public.geography,
    p_area)
  on conflict (user_id) do update
    set location = excluded.location, area_label = excluded.area_label, updated_at = now();
  update public.profiles set last_active = now() where id = auth.uid();  -- drives "active_today" in discovery
end; $$;
revoke execute on function public.update_my_location(double precision,double precision,text) from public, anon;
grant execute on function public.update_my_location(double precision,double precision,text) to authenticated;
