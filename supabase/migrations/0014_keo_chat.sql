-- Caller is an approved+confirmed member of a keo whose group is open (planning+).
create or replace function app_private.in_keo(p_keo uuid)
returns boolean language sql security definer set search_path='' stable as $$
  select exists (
    select 1 from public.keo_members m
    join public.keo k on k.id = m.keo_id
    where m.keo_id = p_keo and m.user_id = auth.uid()
      and m.join_status = 'approved' and m.confirmed
      and k.status in ('planning','confirmed','done')
  );
$$;

-- keo messages readable by in-keo members (reuses the shared messages table + generic broadcast trigger)
create policy messages_select_keo on public.messages for select
  using (thread_type='keo' and app_private.in_keo(thread_id));

create or replace function public.send_keo_message(p_keo uuid, p_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare mid uuid;
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;
  perform app_private.enforce_rate_limit('message', 60, interval '1 minute');
  insert into public.messages(thread_type, thread_id, sender_id, body)
  values ('keo', p_keo, auth.uid(), p_body) returning id into mid;
  return mid;
end; $$;

create or replace function public.mark_keo_read(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.message_reads(thread_type, thread_id, user_id)
  values ('keo', p_keo, auth.uid())
  on conflict (thread_type, thread_id, user_id) do update set last_read_at = now();
end; $$;

revoke execute on function public.send_keo_message(uuid,text) from public, anon;
revoke execute on function public.mark_keo_read(uuid) from public, anon;
grant execute on function public.send_keo_message(uuid,text) to authenticated;
grant execute on function public.mark_keo_read(uuid) to authenticated;

-- Realtime authorization for the private keo topic
create policy "keo members receive broadcasts"
  on realtime.messages for select to authenticated
  using (
    exists (
      select 1 from public.keo_members m
      where 'keo:' || m.keo_id::text = realtime.topic()
        and m.user_id = auth.uid() and m.join_status='approved' and m.confirmed
    )
  );
