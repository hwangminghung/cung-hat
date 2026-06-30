begin;
select plan(28);

set local role postgres;
create temp table _chat_media (
  k text primary key,
  attachment_id uuid,
  bucket_id text,
  object_path text,
  owner_id uuid,
  message_id uuid
) on commit drop;
grant select, insert, update on _chat_media to authenticated;

insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000ca01'),
  ('00000000-0000-0000-0000-00000000ca02'),
  ('00000000-0000-0000-0000-00000000ca03'),
  ('00000000-0000-0000-0000-00000000ca04')
  on conflict (id) do nothing;

insert into public.matches (id, user_a, user_b, status) values
  ('00000000-0000-0000-0000-00000000cb01',
   '00000000-0000-0000-0000-00000000ca01',
   '00000000-0000-0000-0000-00000000ca02',
   'active')
  on conflict (id) do nothing;

insert into public.keo (
  id, host_id, title, area_geo, time_window_start, time_window_end,
  group_size_target, status
) values (
  '00000000-0000-0000-0000-00000000cc01',
  '00000000-0000-0000-0000-00000000ca01',
  'chat media keo',
  public.ST_SetSRID(public.ST_MakePoint(106.7, 10.8), 4326)::public.geography,
  now() + interval '1 day',
  now() + interval '1 day 2 hours',
  3,
  'planning'
) on conflict (id) do nothing;

insert into public.keo_members (keo_id, user_id, role, join_status, confirmed) values
  ('00000000-0000-0000-0000-00000000cc01', '00000000-0000-0000-0000-00000000ca01', 'host', 'approved', true),
  ('00000000-0000-0000-0000-00000000cc01', '00000000-0000-0000-0000-00000000ca02', 'member', 'approved', true)
  on conflict (keo_id, user_id) do update set join_status='approved', confirmed=true;

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
  exists(
    select 1 from storage.buckets
    where id='chat-images'
      and public=false
      and file_size_limit=8388608
      and allowed_mime_types=array['image/jpeg','image/png','image/webp']
  ),
  'chat-images private bucket has image restrictions');

select ok(
  exists(
    select 1 from storage.buckets
    where id='chat-videos'
      and public=false
      and file_size_limit=26214400
      and allowed_mime_types=array['video/mp4','video/quicktime']
  ),
  'chat-videos private bucket has video restrictions');

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

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca01"}';
select lives_ok(
  $$ with upload as (
    select * from public.create_message_attachment(
      'match',
      '00000000-0000-0000-0000-00000000cb01'::uuid,
      'image',
      'image/jpeg',
      1024,
      100,
      100,
      null
    )
  )
  insert into _chat_media(k, attachment_id, bucket_id, object_path, owner_id)
  select 'match_img', id, bucket_id, object_path, '00000000-0000-0000-0000-00000000ca01'::uuid
  from upload $$,
  'member can create pending image attachment');

select is(
  (select status from public.message_attachments
   where id=(select attachment_id from _chat_media where k='match_img')),
  'pending',
  'created attachment is pending');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca02"}';
select lives_ok(
  $$ with upload as (
    select * from public.create_message_attachment(
      'keo',
      '00000000-0000-0000-0000-00000000cc01'::uuid,
      'video',
      'video/mp4',
      2048,
      320,
      180,
      30000
    )
  )
  insert into _chat_media(k, attachment_id, bucket_id, object_path, owner_id)
  select 'keo_video', id, bucket_id, object_path, '00000000-0000-0000-0000-00000000ca02'::uuid
  from upload $$,
  'confirmed keo member can create pending video attachment');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca01"}';
select throws_ok(
  $$ select public.create_message_attachment(
    'match',
    '00000000-0000-0000-0000-00000000cb01'::uuid,
    'image',
    'image/gif',
    1024,
    100,
    100,
    null
  ) $$,
  '23514', null, 'invalid MIME type is rejected');

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
update public.message_attachments
  set delete_after = now() - interval '1 minute'
  where id = (select attachment_id from _chat_media where k='keo_video');

select ok(
  exists (
    select 1 from public.chat_media_cleanup_candidates(10)
    where id = (select attachment_id from _chat_media where k='keo_video')
  ),
  'pending attachment becomes a cleanup candidate after 24h window');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca01"}';
set local role authenticated;
select lives_ok(
  $$ insert into storage.objects (bucket_id, name, owner, metadata)
  select bucket_id, object_path, owner_id, jsonb_build_object('size', 1024, 'mimetype', 'image/jpeg')
  from _chat_media
  where k='match_img' $$,
  'storage insert policy permits pending owner upload');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca02"}';
select lives_ok(
  $$ with upload as (
    select * from public.create_message_attachment(
      'match',
      '00000000-0000-0000-0000-00000000cb01'::uuid,
      'image',
      'image/jpeg',
      1024,
      100,
      100,
      null
    )
  )
  insert into _chat_media(k, attachment_id, bucket_id, object_path, owner_id)
  select 'other_pending', id, bucket_id, object_path, '00000000-0000-0000-0000-00000000ca02'::uuid
  from upload $$,
  'second member can create pending attachment for owner checks');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca01"}';
select throws_ok(
  $$ insert into storage.objects (bucket_id, name, owner, metadata)
  select bucket_id, object_path, owner_id, jsonb_build_object('size', 1024, 'mimetype', 'image/jpeg')
  from _chat_media
  where k='other_pending' $$,
  '42501', null, 'storage insert policy rejects non-owner upload');

select throws_ok(
  $$ select public.send_media_message(
    (select attachment_id from _chat_media where k='other_pending')
  ) $$,
  '23514', null, 'sender cannot attach another user pending attachment');

select lives_ok(
  $$ with sent as (
    select public.send_media_message(
      (select attachment_id from _chat_media where k='match_img')
    ) as message_id
  )
  update _chat_media
    set message_id = sent.message_id
    from sent
    where k='match_img' $$,
  'member can send uploaded media message');

select is(
  (select kind from public.messages
   where id=(select message_id from _chat_media where k='match_img')),
  'image',
  'media message kind is image');

set local role postgres;
select ok(
  (
    select app_private.message_payload(m) @> jsonb_build_object(
      'kind', 'image',
      'hidden', false,
      'attachment', jsonb_build_object(
        'id', (select attachment_id from _chat_media where k='match_img'),
        'media_type', 'image'
      )
    )
    from public.messages m
    where m.id=(select message_id from _chat_media where k='match_img')
  ),
  'realtime payload helper includes kind, hidden, and nested attachment');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca02"}';
set local role authenticated;
select is(
  (select count(*)::int from storage.objects
   where bucket_id=(select bucket_id from _chat_media where k='match_img')
     and name=(select object_path from _chat_media where k='match_img')),
  1,
  'storage select policy permits thread member read');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca03"}';
select is(
  (select count(*)::int from storage.objects
   where bucket_id=(select bucket_id from _chat_media where k='match_img')
     and name=(select object_path from _chat_media where k='match_img')),
  0,
  'storage select policy blocks non-member read');

select is(
  (select count(*)::int from public.message_attachments
   where id=(select attachment_id from _chat_media where k='match_img')),
  0,
  'non-member cannot select attachment metadata');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca01"}';
select lives_ok(
  $$ select public.delete_message(
    (select message_id from _chat_media where k='match_img')
  ) $$,
  'sender can delete own media message');

select is(
  (select status from public.message_attachments
   where id=(select attachment_id from _chat_media where k='match_img')),
  'hidden',
  'delete hides attachment');

select ok(
  (select delete_after between now() + interval '29 days' and now() + interval '31 days'
   from public.message_attachments
   where id=(select attachment_id from _chat_media where k='match_img')),
  'sender delete sets 30-day delete_after');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca01"}';
with upload as (
  select * from public.create_message_attachment(
    'match',
    '00000000-0000-0000-0000-00000000cb01'::uuid,
    'image',
    'image/jpeg',
    1024,
    100,
    100,
    null
  )
)
insert into _chat_media(k, attachment_id, bucket_id, object_path, owner_id)
select 'admin_remove', id, bucket_id, object_path, '00000000-0000-0000-0000-00000000ca01'::uuid
from upload;

set local role postgres;
insert into storage.objects (bucket_id, name, owner, metadata)
select bucket_id, object_path, owner_id, jsonb_build_object('size', 1024, 'mimetype', 'image/jpeg')
from _chat_media
where k='admin_remove';

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca01"}';
set local role authenticated;
with sent as (
  select public.send_media_message(
    (select attachment_id from _chat_media where k='admin_remove')
  ) as message_id
)
update _chat_media
  set message_id = sent.message_id
  from sent
  where k='admin_remove';

set local role postgres;
insert into public.admins (user_id)
values ('00000000-0000-0000-0000-00000000ca04')
on conflict (user_id) do nothing;
insert into public.reports (id, reporter_id, target_type, target_id, reason)
values (
  '00000000-0000-0000-0000-00000000cd01',
  '00000000-0000-0000-0000-00000000ca03',
  'message',
  (select message_id::text from _chat_media where k='admin_remove'),
  'media report'
);

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca04"}';
set local role authenticated;
do $$
begin
  perform public.admin_action_report('00000000-0000-0000-0000-00000000cd01'::uuid, 'remove');
end $$;

set local role postgres;
select ok(
  (select status='hidden'
      and delete_after between now() + interval '6 days' and now() + interval '8 days'
   from public.message_attachments
   where id=(select attachment_id from _chat_media where k='admin_remove')),
  'admin_action_report remove schedules 7-day attachment deletion');

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca02"}';
set local role authenticated;
with upload as (
  select * from public.create_message_attachment(
    'match',
    '00000000-0000-0000-0000-00000000cb01'::uuid,
    'image',
    'image/jpeg',
    1024,
    100,
    100,
    null
  )
)
insert into _chat_media(k, attachment_id, bucket_id, object_path, owner_id)
select 'account_delete', id, bucket_id, object_path, '00000000-0000-0000-0000-00000000ca02'::uuid
from upload;

set local role postgres;
insert into storage.objects (bucket_id, name, owner, metadata)
select bucket_id, object_path, owner_id, jsonb_build_object('size', 1024, 'mimetype', 'image/jpeg')
from _chat_media
where k='account_delete';

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca02"}';
set local role authenticated;
with sent as (
  select public.send_media_message(
    (select attachment_id from _chat_media where k='account_delete')
  ) as message_id
)
update _chat_media
  set message_id = sent.message_id
  from sent
  where k='account_delete';

do $$
begin
  perform public.request_account_deletion();
end $$;

set local role postgres;
select ok(
  (select status='hidden'
      and delete_after between now() + interval '29 days' and now() + interval '31 days'
   from public.message_attachments
   where id=(select attachment_id from _chat_media where k='account_delete')),
  'request_account_deletion schedules 30-day attachment deletion');

select * from finish();
rollback;
