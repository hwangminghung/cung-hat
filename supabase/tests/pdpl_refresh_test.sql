-- Run with: supabase test db
-- Proves 20260708110000: deletion xoa device_tokens/prompts + clear photo_paths;
-- export chua cac khoa moi (prompts/messages_sent/purchases/...).
begin;
select plan(7);
set local role postgres;
insert into auth.users (id) values ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01') on conflict do nothing;
insert into public.profiles (id, display_name, dob, photo_paths) values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01','Del Test','1990-01-01', array['x/1.jpg'])
  on conflict (id) do nothing;
insert into public.device_tokens (user_id, fcm_token, platform) values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01','del-fcm','android');
-- seed 1 profile_prompts cho user nay (schema 20260706130000_profile_prompts.sql:
-- user_id, prompt_id, answer, position).
insert into public.profile_prompts (user_id, prompt_id, answer, position) values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01','p1','Test answer',0);

set local request.jwt.claims to '{"sub":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01","role":"authenticated"}';
set local role authenticated;

-- 1-3) export co cac khoa moi:
select ok(public.export_my_data() ? 'prompts', 'export co prompts');
select ok(public.export_my_data() ? 'messages_sent', 'export co messages_sent');
select ok(public.export_my_data() ? 'purchases', 'export co purchases');

-- 4) deletion chay:
select lives_ok($$ select public.request_account_deletion() $$, 'deletion chay tron');

set local role postgres;
-- 5-7) device_tokens/prompts sach + photo_paths rong:
select is((select count(*)::int from public.device_tokens where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01'), 0, 'device_tokens da xoa');
select is((select count(*)::int from public.profile_prompts where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01'), 0, 'prompts da xoa');
select is((select photo_paths from public.profiles where id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01'), '{}'::text[], 'photo_paths da clear');

select * from finish();
rollback;
