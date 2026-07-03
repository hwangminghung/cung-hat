-- Run with: supabase test db
-- Proves migration 20260703100000_doi_swipe_upgrade: daily_like/daily_super quotas
-- (free vs Pro via app_private.is_pro()), undo_last_swipe (Pro-only rewind).
--
-- rate_limits tumbling window (0007): window_start = to_timestamp(floor(epoch(now())/epoch(p_window))*epoch(p_window)).
-- For p_window = interval '1 day' this snaps to UTC midnight, i.e. date_trunc('day', now()).
-- We seed rows already AT the day's cap so the next enforce_rate_limit call in record_swipe
-- pushes count over the limit and raises check_violation (23514).
begin;
select plan(8);

set local role postgres;

insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000f1'), -- free user
  ('00000000-0000-0000-0000-0000000000f2'), -- pro user
  ('00000000-0000-0000-0000-0000000000f3')  -- target user
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, age_verified) values
  ('00000000-0000-0000-0000-0000000000f1','Free Swiper','1990-01-01', true),
  ('00000000-0000-0000-0000-0000000000f2','Pro Swiper','1990-01-01', true),
  ('00000000-0000-0000-0000-0000000000f3','Target','1990-01-01', true)
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000f2','pro','promo')
  on conflict do nothing;

-- Case 1: free user already at the daily_like cap (30) -> next 'like' raises 23514.
insert into public.rate_limits (user_id, bucket, window_start, count) values
  ('00000000-0000-0000-0000-0000000000f1','daily_like', date_trunc('day', now()), 30)
  on conflict (user_id, bucket, window_start) do update set count = 30;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f1","role":"authenticated"}';
set local role authenticated;
select throws_ok(
  $$ select public.record_swipe('00000000-0000-0000-0000-0000000000f3','like') $$,
  '23514', null, 'free user over daily_like cap raises on like');

-- Case 2: same free user can still pass (pass has no quota check).
select lives_ok(
  $$ select public.record_swipe('00000000-0000-0000-0000-0000000000f3','pass') $$,
  'free user over like cap can still pass');

-- Case 3: free user with 1 seeded daily_super row -> super raises 23514 (free cap = 1).
set local role postgres;
insert into public.rate_limits (user_id, bucket, window_start, count) values
  ('00000000-0000-0000-0000-0000000000f1','daily_super', date_trunc('day', now()), 1)
  on conflict (user_id, bucket, window_start) do update set count = 1;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f1","role":"authenticated"}';
set local role authenticated;
select throws_ok(
  $$ select public.record_swipe('00000000-0000-0000-0000-0000000000f3','super') $$,
  '23514', null, 'free user over daily_super cap (1) raises on super');

-- Case 4: pro user with 30 seeded daily_like rows -> like still lives_ok (Pro bypasses daily_like quota).
set local role postgres;
insert into public.rate_limits (user_id, bucket, window_start, count) values
  ('00000000-0000-0000-0000-0000000000f2','daily_like', date_trunc('day', now()), 30)
  on conflict (user_id, bucket, window_start) do update set count = 30;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f2","role":"authenticated"}';
set local role authenticated;
select lives_ok(
  $$ select public.record_swipe('00000000-0000-0000-0000-0000000000f3','like') $$,
  'pro user bypasses daily_like cap');

-- Case 5: free user -> undo_last_swipe() raises 23514 (pro_required).
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f1","role":"authenticated"}';
set local role authenticated;
select throws_ok(
  $$ select public.undo_last_swipe() $$,
  '23514', null, 'free user blocked from undo_last_swipe (pro_required)');

-- Case 6: pro user -> undo_last_swipe() returns true after their like in Case 4.
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f2","role":"authenticated"}';
set local role authenticated;
select is(
  (select public.undo_last_swipe()),
  true,
  'pro user can undo their last swipe');

-- Case 7: pro user's swipes count = 0 after undo.
set local role postgres;
select is(
  (select count(*)::int from public.swipes where swiper_id = '00000000-0000-0000-0000-0000000000f2'),
  0,
  'pro user has zero swipes after undo');

-- Case 8: after undo, the pro user can re-swipe the SAME target -- the unique
-- (swiper_id, target_type, target_id) slot was freed by the delete.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000f2","role":"authenticated"}';
set local role authenticated;
select lives_ok(
  $$ select public.record_swipe('00000000-0000-0000-0000-0000000000f3','like') $$,
  'pro user can re-swipe the same target after undo');

select * from finish();
rollback;
