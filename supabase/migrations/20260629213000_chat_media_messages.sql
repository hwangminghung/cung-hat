insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('chat-images', 'chat-images', false, 8388608, array['image/jpeg','image/png','image/webp']),
  ('chat-videos', 'chat-videos', false, 26214400, array['video/mp4','video/quicktime'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

alter table public.messages add column if not exists kind text not null default 'text';
alter table public.messages drop constraint if exists messages_kind_check;
alter table public.messages add constraint messages_kind_check
  check (kind in ('text','image','video'));
alter table public.messages alter column body drop not null;
alter table public.messages drop constraint if exists messages_body_check;
alter table public.messages drop constraint if exists messages_kind_body_check;
alter table public.messages add constraint messages_kind_body_check check (
  (kind = 'text' and body is not null and char_length(body) between 1 and 2000)
  or
  (kind in ('image','video') and body is null)
);

create table if not exists public.message_attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid references public.messages(id) on delete cascade deferrable initially deferred,
  thread_type text not null check (thread_type in ('match','keo')),
  thread_id uuid not null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  media_type text not null check (media_type in ('image','video')),
  bucket_id text not null check (bucket_id in ('chat-images','chat-videos')),
  object_path text not null,
  thumbnail_bucket_id text,
  thumbnail_path text,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes > 0),
  width integer,
  height integer,
  duration_ms integer,
  status text not null default 'pending' check (status in ('pending','attached','hidden','deleted')),
  created_at timestamptz not null default now(),
  attached_at timestamptz,
  soft_deleted_at timestamptz,
  delete_after timestamptz default now() + interval '24 hours',
  deleted_at timestamptz,
  unique (bucket_id, object_path),
  check (
    (media_type='image' and bucket_id='chat-images')
    or
    (media_type='video' and bucket_id='chat-videos')
  )
);

create index if not exists message_attachments_message_ix on public.message_attachments(message_id);
create index if not exists message_attachments_thread_ix on public.message_attachments(thread_type, thread_id, created_at);
create index if not exists message_attachments_cleanup_ix on public.message_attachments(delete_after)
  where deleted_at is null;

alter table public.message_attachments enable row level security;

create or replace function app_private.can_access_chat_thread(p_thread_type text, p_thread uuid)
returns boolean language sql security definer set search_path='' stable as $$
  select case
    when p_thread_type = 'match' then app_private.in_match(p_thread)
    when p_thread_type = 'keo' then app_private.in_keo(p_thread)
    else false
  end;
$$;

drop policy if exists message_attachments_select_thread on public.message_attachments;
create policy message_attachments_select_thread on public.message_attachments
for select to authenticated
using (
  (
    status = 'pending'
    and owner_id = auth.uid()
  )
  or (
    status in ('attached','hidden')
    and app_private.can_access_chat_thread(thread_type, thread_id)
  )
);

do $$
begin
  if not exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typname = 'message_attachment_upload'
  ) then
    create type public.message_attachment_upload as (
      id uuid,
      bucket_id text,
      object_path text
    );
  end if;
end $$;

create or replace function app_private.validate_chat_media(
  p_media_type text,
  p_mime_type text,
  p_size_bytes bigint,
  p_duration_ms integer
) returns void language plpgsql security definer set search_path='' as $$
begin
  if p_size_bytes is null or p_size_bytes <= 0 then
    raise exception 'invalid_media_size' using errcode='check_violation';
  end if;

  if p_media_type = 'image' then
    if p_mime_type <> all(array['image/jpeg','image/png','image/webp']) then
      raise exception 'unsupported_media_type' using errcode='check_violation';
    end if;
    if p_size_bytes > 8388608 then
      raise exception 'media_too_large' using errcode='check_violation';
    end if;
  elsif p_media_type = 'video' then
    if p_mime_type <> all(array['video/mp4','video/quicktime']) then
      raise exception 'unsupported_media_type' using errcode='check_violation';
    end if;
    if p_size_bytes > 26214400 then
      raise exception 'media_too_large' using errcode='check_violation';
    end if;
    if coalesce(p_duration_ms, 0) <= 0 or p_duration_ms > 60000 then
      raise exception 'video_too_long' using errcode='check_violation';
    end if;
  else
    raise exception 'unsupported_media_type' using errcode='check_violation';
  end if;
end;
$$;

create or replace function app_private.chat_media_extension(p_mime_type text)
returns text language sql immutable set search_path='' as $$
  select case p_mime_type
    when 'image/jpeg' then 'jpg'
    when 'image/png' then 'png'
    when 'image/webp' then 'webp'
    when 'video/mp4' then 'mp4'
    when 'video/quicktime' then 'mov'
    else 'bin'
  end;
$$;

create or replace function public.create_message_attachment(
  p_thread_type text,
  p_thread uuid,
  p_media_type text,
  p_mime_type text,
  p_size_bytes bigint,
  p_width integer default null,
  p_height integer default null,
  p_duration_ms integer default null
) returns public.message_attachment_upload
language plpgsql security definer set search_path='' as $$
declare
  aid uuid := gen_random_uuid();
  bucket text := case when p_media_type = 'image' then 'chat-images' else 'chat-videos' end;
  object_name text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode='check_violation';
  end if;
  if not app_private.can_access_chat_thread(p_thread_type, p_thread) then
    raise exception 'not_in_thread' using errcode='check_violation';
  end if;
  perform app_private.validate_chat_media(p_media_type, p_mime_type, p_size_bytes, p_duration_ms);

  object_name := p_thread_type || '/' || p_thread::text || '/' || auth.uid()::text || '/' ||
    aid::text || '.' || app_private.chat_media_extension(p_mime_type);

  insert into public.message_attachments(
    id, thread_type, thread_id, owner_id, media_type, bucket_id, object_path,
    mime_type, size_bytes, width, height, duration_ms
  ) values (
    aid, p_thread_type, p_thread, auth.uid(), p_media_type, bucket, object_name,
    p_mime_type, p_size_bytes, p_width, p_height, p_duration_ms
  );

  return (aid, bucket, object_name)::public.message_attachment_upload;
end;
$$;

create or replace function public.send_media_message(p_attachment uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare
  a public.message_attachments;
  o storage.objects;
  object_mime text;
  mid uuid := gen_random_uuid();
begin
  select * into a from public.message_attachments where id = p_attachment for update;
  if not found then raise exception 'attachment_not_found' using errcode='no_data_found'; end if;
  if a.owner_id <> auth.uid() then raise exception 'not_attachment_owner' using errcode='check_violation'; end if;
  if a.status <> 'pending' then raise exception 'attachment_not_pending' using errcode='check_violation'; end if;
  if not app_private.can_access_chat_thread(a.thread_type, a.thread_id) then
    raise exception 'not_in_thread' using errcode='check_violation';
  end if;
  perform app_private.validate_chat_media(a.media_type, a.mime_type, a.size_bytes, a.duration_ms);

  select * into o
  from storage.objects so
  where so.bucket_id = a.bucket_id and so.name = a.object_path;
  if not found then
    raise exception 'storage_object_missing' using errcode='check_violation';
  end if;
  if not (
    coalesce(o.owner = auth.uid(), false)
    or coalesce(o.owner_id = auth.uid()::text, false)
  ) then
    raise exception 'storage_object_mismatch' using errcode='check_violation';
  end if;
  if o.metadata ? 'size' and (o.metadata->>'size')::bigint <> a.size_bytes then
    raise exception 'storage_object_mismatch' using errcode='check_violation';
  end if;
  object_mime := coalesce(o.metadata->>'mimetype', o.metadata->>'mime_type');
  if object_mime is not null and object_mime <> a.mime_type then
    raise exception 'storage_object_mismatch' using errcode='check_violation';
  end if;

  perform app_private.enforce_rate_limit('message', 60, interval '1 minute');
  perform app_private.enforce_rate_limit('media_message', 20, interval '1 day');

  update public.message_attachments
    set message_id = mid, status = 'attached', attached_at = now(), delete_after = null
    where id = a.id;

  insert into public.messages(id, thread_type, thread_id, sender_id, kind, body)
  values (mid, a.thread_type, a.thread_id, auth.uid(), a.media_type, null);

  return mid;
end;
$$;

create or replace function public.delete_message(p_message uuid)
returns void language plpgsql security definer set search_path='' as $$
declare
  m public.messages;
begin
  select * into m from public.messages where id = p_message for update;
  if not found then raise exception 'message_not_found' using errcode='no_data_found'; end if;
  if m.sender_id <> auth.uid() then raise exception 'not_message_owner' using errcode='check_violation'; end if;

  update public.messages
    set hidden = true, soft_deleted_at = now()
    where id = p_message;

  update public.message_attachments
    set status = 'hidden',
        soft_deleted_at = now(),
        delete_after = now() + interval '30 days'
    where message_id = p_message and status <> 'deleted';
end;
$$;

create or replace function app_private.message_payload(p_message public.messages)
returns jsonb language sql security definer set search_path='' stable as $$
  select jsonb_build_object(
    'id', p_message.id,
    'thread_id', p_message.thread_id,
    'sender_id', p_message.sender_id,
    'body', p_message.body,
    'kind', p_message.kind,
    'hidden', p_message.hidden,
    'created_at', p_message.created_at,
    'attachment', (
      select case when a.id is null then null else jsonb_build_object(
        'id', a.id,
        'message_id', a.message_id,
        'media_type', a.media_type,
        'bucket_id', a.bucket_id,
        'object_path', a.object_path,
        'thumbnail_bucket_id', a.thumbnail_bucket_id,
        'thumbnail_path', a.thumbnail_path,
        'mime_type', a.mime_type,
        'size_bytes', a.size_bytes,
        'width', a.width,
        'height', a.height,
        'duration_ms', a.duration_ms,
        'status', a.status
      ) end
      from public.message_attachments a
      where a.message_id = p_message.id
      limit 1
    )
  );
$$;

create or replace function app_private.broadcast_message()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  begin
    perform realtime.send(
      app_private.message_payload(new),
      'new_message',
      new.thread_type || ':' || new.thread_id::text,
      true
    );
  exception when others then
    null;
  end;
  return new;
end;
$$;

drop policy if exists "chat media pending upload insert" on storage.objects;
create policy "chat media pending upload insert"
on storage.objects for insert to authenticated
with check (
  exists (
    select 1 from public.message_attachments a
    where a.bucket_id = storage.objects.bucket_id
      and a.object_path = storage.objects.name
      and a.owner_id = auth.uid()
      and a.status = 'pending'
  )
);

drop policy if exists "chat media thread member read" on storage.objects;
create policy "chat media thread member read"
on storage.objects for select to authenticated
using (
  exists (
    select 1 from public.message_attachments a
    where a.bucket_id = storage.objects.bucket_id
      and a.object_path = storage.objects.name
      and a.status = 'attached'
      and app_private.can_access_chat_thread(a.thread_type, a.thread_id)
  )
);

create or replace function public.chat_media_cleanup_candidates(p_limit integer default 100)
returns setof public.message_attachments
language sql security definer set search_path='' as $$
  select * from public.message_attachments
  where delete_after is not null and delete_after <= now() and deleted_at is null
  order by delete_after asc
  limit greatest(p_limit, 1);
$$;

create or replace function public.admin_action_report(p_report uuid, p_action text, p_reason text default null)
returns void language plpgsql security definer set search_path='' as $$
declare r public.reports;
begin
  if not app_private.is_admin() then raise exception 'not_admin' using errcode='check_violation'; end if;
  select * into r from public.reports where id = p_report;
  if not found then raise exception 'no_report' using errcode='no_data_found'; end if;

  if p_action in ('hide','remove') then
    if r.target_type = 'message' then
      update public.messages set hidden = true,
        soft_deleted_at = case when p_action = 'remove' then now() else soft_deleted_at end
        where id = r.target_id::uuid;
      update public.message_attachments set
        status = 'hidden',
        soft_deleted_at = coalesce(soft_deleted_at, now()),
        delete_after = case
          when p_action = 'remove' then now() + interval '7 days'
          else delete_after
        end
        where message_id = r.target_id::uuid and status <> 'deleted';
    elsif r.target_type = 'keo' then
      update public.keo set soft_deleted_at = now(), status = 'cancelled' where id = r.target_id::uuid;
    elsif r.target_type = 'profile' then
      update public.profiles set soft_deleted_at = now(), report_risk = report_risk + 1 where id = r.target_id::uuid;
    else
      raise exception 'unhandled_target_type' using errcode='check_violation';
    end if;
    update public.reports set status = 'actioned' where id = p_report;
  elsif p_action = 'dismiss' then
    update public.reports set status = 'dismissed' where id = p_report;
  else
    raise exception 'bad_action' using errcode='check_violation';
  end if;

  insert into public.moderation_audit(actor, action, target_type, target_id, reason)
  values (auth.uid(), p_action, r.target_type, r.target_id, p_reason);
end; $$;

create or replace function public.request_account_deletion()
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.profiles
    set soft_deleted_at = now(), tombstone = true,
        display_name = U&'Ng\01B0\1EDDi d\00F9ng \0111\00E3 r\1EDDi', full_name = null, bio = null
    where id = auth.uid();
  update public.keo set status = 'cancelled', soft_deleted_at = now() where host_id = auth.uid() and status <> 'done';
  update public.keo_members set join_status = 'left' where user_id = auth.uid();
  update public.matches set status = 'unmatched', unmatched_at = now() where user_a = auth.uid() or user_b = auth.uid();
  update public.messages set hidden = true where sender_id = auth.uid();
  update public.message_attachments
    set status = 'hidden', soft_deleted_at = now(), delete_after = now() + interval '30 days'
    where owner_id = auth.uid() and status <> 'deleted';
  update public.plans set status = 'cancelled'
    where status <> 'done'
      and keo_id in (select id from public.keo where host_id = auth.uid());
end; $$;

revoke execute on function app_private.validate_chat_media(text,text,bigint,integer) from public, anon, authenticated;
revoke execute on function app_private.chat_media_extension(text) from public, anon, authenticated;
revoke execute on function app_private.message_payload(public.messages) from public, anon, authenticated;
revoke execute on function app_private.broadcast_message() from public, anon, authenticated;
revoke execute on function app_private.can_access_chat_thread(text,uuid) from public, anon;
grant execute on function app_private.can_access_chat_thread(text,uuid) to authenticated;

revoke execute on function public.create_message_attachment(text,uuid,text,text,bigint,integer,integer,integer) from public, anon;
revoke execute on function public.send_media_message(uuid) from public, anon;
revoke execute on function public.delete_message(uuid) from public, anon;
revoke execute on function public.chat_media_cleanup_candidates(integer) from public, anon, authenticated;
revoke execute on function public.admin_action_report(uuid,text,text) from public, anon;
revoke execute on function public.request_account_deletion() from public, anon;

grant execute on function public.create_message_attachment(text,uuid,text,text,bigint,integer,integer,integer) to authenticated;
grant execute on function public.send_media_message(uuid) to authenticated;
grant execute on function public.delete_message(uuid) to authenticated;
grant execute on function public.admin_action_report(uuid,text,text) to authenticated;
grant execute on function public.request_account_deletion() to authenticated;
grant execute on function public.chat_media_cleanup_candidates(integer) to service_role;

grant select on public.messages to authenticated;
grant select on public.message_attachments to authenticated;
