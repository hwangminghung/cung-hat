# Chat Media Messages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one-photo-or-one-video messages to 1:1 match chat and keo group chat with private Supabase Storage, metadata-backed message attachments, deletion retention, and emulator-verifiable UI.

**Architecture:** Supabase remains the source of truth: `messages` stores the durable chat event and a new `message_attachments` table stores private Storage metadata. Flutter uses a small media upload service to create a pending attachment, upload to Storage, attach it through an RPC, then renders the returned metadata in shared chat UI components.

**Tech Stack:** Flutter, Riverpod, freezed/json_serializable, supabase_flutter, Supabase Postgres/RLS/RPC, Supabase Storage private buckets, Supabase Edge Functions for physical cleanup.

## Global Constraints

- MVP supports exactly one media attachment per message.
- A message can be text, one image, or one video; albums and captions are out of scope.
- Support both 1:1 match chat and keo group chat.
- Image MIME types: `image/jpeg`, `image/png`, `image/webp`; max image size: `8MiB`.
- Video MIME types: `video/mp4`, `video/quicktime`; max video size: `25MiB`; max video duration: `60 seconds`.
- Keep existing text rate limit and add `20 media messages per user per day`.
- Buckets are private: `chat-images` and `chat-videos`.
- Client code must never use `service_role`.
- Pending upload not sent is deleted after `24 hours`.
- Sender-deleted media and account-deletion media are hidden immediately and physically deleted after `30 days`.
- Admin-removed media is hidden immediately and physically deleted after `7 days`.
- Keo media for completed keos is deleted after `90 days`.
- New public tables/RPCs must explicitly grant access to `authenticated` because new Supabase projects may not expose public tables automatically.
- Do not revert unrelated dirty worktree changes.

---

## File Structure

- Create `supabase/migrations/20260629213000_chat_media_messages.sql` for buckets, message kind, attachment metadata, RLS, RPCs, realtime payload, moderation/account-deletion updates, and cleanup helpers.
- Create `supabase/tests/chat_media_test.sql` for DB/RLS/RPC coverage.
- Create `supabase/functions/cleanup-chat-media/index.ts` for physical Storage cleanup with service role.
- Modify `supabase/functions/.env.example` to add `CHAT_MEDIA_CLEANUP_SECRET`.
- Modify `pubspec.yaml` and `pubspec.lock` to add media dependencies.
- Modify `lib/features/chat/domain/message.dart` and generated files to add `kind`, `hidden`, and optional `MessageAttachment`.
- Create `lib/features/chat/domain/message_attachment.dart` plus generated files.
- Create `lib/features/chat/domain/pending_chat_media.dart` to represent a locally selected file.
- Create `lib/features/chat/data/chat_media_uploader.dart` for Storage upload and signed URL creation.
- Modify `lib/features/chat/data/chat_repository.dart` for attachment history, media send, signed URL, and delete APIs.
- Modify `lib/features/chat/application/chat_providers.dart` for media providers and injectable uploader.
- Create shared chat presentation components under `lib/features/chat/presentation/widgets/`.
- Modify `lib/features/chat/presentation/chat_screen.dart` and `lib/features/keo/presentation/keo_chat_screen.dart` to use shared composer/list widgets.
- Add tests under `test/features/chat/` and update existing chat/keo chat tests.

---

### Task 1: Supabase Chat Media Schema, RPCs, And Storage Policies

**Files:**
- Create: `supabase/migrations/20260629213000_chat_media_messages.sql`
- Test: `supabase/tests/chat_media_test.sql`

**Interfaces:**
- Consumes:
  - `app_private.in_match(p_thread uuid) returns boolean`
  - `app_private.in_keo(p_keo uuid) returns boolean`
  - `app_private.enforce_rate_limit(p_key text, p_limit integer, p_window interval)`
- Produces:
  - `public.message_attachments`
  - `public.create_message_attachment(p_thread_type text, p_thread uuid, p_media_type text, p_mime_type text, p_size_bytes bigint, p_width integer default null, p_height integer default null, p_duration_ms integer default null) returns public.message_attachment_upload`
  - `public.send_media_message(p_attachment uuid) returns uuid`
  - `public.delete_message(p_message uuid) returns void`
  - `messages.kind text`
  - Realtime payload with `kind`, `hidden`, and nested `attachment`

- [ ] **Step 1: Create the failing SQL test**

Add `supabase/tests/chat_media_test.sql`:

```sql
begin;
select plan(12);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000ca01'),
  ('00000000-0000-0000-0000-00000000ca02'),
  ('00000000-0000-0000-0000-00000000ca03')
  on conflict (id) do nothing;

insert into public.matches (id, user_a, user_b, status) values
  ('00000000-0000-0000-0000-00000000cb01',
   '00000000-0000-0000-0000-00000000ca01',
   '00000000-0000-0000-0000-00000000ca02',
   'active')
  on conflict (id) do nothing;

select ok(
  exists(select 1 from pg_type where typname = 'message_attachment_upload'),
  'message_attachment_upload type exists');

select ok(
  exists(select 1 from information_schema.columns
         where table_schema='public' and table_name='messages' and column_name='kind'),
  'messages.kind exists');

select ok(
  exists(select 1 from information_schema.tables
         where table_schema='public' and table_name='message_attachments'),
  'message_attachments table exists');

select ok(
  exists(select 1 from storage.buckets where id='chat-images' and public=false),
  'chat-images private bucket exists');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca03"}';
set local role authenticated;
select throws_ok(
  $$ select public.create_message_attachment(
    'match',
    '00000000-0000-0000-0000-00000000cb01'::uuid,
    'image',
    'image/jpeg',
    1024,
    100,
    100,
    null
  ) $$,
  '23514', null, 'non-member cannot create match attachment');
reset role;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca01"}';
set local role authenticated;
select lives_ok(
  $$ select public.create_message_attachment(
    'match',
    '00000000-0000-0000-0000-00000000cb01'::uuid,
    'image',
    'image/jpeg',
    1024,
    100,
    100,
    null
  ) $$,
  'member can create pending image attachment');

select is(
  (select status from public.message_attachments
   where owner_id='00000000-0000-0000-0000-00000000ca01'
   order by created_at desc limit 1),
  'pending',
  'created attachment is pending');

select throws_ok(
  $$ select public.create_message_attachment(
    'match',
    '00000000-0000-0000-0000-00000000cb01'::uuid,
    'image',
    'image/jpeg',
    9000000,
    100,
    100,
    null
  ) $$,
  '23514', null, 'oversized image is rejected');

select throws_ok(
  $$ select public.create_message_attachment(
    'match',
    '00000000-0000-0000-0000-00000000cb01'::uuid,
    'video',
    'video/mp4',
    1024,
    100,
    100,
    61000
  ) $$,
  '23514', null, 'overlong video is rejected');

set local role postgres;
insert into storage.objects (bucket_id, name, owner, metadata)
select bucket_id, object_path, owner_id, jsonb_build_object('size', size_bytes, 'mimetype', mime_type)
from public.message_attachments
where owner_id='00000000-0000-0000-0000-00000000ca01'
order by created_at desc limit 1;
set local role authenticated;

select lives_ok(
  $$ select public.send_media_message(
    (select id from public.message_attachments
     where owner_id='00000000-0000-0000-0000-00000000ca01'
     order by created_at desc limit 1)
  ) $$,
  'member can send uploaded media message');

select is(
  (select kind from public.messages
   where sender_id='00000000-0000-0000-0000-00000000ca01'
   order by created_at desc limit 1),
  'image',
  'media message kind is image');

select lives_ok(
  $$ select public.delete_message(
    (select id from public.messages
     where sender_id='00000000-0000-0000-0000-00000000ca01'
     order by created_at desc limit 1)
  ) $$,
  'sender can delete own media message');

select is(
  (select status from public.message_attachments
   where owner_id='00000000-0000-0000-0000-00000000ca01'
   order by created_at desc limit 1),
  'hidden',
  'delete hides attachment');

select * from finish();
rollback;
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
supabase test db supabase/tests/chat_media_test.sql
```

Expected: FAIL because `message_attachment_upload`, `messages.kind`, and `message_attachments` do not exist yet.

- [ ] **Step 3: Create the migration**

Create `supabase/migrations/20260629213000_chat_media_messages.sql` with this structure:

```sql
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
alter table public.messages add constraint messages_kind_body_check check (
  (kind = 'text' and body is not null and char_length(body) between 1 and 2000)
  or
  (kind in ('image','video') and body is null)
);

create table public.message_attachments (
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
  delete_after timestamptz not null default now() + interval '24 hours',
  deleted_at timestamptz,
  unique (bucket_id, object_path),
  check (
    (media_type='image' and bucket_id='chat-images')
    or
    (media_type='video' and bucket_id='chat-videos')
  )
);

create index message_attachments_message_ix on public.message_attachments(message_id);
create index message_attachments_thread_ix on public.message_attachments(thread_type, thread_id, created_at);
create index message_attachments_cleanup_ix on public.message_attachments(delete_after)
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

create policy message_attachments_select_thread on public.message_attachments
for select to authenticated
using (
  status in ('attached','hidden')
  and app_private.can_access_chat_thread(thread_type, thread_id)
);

create type public.message_attachment_upload as (
  id uuid,
  bucket_id text,
  object_path text
);

create or replace function app_private.validate_chat_media(
  p_media_type text,
  p_mime_type text,
  p_size_bytes bigint,
  p_duration_ms integer
) returns void language plpgsql security definer set search_path='' as $$
begin
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
returns text language sql immutable as $$
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
  bucket text := case when p_media_type='image' then 'chat-images' else 'chat-videos' end;
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
  if not exists(select 1 from storage.objects o where o.bucket_id=a.bucket_id and o.name=a.object_path) then
    raise exception 'storage_object_missing' using errcode='check_violation';
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
  limit p_limit;
$$;

revoke execute on function public.create_message_attachment(text,uuid,text,text,bigint,integer,integer,integer) from public, anon;
revoke execute on function public.send_media_message(uuid) from public, anon;
revoke execute on function public.delete_message(uuid) from public, anon;
revoke execute on function public.chat_media_cleanup_candidates(integer) from public, anon, authenticated;
grant execute on function public.create_message_attachment(text,uuid,text,text,bigint,integer,integer,integer) to authenticated;
grant execute on function public.send_media_message(uuid) to authenticated;
grant execute on function public.delete_message(uuid) to authenticated;
grant select on public.message_attachments to authenticated;
```

Update `public.admin_action_report` in the same migration by replacing the message branch with:

```sql
if r.target_type = 'message' then
  update public.messages set hidden=true,
    soft_deleted_at = case when p_action='remove' then now() else soft_deleted_at end
    where id = r.target_id::uuid;
  update public.message_attachments set
    status = case when p_action='remove' then 'hidden' else status end,
    soft_deleted_at = case when p_action='remove' then now() else soft_deleted_at end,
    delete_after = case when p_action='remove' then now() + interval '7 days' else delete_after end
    where message_id = r.target_id::uuid and status <> 'deleted';
```

Update `public.request_account_deletion` in the same migration by adding:

```sql
update public.message_attachments
  set status='hidden', soft_deleted_at=now(), delete_after=now() + interval '30 days'
  where owner_id = auth.uid() and status <> 'deleted';
```

- [ ] **Step 4: Run DB test and fix only this migration/test if it fails**

Run:

```powershell
supabase test db supabase/tests/chat_media_test.sql
```

Expected: PASS with 12 assertions.

- [ ] **Step 5: Run focused existing chat tests**

Run:

```powershell
supabase test db supabase/tests/chat_test.sql
supabase test db supabase/tests/keo_chat_test.sql
supabase test db supabase/tests/moderation_test.sql
```

Expected: all PASS.

- [ ] **Step 6: Commit**

```powershell
git add supabase/migrations/20260629213000_chat_media_messages.sql supabase/tests/chat_media_test.sql
git commit -m "feat(chat): add media message schema"
```

---

### Task 2: Edge Function For Physical Media Cleanup

**Files:**
- Create: `supabase/functions/cleanup-chat-media/index.ts`
- Modify: `supabase/functions/.env.example`
- Test: Manual local function invocation plus DB row verification.

**Interfaces:**
- Consumes:
  - `public.chat_media_cleanup_candidates(p_limit integer)`
  - `public.message_attachments`
  - Supabase Storage `.remove(paths)`
- Produces:
  - POST-only Edge Function `cleanup-chat-media`
  - Secret header `x-cleanup-secret`

- [ ] **Step 1: Add env example**

Modify `supabase/functions/.env.example`:

```dotenv
CHAT_MEDIA_CLEANUP_SECRET=your-chat-media-cleanup-secret
```

- [ ] **Step 2: Create Edge Function**

Create `supabase/functions/cleanup-chat-media/index.ts`:

```ts
import { createClient } from "jsr:@supabase/supabase-js@2";

type Attachment = {
  id: string;
  bucket_id: string;
  object_path: string;
  thumbnail_bucket_id: string | null;
  thumbnail_path: string | null;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("method_not_allowed", { status: 405 });
  }
  if (req.headers.get("x-cleanup-secret") !== Deno.env.get("CHAT_MEDIA_CLEANUP_SECRET")) {
    return new Response("forbidden", { status: 403 });
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data, error } = await admin.rpc("chat_media_cleanup_candidates", { p_limit: 100 });
  if (error) {
    console.error("[cleanup-chat-media] candidate query failed", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  const attachments = (data ?? []) as Attachment[];
  let deleted = 0;
  const failures: Array<{ id: string; error: string }> = [];

  for (const attachment of attachments) {
    const removals = new Map<string, string[]>();
    removals.set(attachment.bucket_id, [attachment.object_path]);
    if (attachment.thumbnail_bucket_id && attachment.thumbnail_path) {
      const paths = removals.get(attachment.thumbnail_bucket_id) ?? [];
      paths.push(attachment.thumbnail_path);
      removals.set(attachment.thumbnail_bucket_id, paths);
    }

    let failed = false;
    for (const [bucket, paths] of removals.entries()) {
      const { error: removeError } = await admin.storage.from(bucket).remove(paths);
      if (removeError) {
        failures.push({ id: attachment.id, error: removeError.message });
        failed = true;
        break;
      }
    }

    if (failed) continue;

    const { error: updateError } = await admin
      .from("message_attachments")
      .update({ status: "deleted", deleted_at: new Date().toISOString() })
      .eq("id", attachment.id);
    if (updateError) {
      failures.push({ id: attachment.id, error: updateError.message });
      continue;
    }
    deleted += 1;
  }

  return new Response(JSON.stringify({ scanned: attachments.length, deleted, failures }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

- [ ] **Step 3: Serve and invoke locally**

Run:

```powershell
supabase functions serve cleanup-chat-media --env-file supabase/functions/.env.example
```

In a second terminal, run:

```powershell
Invoke-WebRequest -UseBasicParsing `
  -Method Post `
  -Uri http://127.0.0.1:54321/functions/v1/cleanup-chat-media `
  -Headers @{ "x-cleanup-secret" = "your-chat-media-cleanup-secret" }
```

Expected: JSON response with `scanned`, `deleted`, and `failures`.

- [ ] **Step 4: Commit**

```powershell
git add supabase/functions/cleanup-chat-media/index.ts supabase/functions/.env.example
git commit -m "feat(chat): add media cleanup function"
```

---

### Task 3: Dart Message Attachment Domain Model

**Files:**
- Create: `lib/features/chat/domain/message_attachment.dart`
- Modify: `lib/features/chat/domain/message.dart`
- Regenerate: `lib/features/chat/domain/message.freezed.dart`
- Regenerate: `lib/features/chat/domain/message.g.dart`
- Create: `test/features/chat/message_model_test.dart`

**Interfaces:**
- Consumes realtime/history JSON with `kind`, `hidden`, and `attachment`.
- Produces:
  - `MessageAttachment`
  - `Message.kind`
  - `Message.hidden`
  - `Message.attachment`

- [ ] **Step 1: Write failing model tests**

Create `test/features/chat/message_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/chat/domain/message.dart';

void main() {
  test('parses text message without attachment', () {
    final msg = Message.fromJson({
      'id': 'm1',
      'thread_id': 't1',
      'sender_id': 'u1',
      'body': 'hello',
      'kind': 'text',
      'hidden': false,
      'created_at': '2026-06-29T10:00:00Z',
      'attachment': null,
    });

    expect(msg.kind, 'text');
    expect(msg.body, 'hello');
    expect(msg.hidden, isFalse);
    expect(msg.attachment, isNull);
  });

  test('parses image message with attachment', () {
    final msg = Message.fromJson({
      'id': 'm2',
      'thread_id': 't1',
      'sender_id': 'u1',
      'body': null,
      'kind': 'image',
      'hidden': false,
      'created_at': '2026-06-29T10:01:00Z',
      'attachment': {
        'id': 'a1',
        'message_id': 'm2',
        'media_type': 'image',
        'bucket_id': 'chat-images',
        'object_path': 'match/t1/u1/a1.jpg',
        'thumbnail_bucket_id': null,
        'thumbnail_path': null,
        'mime_type': 'image/jpeg',
        'size_bytes': 1234,
        'width': 640,
        'height': 480,
        'duration_ms': null,
        'status': 'attached',
      },
    });

    expect(msg.kind, 'image');
    expect(msg.body, isNull);
    expect(msg.attachment?.objectPath, 'match/t1/u1/a1.jpg');
    expect(msg.attachment?.sizeBytes, 1234);
  });
}
```

- [ ] **Step 2: Run tests to verify failure**

```powershell
flutter test test/features/chat/message_model_test.dart
```

Expected: FAIL because `Message.kind`, `hidden`, and `attachment` do not exist.

- [ ] **Step 3: Add domain models**

Create `lib/features/chat/domain/message_attachment.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_attachment.freezed.dart';
part 'message_attachment.g.dart';

@freezed
abstract class MessageAttachment with _$MessageAttachment {
  const factory MessageAttachment({
    required String id,
    @JsonKey(name: 'message_id') String? messageId,
    @JsonKey(name: 'media_type') required String mediaType,
    @JsonKey(name: 'bucket_id') required String bucketId,
    @JsonKey(name: 'object_path') required String objectPath,
    @JsonKey(name: 'thumbnail_bucket_id') String? thumbnailBucketId,
    @JsonKey(name: 'thumbnail_path') String? thumbnailPath,
    @JsonKey(name: 'mime_type') required String mimeType,
    @JsonKey(name: 'size_bytes') required int sizeBytes,
    int? width,
    int? height,
    @JsonKey(name: 'duration_ms') int? durationMs,
    required String status,
  }) = _MessageAttachment;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      _$MessageAttachmentFromJson(json);
}
```

Modify `lib/features/chat/domain/message.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_attachment.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
abstract class Message with _$Message {
  const factory Message({
    required String id,
    @JsonKey(name: 'thread_id') required String threadId,
    @JsonKey(name: 'sender_id') required String senderId,
    String? body,
    @Default('text') String kind,
    @Default(false) bool hidden,
    MessageAttachment? attachment,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
```

- [ ] **Step 4: Generate code**

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: generated `message_attachment.freezed.dart`, `message_attachment.g.dart`, updated `message.freezed.dart`, and `message.g.dart`.

- [ ] **Step 5: Run model tests**

```powershell
flutter test test/features/chat/message_model_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib/features/chat/domain/message.dart lib/features/chat/domain/message_attachment.dart lib/features/chat/domain/*.freezed.dart lib/features/chat/domain/*.g.dart test/features/chat/message_model_test.dart
git commit -m "feat(chat): model media attachments"
```

---

### Task 4: Chat Repository Media Upload API

**Files:**
- Create: `lib/features/chat/domain/pending_chat_media.dart`
- Create: `lib/features/chat/data/chat_media_uploader.dart`
- Modify: `lib/features/chat/data/chat_repository.dart`
- Modify: `lib/features/chat/application/chat_providers.dart`
- Modify: `test/features/chat/chat_repository_test.dart`
- Modify: `test/features/keo/keo_chat_test.dart`

**Interfaces:**
- Consumes:
  - `public.create_message_attachment`
  - `public.send_media_message`
  - `public.delete_message`
- Produces:
  - `ChatRepository.sendMatchMedia(String threadId, PendingChatMedia media)`
  - `ChatRepository.sendKeoMedia(String keoId, PendingChatMedia media)`
  - `ChatRepository.deleteMessage(String messageId)`
  - `ChatMediaUploader.upload(...)`
  - `ChatMediaUploader.signedUrl(...)`

- [ ] **Step 1: Write failing repository tests**

Add to `test/features/chat/chat_repository_test.dart`:

```dart
import 'dart:io';

import 'package:cung_hat/features/chat/data/chat_media_uploader.dart';
import 'package:cung_hat/features/chat/domain/pending_chat_media.dart';

class _FakeUploader implements ChatMediaUploader {
  final uploaded = <String>[];

  @override
  Future<void> upload({
    required String bucketId,
    required String objectPath,
    required File file,
    required String mimeType,
  }) async {
    uploaded.add('$bucketId/$objectPath/$mimeType');
  }

  @override
  Future<String> signedUrl({
    required String bucketId,
    required String objectPath,
    int expiresInSeconds = 600,
  }) async {
    return 'signed:$bucketId/$objectPath';
  }
}

test('sendMatchMedia creates pending attachment, uploads, then sends media message', () async {
  final client = MockSupabaseClient();
  final uploader = _FakeUploader();
  final file = File('test/fixtures/chat-image.jpg');

  when(() => client.rpc('create_message_attachment', params: any(named: 'params')))
      .thenAnswer((_) => rpcOk({
            'id': 'a1',
            'bucket_id': 'chat-images',
            'object_path': 'match/t1/u1/a1.jpg',
          }));
  when(() => client.rpc('send_media_message', params: any(named: 'params')))
      .thenAnswer((_) => rpcOk('m1'));

  final id = await ChatRepository(client, uploader: uploader).sendMatchMedia(
    't1',
    PendingChatMedia(
      file: file,
      mediaType: 'image',
      mimeType: 'image/jpeg',
      sizeBytes: 100,
      width: 10,
      height: 10,
    ),
  );

  expect(id, 'm1');
  expect(uploader.uploaded, ['chat-images/match/t1/u1/a1.jpg/image/jpeg']);
  verify(() => client.rpc('create_message_attachment', params: {
        'p_thread_type': 'match',
        'p_thread': 't1',
        'p_media_type': 'image',
        'p_mime_type': 'image/jpeg',
        'p_size_bytes': 100,
        'p_width': 10,
        'p_height': 10,
        'p_duration_ms': null,
      })).called(1);
  verify(() => client.rpc('send_media_message', params: {'p_attachment': 'a1'})).called(1);
});
```

Add to `test/features/keo/keo_chat_test.dart`:

```dart
test('deleteMessage calls delete_message RPC', () async {
  final client = MockSupabaseClient();
  when(() => client.rpc('delete_message', params: any(named: 'params')))
      .thenAnswer((_) => rpcOk(null));

  await ChatRepository(client).deleteMessage('m1');

  verify(() => client.rpc('delete_message', params: {'p_message': 'm1'})).called(1);
});
```

- [ ] **Step 2: Run tests to verify failure**

```powershell
flutter test test/features/chat/chat_repository_test.dart test/features/keo/keo_chat_test.dart
```

Expected: FAIL because `PendingChatMedia`, `ChatMediaUploader`, and new repository methods do not exist.

- [ ] **Step 3: Add local media and uploader classes**

Create `lib/features/chat/domain/pending_chat_media.dart`:

```dart
import 'dart:io';

class PendingChatMedia {
  const PendingChatMedia({
    required this.file,
    required this.mediaType,
    required this.mimeType,
    required this.sizeBytes,
    this.width,
    this.height,
    this.durationMs,
  });

  final File file;
  final String mediaType;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;
  final int? durationMs;
}
```

Create `lib/features/chat/data/chat_media_uploader.dart`:

```dart
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatMediaUploader {
  Future<void> upload({
    required String bucketId,
    required String objectPath,
    required File file,
    required String mimeType,
  });

  Future<String> signedUrl({
    required String bucketId,
    required String objectPath,
    int expiresInSeconds = 600,
  });
}

class SupabaseChatMediaUploader implements ChatMediaUploader {
  SupabaseChatMediaUploader(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upload({
    required String bucketId,
    required String objectPath,
    required File file,
    required String mimeType,
  }) {
    return _client.storage.from(bucketId).upload(
          objectPath,
          file,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
  }

  @override
  Future<String> signedUrl({
    required String bucketId,
    required String objectPath,
    int expiresInSeconds = 600,
  }) {
    return _client.storage.from(bucketId).createSignedUrl(objectPath, expiresInSeconds);
  }
}
```

- [ ] **Step 4: Extend repository**

Modify `ChatRepository` constructor and add methods:

```dart
class ChatRepository {
  ChatRepository(this._client, {ChatMediaUploader? uploader})
      : _uploader = uploader ?? SupabaseChatMediaUploader(_client);

  final SupabaseClient _client;
  final ChatMediaUploader _uploader;

  Future<String> sendMatchMedia(String threadId, PendingChatMedia media) {
    return _sendMedia(threadType: 'match', threadId: threadId, media: media);
  }

  Future<String> sendKeoMedia(String keoId, PendingChatMedia media) {
    return _sendMedia(threadType: 'keo', threadId: keoId, media: media);
  }

  Future<String> _sendMedia({
    required String threadType,
    required String threadId,
    required PendingChatMedia media,
  }) async {
    final upload = await _client.rpc('create_message_attachment', params: {
      'p_thread_type': threadType,
      'p_thread': threadId,
      'p_media_type': media.mediaType,
      'p_mime_type': media.mimeType,
      'p_size_bytes': media.sizeBytes,
      'p_width': media.width,
      'p_height': media.height,
      'p_duration_ms': media.durationMs,
    }) as Map;
    final uploadMap = Map<String, dynamic>.from(upload);
    final attachmentId = uploadMap['id'] as String;
    final bucketId = uploadMap['bucket_id'] as String;
    final objectPath = uploadMap['object_path'] as String;

    await _uploader.upload(
      bucketId: bucketId,
      objectPath: objectPath,
      file: media.file,
      mimeType: media.mimeType,
    );

    final id = await _client.rpc('send_media_message', params: {
      'p_attachment': attachmentId,
    });
    return id as String;
  }

  Future<void> deleteMessage(String messageId) async {
    await _client.rpc('delete_message', params: {'p_message': messageId});
  }

  Future<String> signedMediaUrl(String bucketId, String objectPath) {
    return _uploader.signedUrl(bucketId: bucketId, objectPath: objectPath);
  }
}
```

Keep existing `sendMessage`, `sendKeoMessage`, `history`, `keoHistory`, `subscribe`, and `subscribeKeo`.

- [ ] **Step 5: Update provider**

Modify `chatRepositoryProvider` only if constructor changes require no action:

```dart
final chatRepositoryProvider =
    Provider((ref) => ChatRepository(ref.watch(supabaseClientProvider)));
```

This remains valid because uploader is optional.

- [ ] **Step 6: Run focused repository tests**

```powershell
flutter test test/features/chat/chat_repository_test.dart test/features/keo/keo_chat_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/features/chat/domain/pending_chat_media.dart lib/features/chat/data/chat_media_uploader.dart lib/features/chat/data/chat_repository.dart lib/features/chat/application/chat_providers.dart test/features/chat/chat_repository_test.dart test/features/keo/keo_chat_test.dart
git commit -m "feat(chat): upload media messages"
```

---

### Task 5: Dependencies And Platform Picker Setup

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Produces packages for picker and video rendering:
  - `image_picker`
  - `video_player`
  - `mime`

- [ ] **Step 1: Add dependencies**

Run:

```powershell
flutter pub add image_picker video_player mime
```

Expected: `pubspec.yaml` and `pubspec.lock` update.

- [ ] **Step 2: Add iOS photo library usage text**

Modify `ios/Runner/Info.plist` inside the main `<dict>`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Cho phep Cung Hat chon anh va video de gui trong tin nhan.</string>
```

- [ ] **Step 3: Keep Android minimal**

Do not add broad storage permissions for Android unless build/runtime proves the picker needs them. `image_picker` uses platform pickers on modern Android; avoid requesting unnecessary storage permissions.

- [ ] **Step 4: Run dependency verification**

```powershell
flutter pub get
flutter analyze
```

Expected: dependency resolution succeeds and analyzer reports no new errors from dependency setup.

- [ ] **Step 5: Commit**

```powershell
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
git commit -m "chore(chat): add media picker dependencies"
```

---

### Task 6: Shared Message Bubble Rendering

**Files:**
- Create: `lib/features/chat/presentation/widgets/chat_message_bubble.dart`
- Create: `lib/features/chat/presentation/widgets/media_message_view.dart`
- Create: `test/features/chat/chat_message_bubble_test.dart`

**Interfaces:**
- Consumes:
  - `Message`
  - `MessageAttachment`
  - `Future<String> Function(String bucketId, String objectPath) resolveMediaUrl`
- Produces:
  - `ChatMessageBubble`
  - `MediaMessageView`

- [ ] **Step 1: Write failing widget tests**

Create `test/features/chat/chat_message_bubble_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/domain/message_attachment.dart';
import 'package:cung_hat/features/chat/presentation/widgets/chat_message_bubble.dart';

void main() {
  testWidgets('renders text message body', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatMessageBubble(
          message: const Message(
            id: 'm1',
            threadId: 't1',
            senderId: 'u1',
            body: 'hello',
            createdAt: '2026-06-29T10:00:00Z',
          ),
          mine: true,
          resolveMediaUrl: (_, __) async => '',
        ),
      ),
    ));

    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('renders deleted tombstone', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatMessageBubble(
          message: const Message(
            id: 'm1',
            threadId: 't1',
            senderId: 'u1',
            body: null,
            kind: 'image',
            hidden: true,
            createdAt: '2026-06-29T10:00:00Z',
          ),
          mine: true,
          resolveMediaUrl: (_, __) async => '',
        ),
      ),
    ));

    expect(find.text('Tin da xoa'), findsOneWidget);
  });

  testWidgets('renders image media shell', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatMessageBubble(
          message: const Message(
            id: 'm2',
            threadId: 't1',
            senderId: 'u1',
            body: null,
            kind: 'image',
            createdAt: '2026-06-29T10:00:00Z',
            attachment: MessageAttachment(
              id: 'a1',
              messageId: 'm2',
              mediaType: 'image',
              bucketId: 'chat-images',
              objectPath: 'match/t1/u1/a1.jpg',
              mimeType: 'image/jpeg',
              sizeBytes: 100,
              status: 'attached',
            ),
          ),
          mine: true,
          resolveMediaUrl: (_, __) async => 'https://example.test/a1.jpg',
        ),
      ),
    ));
    await tester.pump();

    expect(find.byKey(const Key('image_media_bubble')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify failure**

```powershell
flutter test test/features/chat/chat_message_bubble_test.dart
```

Expected: FAIL because `ChatMessageBubble` does not exist.

- [ ] **Step 3: Add shared bubble widgets**

Create `chat_message_bubble.dart` with a text/deleted/media switch:

```dart
import 'package:flutter/material.dart';

import '../../domain/message.dart';
import 'media_message_view.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.resolveMediaUrl,
    this.onDelete,
  });

  final Message message;
  final bool mine;
  final Future<String> Function(String bucketId, String objectPath) resolveMediaUrl;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final child = _child(context);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: mine ? onDelete : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: message.kind == 'text'
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
              : const EdgeInsets.all(6),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: mine ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _child(BuildContext context) {
    if (message.hidden || message.attachment?.status == 'hidden') {
      return Text(
        'Tin da xoa',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    if (message.kind == 'text') {
      return Text(message.body ?? '');
    }
    final attachment = message.attachment;
    if (attachment == null) {
      return const Text('Khong tai duoc tep');
    }
    return MediaMessageView(
      attachment: attachment,
      resolveMediaUrl: resolveMediaUrl,
    );
  }
}
```

Create `media_message_view.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/message_attachment.dart';

class MediaMessageView extends StatelessWidget {
  const MediaMessageView({
    super.key,
    required this.attachment,
    required this.resolveMediaUrl,
  });

  final MessageAttachment attachment;
  final Future<String> Function(String bucketId, String objectPath) resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    final isVideo = attachment.mediaType == 'video';
    return FutureBuilder<String>(
      future: resolveMediaUrl(attachment.bucketId, attachment.objectPath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            key: Key('media_loading_bubble'),
            width: 220,
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (isVideo) {
          return SizedBox(
            key: const Key('video_media_bubble'),
            width: 220,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SizedBox.expand(),
                ),
                const Icon(Icons.play_circle_fill, size: 48),
              ],
            ),
          );
        }
        return ClipRRect(
          key: const Key('image_media_bubble'),
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            snapshot.data!,
            width: 220,
            height: 160,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run widget tests**

```powershell
flutter test test/features/chat/chat_message_bubble_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/chat/presentation/widgets/chat_message_bubble.dart lib/features/chat/presentation/widgets/media_message_view.dart test/features/chat/chat_message_bubble_test.dart
git commit -m "feat(chat): render media message bubbles"
```

---

### Task 7: Shared Chat Composer With Media Pick

**Files:**
- Create: `lib/features/chat/presentation/widgets/chat_composer.dart`
- Create: `lib/features/chat/presentation/widgets/media_preview_bar.dart`
- Modify: `test/features/chat/chat_screen_test.dart`

**Interfaces:**
- Consumes:
  - `Future<void> Function(String text) onSendText`
  - `Future<void> Function(PendingChatMedia media) onSendMedia`
- Produces:
  - `ChatComposer`
  - attach button with key `attach_media_btn`
  - send button with key `send_btn`

- [ ] **Step 1: Write failing composer test**

Add to `test/features/chat/chat_screen_test.dart` or create `test/features/chat/chat_composer_test.dart`:

```dart
import 'package:cung_hat/features/chat/presentation/widgets/chat_composer.dart';

testWidgets('composer keeps existing text send behavior', (tester) async {
  String? sent;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ChatComposer(
        onSendText: (text) async => sent = text,
        onSendMedia: (_) async {},
      ),
    ),
  ));

  await tester.enterText(find.byType(TextField), 'di hat nhe');
  await tester.tap(find.byKey(const Key('send_btn')));
  await tester.pump();

  expect(sent, 'di hat nhe');
});

testWidgets('composer exposes attach button', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: ChatComposer(
        onSendText: (_) async {},
        onSendMedia: (_) async {},
      ),
    ),
  ));

  expect(find.byKey(const Key('attach_media_btn')), findsOneWidget);
});
```

- [ ] **Step 2: Run composer test to verify failure**

```powershell
flutter test test/features/chat/chat_screen_test.dart
```

Expected: FAIL because `ChatComposer` does not exist.

- [ ] **Step 3: Add composer without picker wiring first**

Create `chat_composer.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/pending_chat_media.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSendText,
    required this.onSendMedia,
    this.enabled = true,
  });

  final Future<void> Function(String text) onSendText;
  final Future<void> Function(PendingChatMedia media) onSendMedia;
  final bool enabled;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || !widget.enabled) return;
    setState(() => _sending = true);
    try {
      await widget.onSendText(text);
      if (mounted) _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickMedia() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chon anh/video sap san sang')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            IconButton(
              key: const Key('attach_media_btn'),
              tooltip: 'Gui anh/video',
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onPressed: widget.enabled && !_sending ? _pickMedia : null,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled && !_sending,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
                decoration: const InputDecoration(
                  hintText: 'Nhan gi do...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              key: const Key('send_btn'),
              icon: const Icon(Icons.send),
              onPressed: widget.enabled && !_sending ? _sendText : null,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Wire actual picker in composer**

Update `_pickMedia` after adding dependencies:

```dart
final picker = ImagePicker();
final picked = await picker.pickMedia();
if (picked == null) return;
final file = File(picked.path);
final length = await file.length();
final mimeType = picked.mimeType ?? lookupMimeType(picked.path);
if (mimeType == null) {
  _snack('Dinh dang tep chua duoc ho tro.');
  return;
}
final isImage = mimeType.startsWith('image/');
final isVideo = mimeType.startsWith('video/');
if (!isImage && !isVideo) {
  _snack('Dinh dang tep chua duoc ho tro.');
  return;
}
if (isImage && length > 8388608) {
  _snack('Tep qua lon de gui.');
  return;
}
if (isVideo && length > 26214400) {
  _snack('Tep qua lon de gui.');
  return;
}
await widget.onSendMedia(PendingChatMedia(
  file: file,
  mediaType: isImage ? 'image' : 'video',
  mimeType: mimeType,
  sizeBytes: length,
));
```

Add imports:

```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
```

If video duration inspection is not available from picker metadata, Task 1 server validation remains authoritative for the MVP and rejects videos over 60 seconds.

- [ ] **Step 5: Run composer tests**

```powershell
flutter test test/features/chat/chat_screen_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib/features/chat/presentation/widgets/chat_composer.dart lib/features/chat/presentation/widgets/media_preview_bar.dart test/features/chat/chat_screen_test.dart
git commit -m "feat(chat): add media composer"
```

---

### Task 8: Wire Match Chat And Keo Chat Screens To Shared Components

**Files:**
- Modify: `lib/features/chat/presentation/chat_screen.dart`
- Modify: `lib/features/keo/presentation/keo_chat_screen.dart`
- Modify: `test/features/chat/chat_screen_test.dart`

**Interfaces:**
- Consumes:
  - `ChatMessageBubble`
  - `ChatComposer`
  - `ChatRepository.sendMatchMedia`
  - `ChatRepository.sendKeoMedia`
  - `ChatRepository.signedMediaUrl`
  - `ChatRepository.deleteMessage`

- [ ] **Step 1: Update screen tests for media send path**

Add a repository mock expectation in `chat_screen_test.dart`:

```dart
when(() => repo.signedMediaUrl(any(), any())).thenAnswer((_) async => 'https://example.test/media');
when(() => repo.deleteMessage(any())).thenAnswer((_) async {});
```

Keep the existing text-send test passing.

- [ ] **Step 2: Replace inline text bubble with `ChatMessageBubble`**

In both screens, replace the inline `Container(child: Text(m.body))` with:

```dart
ChatMessageBubble(
  message: m,
  mine: mine,
  resolveMediaUrl: (bucketId, objectPath) =>
      ref.read(chatRepositoryProvider).signedMediaUrl(bucketId, objectPath),
  onDelete: mine ? () => _deleteMessage(m.id) : null,
)
```

Add `_deleteMessage`:

```dart
Future<void> _deleteMessage(String messageId) async {
  try {
    await ref.read(chatRepositoryProvider).deleteMessage(messageId);
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Khong xoa duoc tin nhan.')),
    );
  }
}
```

- [ ] **Step 3: Replace composer with `ChatComposer`**

For match chat:

```dart
ChatComposer(
  onSendText: _doSend,
  onSendMedia: (media) async {
    await ref.read(chatRepositoryProvider).sendMatchMedia(widget.matchId, media);
    _scrollToBottom();
  },
)
```

For keo chat:

```dart
ChatComposer(
  onSendText: _doSend,
  onSendMedia: (media) async {
    try {
      await ref.read(chatRepositoryProvider).sendKeoMedia(widget.keoId, media);
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chua mo chat nhom hoac khong gui duoc tep.')),
      );
    }
  },
)
```

- [ ] **Step 4: Run focused Flutter tests**

```powershell
flutter test test/features/chat/chat_screen_test.dart test/features/chat/chat_message_bubble_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/chat/presentation/chat_screen.dart lib/features/keo/presentation/keo_chat_screen.dart test/features/chat/chat_screen_test.dart
git commit -m "feat(chat): wire media UI into chats"
```

---

### Task 9: Full Verification And Emulator QA

**Files:**
- No source files unless verification finds defects.
- Optional screenshots under `test/screenshots/emulator-qa/`.

**Interfaces:**
- Verifies the complete user flow.

- [ ] **Step 1: Run code generation once more**

```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: no generation errors.

- [ ] **Step 2: Run static analysis**

```powershell
flutter analyze
```

Expected: exit 0.

- [ ] **Step 3: Run focused Flutter tests**

```powershell
flutter test test/features/chat test/features/keo/keo_chat_test.dart
```

Expected: all tests pass.

- [ ] **Step 4: Run focused Supabase tests**

```powershell
supabase test db supabase/tests/chat_test.sql
supabase test db supabase/tests/keo_chat_test.sql
supabase test db supabase/tests/chat_media_test.sql
supabase test db supabase/tests/moderation_test.sql
```

Expected: all tests pass.

- [ ] **Step 5: Build Android debug APK**

If path-with-spaces native-assets issue recurs, use the existing no-space worktree workaround from prior emulator QA. Otherwise run:

```powershell
flutter build apk --debug --dart-define-from-file=env/dev.json
```

Expected: debug APK builds.

- [ ] **Step 6: Manual emulator QA**

Use `adb` UI-tree driven taps:

```powershell
adb devices
adb -s emulator-5554 reverse tcp:54321 tcp:54321
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 logcat -c
```

QA checklist:

- Login with test OTP.
- Open an existing 1:1 chat.
- Send one image.
- Reload app and confirm image still renders.
- Long-press/delete the image message and confirm tombstone.
- Open a keo chat as confirmed member.
- Send one image or short video.
- Confirm DB row in `message_attachments` is `attached`.
- Confirm logcat has no `FATAL EXCEPTION`, `E/flutter`, or `PostgrestException`.

- [ ] **Step 7: Record final verification status**

If all commands and emulator checks pass without additional source edits, leave the task with no commit. If a defect is found, stop this verification task, create a focused fix task for the specific failing file, and re-run Task 9 from Step 1 after that fix lands.

---

## Plan Self-Review

Spec coverage:

- One media per message: covered by DB `message_attachments.message_id` shape and UI picker flow.
- Private Storage buckets: Task 1.
- Metadata table: Task 1 and Task 3.
- Signed/authenticated access: Task 4 and Task 6.
- Deletion retention: Task 1 and Task 2.
- Cleanup of pending uploads: Task 1 marks `delete_after`; Task 2 deletes physical objects.
- Match and keo chat support: Tasks 1, 4, 8, 9.
- Tests and emulator QA: Tasks 1, 3, 4, 6, 7, 8, 9.

Placeholder scan:

- No `TBD`, `TODO`, or open-ended placeholders are intentionally left in the implementation steps.

Type consistency:

- `MessageAttachment` JSON keys match the SQL payload keys.
- `PendingChatMedia` fields match `create_message_attachment` RPC params.
- `ChatRepository.sendMatchMedia` and `sendKeoMedia` both call the shared `_sendMedia`.

## References

- Supabase Storage file limits: https://supabase.com/docs/guides/storage/uploads/file-limits
- Supabase Storage access control/RLS: https://supabase.com/docs/guides/storage/security/access-control
- Supabase Storage private serving/signed URLs: https://supabase.com/docs/guides/storage/serving/downloads
- Supabase resumable upload guidance: https://supabase.com/docs/guides/storage/uploads/resumable-uploads
- Supabase Data API exposure breaking change: https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically
