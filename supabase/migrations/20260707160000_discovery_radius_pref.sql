-- Bo loc ban kinh kieu Tinder (feedback live 2026-07-07).
alter table public.discovery_prefs
  add column if not exists radius_km int not null default 50;
do $$ begin
  alter table public.discovery_prefs
    add constraint discovery_prefs_radius_range check (radius_km between 5 and 100);
exception when duplicate_object then null; end $$;

create or replace function public.set_discovery_radius(p_km int)
returns void language plpgsql security definer set search_path='' as $$
begin
  if p_km is null or p_km < 5 or p_km > 100 then
    raise exception 'radius_range' using errcode='check_violation';
  end if;
  insert into public.discovery_prefs (user_id, radius_km, updated_at)
  values (auth.uid(), p_km, now())
  on conflict (user_id) do update set radius_km = excluded.radius_km, updated_at = now();
end; $$;
revoke execute on function public.set_discovery_radius(int) from public, anon;
grant execute on function public.set_discovery_radius(int) to authenticated;

-- Getter gop (giu get_discovery_auto_expand cu cho tuong thich, client chuyen sang cai nay).
create or replace function public.get_discovery_prefs()
returns table (auto_expand boolean, radius_km int)
language sql security definer set search_path='' as $$
  select coalesce(dp.auto_expand, false), coalesce(dp.radius_km, 50)
  from (select 1) one
  left join public.discovery_prefs dp on dp.user_id = auth.uid();
$$;
revoke execute on function public.get_discovery_prefs() from public, anon;
grant execute on function public.get_discovery_prefs() to authenticated;
