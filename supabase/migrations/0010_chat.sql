create table public.messages (
  id uuid primary key default gen_random_uuid(),
  thread_type text not null check (thread_type in ('match','keo')),
  thread_id uuid not null,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  hidden boolean not null default false,
  created_at timestamptz not null default now(),
  soft_deleted_at timestamptz
);
create index messages_thread_ix on public.messages(thread_type, thread_id, created_at);
alter table public.messages enable row level security;

-- Helper: is the caller a participant of this match thread?
create or replace function app_private.in_match(p_thread uuid)
returns boolean language sql security definer set search_path='' stable as $$
  select exists (select 1 from public.matches m
                 where m.id = p_thread and m.status='active'
                   and (m.user_a = auth.uid() or m.user_b = auth.uid()));
$$;

-- Read own threads' messages (participant only). Inserts go through send_message RPC only.
create policy messages_select_participant on public.messages for select
  using (thread_type='match' and app_private.in_match(thread_id));

create table public.message_reads (
  thread_type text not null check (thread_type in ('match','keo')),
  thread_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (thread_type, thread_id, user_id)
);
alter table public.message_reads enable row level security;
create policy message_reads_self on public.message_reads for all
  using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- Broadcast each insert to the private topic match:{id}
create or replace function app_private.broadcast_message()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  begin
    perform realtime.send(
      jsonb_build_object('id', new.id, 'thread_id', new.thread_id,
        'sender_id', new.sender_id, 'body', new.body, 'created_at', new.created_at),
      'new_message',
      new.thread_type || ':' || new.thread_id::text,
      true   -- private channel
    );
  exception when others then
    null; -- broadcast is best-effort; the message is already durably inserted
  end;
  return new;
end; $$;
create trigger messages_broadcast after insert on public.messages
  for each row execute function app_private.broadcast_message();

-- Send (membership-checked + rate-limited)
create or replace function public.send_message(p_thread uuid, p_body text)
returns uuid language plpgsql security definer set search_path='' as $$
declare mid uuid;
begin
  if not app_private.in_match(p_thread) then
    raise exception 'not_a_member' using errcode='check_violation';
  end if;
  perform app_private.enforce_rate_limit('message', 60, interval '1 minute');
  insert into public.messages(thread_type, thread_id, sender_id, body)
  values ('match', p_thread, auth.uid(), p_body) returning id into mid;
  return mid;
end; $$;

create or replace function public.mark_match_read(p_thread uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.message_reads(thread_type, thread_id, user_id)
  values ('match', p_thread, auth.uid())
  on conflict (thread_type, thread_id, user_id) do update set last_read_at = now();
end; $$;

revoke execute on function public.send_message(uuid,text) from public, anon;
revoke execute on function public.mark_match_read(uuid) from public, anon;
grant execute on function public.send_message(uuid,text) to authenticated;
grant execute on function public.mark_match_read(uuid) to authenticated;

-- Realtime authorization: only match members may receive on the private topic.
create policy "match members receive broadcasts"
  on realtime.messages for select to authenticated
  using (
    exists (select 1 from public.matches m
            where 'match:' || m.id::text = realtime.topic()
              and m.status='active'
              and (m.user_a = auth.uid() or m.user_b = auth.uid()))
  );
