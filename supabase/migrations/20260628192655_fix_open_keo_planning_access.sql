create or replace function app_private.in_keo(p_keo uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists (
    select 1
    from public.keo_members m
    join public.keo k on k.id = m.keo_id
    where m.keo_id = p_keo
      and m.user_id = auth.uid()
      and m.join_status = 'approved'
      and m.confirmed
      and k.status in ('open', 'full', 'planning', 'confirmed', 'done')
  );
$$;

grant select on table public.plans to authenticated;
