-- Run with: supabase test db
-- Proves migration 20260707120000_match_profile: get_match_profile RPC.
--   * a match member gets back the other user's discovery_candidate composite
--     (display_name correct)
--   * shared_baitu surfaces a song both users have in their bai tu
--   * a bystander (not a match member) is rejected via app_private.in_match (23514)
--   * if the other user has soft-deleted their profile, the composite comes
--     back as a NULL row (id null) instead of raising -- client maps this to
--     "ho so khong con".
-- Seed pattern copied from chat_test.sql (fixed uuids, JWT-claims impersonation)
-- + profile_prompts_test.sql (profiles minimal columns) + 0004_onboarding.sql
-- (songs.id is `text references public.songs(id)` -- user_baitu needs a real
-- songs row seeded first, no existing pgTAP test seeds user_baitu directly).
begin;
select plan(4);

-- Fixed uuids (hex-only segments -- 'm' is NOT a valid hex digit, unlike
-- chat_test.sql's a1/a2/c3/d4 style). user_a < user_b required by matches'
-- canonical-ordering CHECK.
-- A = 00000000-0000-0000-0000-0000000000f1 (caller / member)
-- B = 00000000-0000-0000-0000-0000000000f2 (matched other user)
-- C = 00000000-0000-0000-0000-0000000000f3 (bystander, not a member)
-- match id = 00000000-0000-0000-0000-0000000000f4

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000f1'),
  ('00000000-0000-0000-0000-0000000000f2'),
  ('00000000-0000-0000-0000-0000000000f3')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, age_verified) values
  ('00000000-0000-0000-0000-0000000000f1','A','1995-01-01', true),
  ('00000000-0000-0000-0000-0000000000f2','B','1995-01-01', true),
  ('00000000-0000-0000-0000-0000000000f3','C','1995-01-01', true)
  on conflict (id) do nothing;
insert into public.matches (id, user_a, user_b, status) values
  ('00000000-0000-0000-0000-0000000000f4',
   '00000000-0000-0000-0000-0000000000f1',
   '00000000-0000-0000-0000-0000000000f2',
   'active')
  on conflict (id) do nothing;

-- Shared bai tu: both A and B have song 'song-chung' in their user_baitu.
insert into public.songs (id, title, artist) values
  ('song-chung', 'Noi Nay Co Anh', 'Son Tung MTP')
  on conflict (id) do nothing;
insert into public.user_baitu (user_id, song_id, position) values
  ('00000000-0000-0000-0000-0000000000f1', 'song-chung', 0),
  ('00000000-0000-0000-0000-0000000000f2', 'song-chung', 0)
  on conflict (user_id, song_id) do nothing;

-- 1) member (A) calls -> display_name of the OTHER user (B) is correct.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f1","role":"authenticated"}';
set local role authenticated;
select is(
  ((public.get_match_profile('00000000-0000-0000-0000-0000000000f4')).display_name),
  'B',
  'member (A) gets the other user (B) display_name');

-- 2) shared_baitu contains the common song.
select is(
  ((public.get_match_profile('00000000-0000-0000-0000-0000000000f4')).shared_baitu),
  array['song-chung'],
  'shared_baitu surfaces the common song');

-- 3) bystander (C) -> not_match_member (23514).
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f3","role":"authenticated"}';
set local role authenticated;
select throws_ok(
  $$ select public.get_match_profile('00000000-0000-0000-0000-0000000000f4'::uuid) $$,
  '23514', null, 'bystander (C) cannot read the match profile');

-- 4) other user (B) soft-deletes -> composite comes back NULL-row (id null).
set local role postgres;
update public.profiles set soft_deleted_at = now()
  where id = '00000000-0000-0000-0000-0000000000f2';
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f1","role":"authenticated"}';
set local role authenticated;
select is(
  ((public.get_match_profile('00000000-0000-0000-0000-0000000000f4')).id),
  null,
  'soft-deleted other user -> composite NULL row (id null)');

reset role;
select * from finish();
rollback;
