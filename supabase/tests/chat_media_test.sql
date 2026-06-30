begin;
select plan(13);

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

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000ca01"}';
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

set local role postgres;
select is(
  (select status from public.message_attachments
   where owner_id='00000000-0000-0000-0000-00000000ca01'
   order by created_at desc limit 1),
  'pending',
  'created attachment is pending');

set local role authenticated;
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
