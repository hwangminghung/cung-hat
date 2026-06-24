-- Kèo (group karaoke meetup) board: keo + keo_members + create/list/roster RPCs.
-- PostGIS note: postgis is installed into the `public` schema (see 0001_foundation.sql),
-- and every function uses `set search_path=''`, so EVERY PostGIS symbol — the geography
-- type AND all ST_* functions — must be schema-qualified as `public.*`, mirroring
-- 0006_locations.sql.

create table public.keo (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 100),
  area_label text,
  area_geo public.geography(Point,4326) not null,
  time_window_start timestamptz not null,
  time_window_end timestamptz not null,
  group_size_target int not null check (group_size_target between 2 and 5),
  intent_tag text,
  vibe text,
  genres text[] not null default '{}',
  status text not null default 'open'
    check (status in ('open','full','planning','confirmed','done','cancelled')),
  created_at timestamptz not null default now(),
  soft_deleted_at timestamptz,
  check (time_window_end > time_window_start)
);
create index keo_geo_gix on public.keo using gist (area_geo);
alter table public.keo enable row level security;
create policy keo_host_write on public.keo for all
  using (auth.uid() = host_id) with check (auth.uid() = host_id);

create table public.keo_members (
  keo_id uuid references public.keo(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('host','member')),
  join_status text not null default 'requested'
    check (join_status in ('requested','approved','declined','left')),
  confirmed boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (keo_id, user_id)
);
alter table public.keo_members enable row level security;
create policy keo_members_self on public.keo_members for select
  using (auth.uid() = user_id
         or exists (select 1 from public.keo k where k.id = keo_id and k.host_id = auth.uid()));

create or replace function public.create_keo(
  p_title text, p_lat double precision, p_lng double precision, p_area text,
  p_start timestamptz, p_end timestamptz, p_size int, p_intent text, p_vibe text, p_genres text[]
) returns uuid language plpgsql security definer set search_path='' as $$
declare kid uuid;
begin
  perform app_private.enforce_rate_limit('create_keo', 10, interval '1 day');
  insert into public.keo(host_id, title, area_label, area_geo, time_window_start, time_window_end,
                         group_size_target, intent_tag, vibe, genres)
  values (auth.uid(), p_title, p_area,
          public.ST_SetSRID(public.ST_MakePoint(round(p_lng::numeric,3)::double precision,
                                  round(p_lat::numeric,3)::double precision),4326)::public.geography,
          p_start, p_end, p_size, p_intent, p_vibe, coalesce(p_genres,'{}'))
  returning id into kid;
  insert into public.keo_members(keo_id, user_id, role, join_status, confirmed)
  values (kid, auth.uid(), 'host', 'approved', true);
  return kid;
end; $$;

create type public.keo_card as (
  id uuid, title text, area_label text, distance_band text,
  time_window_start timestamptz, time_window_end timestamptz,
  size_target int, slots_filled int, genres text[], host_name text, status text
);

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
         k.status
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

create type public.keo_member_row as (user_id uuid, display_name text, verified boolean, role text, join_status text);
create or replace function public.get_keo_roster(p_keo uuid)
returns setof public.keo_member_row language sql security definer set search_path='' as $$
  select m.user_id, p.display_name, p.age_verified, m.role, m.join_status
  from public.keo_members m
  join public.profiles p on p.id = m.user_id
  where m.keo_id = p_keo and m.join_status in ('approved','requested')
  order by case m.role when 'host' then 0 else 1 end, m.joined_at;
$$;

revoke execute on function public.create_keo(text,double precision,double precision,text,timestamptz,timestamptz,int,text,text,text[]) from public, anon;
revoke execute on function public.list_open_keos(int,int) from public, anon;
revoke execute on function public.get_keo_roster(uuid) from public, anon;
grant execute on function public.create_keo(text,double precision,double precision,text,timestamptz,timestamptz,int,text,text,text[]) to authenticated;
grant execute on function public.list_open_keos(int,int) to authenticated;
grant execute on function public.get_keo_roster(uuid) to authenticated;
