-- Two-stage sanitized discovery scorer (P1-T3).
-- PostGIS note: postgis lives in the `public` schema in this DB (see 0006_locations.sql).
-- Because get_discovery_candidates uses `set search_path=''`, every PostGIS symbol must
-- be schema-qualified `public.*` — here `public.ST_Distance` and `public.ST_DWithin`.
-- The geography columns are already `public.geography`.

-- profiles columns the scorer reads (must exist BEFORE the type/function below).
alter table public.profiles add column if not exists verified_badge boolean not null default false;
alter table public.profiles add column if not exists report_risk numeric not null default 0;

-- swipes table created HERE (0008) so get_discovery_candidates below can reference it.
create table public.swipes (
  swiper_id uuid references auth.users(id) on delete cascade,
  target_type text not null check (target_type in ('user','keo')),
  target_id text not null,
  direction text not null check (direction in ('like','pass','super','save')),
  created_at timestamptz not null default now(),
  primary key (swiper_id, target_type, target_id)
);
alter table public.swipes enable row level security; -- writes via RPC only

create table public.ranking_weights (key text primary key, weight numeric not null);
alter table public.ranking_weights enable row level security; -- no client policy
insert into public.ranking_weights(key, weight) values
  ('music', 3.0), ('nearness', 1.5), ('activity', 1.0), ('report_risk', 2.0);

-- Sanitized candidate row = the privacy boundary (NO coords, NO score, NO weights).
create type public.discovery_candidate as (
  id uuid, display_name text, age int, distance_band text,
  shared_genres text[], shared_baitu text[], verified boolean, active_today boolean
);

create or replace function public.get_discovery_candidates(p_limit int default 20, p_radius_km int default 50)
returns setof public.discovery_candidate
language sql security definer set search_path='' as $$
  with me as (
    select l.location as loc,
      (select array_agg(genre_id) from public.user_genres where user_id = auth.uid()) as genres,
      (select array_agg(song_id) from public.user_baitu where user_id = auth.uid()) as songs
    from public.user_locations l where l.user_id = auth.uid()
  ),
  cand as (
    select p.id, p.display_name, p.dob, p.verified_badge as verified, p.last_active,
           coalesce(p.report_risk, 0) as report_risk,
           public.ST_Distance(ul.location, me.loc) as dist_m,
           (select array_agg(g.genre_id) from public.user_genres g
              where g.user_id = p.id and g.genre_id = any(me.genres)) as shared_g,
           (select array_agg(s.song_id) from public.user_baitu s
              where s.user_id = p.id and s.song_id = any(me.songs)) as shared_s
    from public.profiles p
    join public.user_locations ul on ul.user_id = p.id
    cross join me
    where p.id <> auth.uid()
      and p.soft_deleted_at is null
      and public.ST_DWithin(ul.location, me.loc, p_radius_km * 1000)
      and not exists (select 1 from public.blocks b
                        where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
                           or (b.blocker_id = p.id and b.blocked_id = auth.uid()))
      and not exists (select 1 from public.swipes sw
                        where sw.swiper_id = auth.uid() and sw.target_type = 'user' and sw.target_id = p.id::text)
  )
  select c.id, c.display_name,
         extract(year from age(c.dob))::int as age,
         app_private.dist_band(c.dist_m) as distance_band,
         coalesce(c.shared_g, '{}') as shared_genres,
         coalesce(c.shared_s, '{}') as shared_baitu,
         c.verified, (c.last_active > now() - interval '1 day') as active_today
  from cand c
  order by (
      (select weight from public.ranking_weights where key='music') * coalesce(array_length(c.shared_g,1),0)
    + (select weight from public.ranking_weights where key='nearness') * (1.0 / (1 + c.dist_m/1000))
    + (select weight from public.ranking_weights where key='activity') * (case when c.last_active > now() - interval '1 day' then 1 else 0 end)
    - (select weight from public.ranking_weights where key='report_risk') * c.report_risk
  ) desc
  limit greatest(p_limit, 1);
$$;
revoke execute on function public.get_discovery_candidates(int,int) from public, anon;
grant execute on function public.get_discovery_candidates(int,int) to authenticated;
