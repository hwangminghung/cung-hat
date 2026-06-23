-- Run with: supabase test db
-- Proves app_private.enforce_rate_limit (migration 0007) honors p_limit within a
-- single tumbling window. We fake an authenticated user via JWT claims so
-- auth.uid() (request.jwt.claims->>'sub') resolves to a real uuid.
--
-- enforce_rate_limit lives in the `app_private` schema, whose execute is revoked
-- from authenticated/anon. So unlike consent_gate_test we DO NOT `set role
-- authenticated` for these calls — we stay as postgres (superuser), which can
-- call it. The function still reads auth.uid() from the GUC, so we set the
-- jwt-claims even while running as postgres.
--
-- With p_limit = 2 and a 1-day window the three calls land in the same window:
--   1st call -> count 1 (1 > 2 false)  -> lives_ok
--   2nd call -> count 2 (2 > 2 false)  -> lives_ok
--   3rd call -> count 3 (3 > 2 true)   -> throws_ok (check_violation / 23514)
begin;
select plan(3);

-- rate_limits.user_id FKs to auth.users(id), so the faked uid must exist there.
-- Seed it as the table owner (postgres bypasses RLS / privilege).
set local role postgres;
insert into auth.users (id) values ('00000000-0000-0000-0000-000000000002')
  on conflict (id) do nothing;

-- Fake an authenticated user so auth.uid() resolves inside enforce_rate_limit.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-000000000002"}';

-- Call 1: count -> 1, not > 2 -> succeeds.
select lives_ok(
  $$ select app_private.enforce_rate_limit('t', 2, interval '1 day') $$,
  '1st call within limit succeeds');

-- Call 2: count -> 2, not > 2 -> succeeds.
select lives_ok(
  $$ select app_private.enforce_rate_limit('t', 2, interval '1 day') $$,
  '2nd call at limit succeeds');

-- Call 3: count -> 3, > 2 -> rate_limit_exceeded (errcode check_violation / 23514).
select throws_ok(
  $$ select app_private.enforce_rate_limit('t', 2, interval '1 day') $$,
  '23514', null, '3rd call over limit raises rate_limit_exceeded');

select * from finish();
rollback;
