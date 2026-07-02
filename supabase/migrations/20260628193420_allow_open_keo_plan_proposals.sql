create or replace function public.propose_keo_plan(
  p_keo uuid,
  p_venue uuid,
  p_when timestamptz
)
returns uuid language plpgsql security definer set search_path='' as $$
declare
  pid uuid;
  keo_status text;
begin
  perform app_private.assert_host(p_keo);

  select status into keo_status
  from public.keo
  where id = p_keo;

  if keo_status not in ('open', 'full', 'planning') then
    raise exception 'keo_not_planning' using errcode='check_violation';
  end if;

  insert into public.plans(keo_id, venue_id, scheduled_at)
  values (p_keo, p_venue, p_when)
  returning id into pid;

  return pid;
end; $$;
