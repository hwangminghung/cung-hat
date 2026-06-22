-- Run with: supabase test db
-- Proves upsert_my_taste's consent gate (migration 0005): it requires BOTH
-- `matching` AND `cross_border` consent. We fake an authenticated user via JWT
-- claims so auth.uid() resolves to a real uuid, then assert three cases:
--   1) no consents            -> reject (check_violation / 23514)
--   2) only `matching`        -> still reject (EITHER required branch missing)
--   3) both required consents -> succeeds
begin;
select plan(3);

-- The consents.user_id and user_* tables FK to auth.users(id), so the faked uid
-- must exist there. Seed it as the table owner (postgres bypasses RLS / privilege).
set local role postgres;
insert into auth.users (id) values ('00000000-0000-0000-0000-000000000001')
  on conflict (id) do nothing;

-- Fake an authenticated user so auth.uid() (request.jwt.claims->>'sub') resolves.
-- The jwt-claims GUC persists across role switches below.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-000000000001"}';
set local role authenticated;

-- Case 1: no consents granted -> reject.
select throws_ok(
  $$ select public.upsert_my_taste(array[]::text[], array[]::text[], array[]::text[]) $$,
  '23514', null, 'rejects when no consent granted');

-- Case 2: only matching granted (cross_border missing) -> still reject (EITHER-branch).
-- Seed as owner so the insert isn't gated by RLS (which would muddy the assertion).
set local role postgres;
insert into public.consents (user_id, purpose, granted, policy_version)
  values ('00000000-0000-0000-0000-000000000001','matching',true,'v1');
set local role authenticated;
select throws_ok(
  $$ select public.upsert_my_taste(array[]::text[], array[]::text[], array[]::text[]) $$,
  '23514', null, 'rejects when only matching granted');

-- Case 3: both matching + cross_border granted -> succeeds.
set local role postgres;
insert into public.consents (user_id, purpose, granted, policy_version)
  values ('00000000-0000-0000-0000-000000000001','cross_border',true,'v1');
set local role authenticated;
select lives_ok(
  $$ select public.upsert_my_taste(array[]::text[], array[]::text[], array[]::text[]) $$,
  'succeeds when both required consents granted');

select * from finish();
rollback;
