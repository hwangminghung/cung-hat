begin;
select plan(2);

-- Assertion 1: RLS with no policy ⇒ zero rows selectable directly even as authenticated.
set local role authenticated;
select is_empty($$ select * from public.user_locations $$, 'user_locations not directly selectable');

-- app_private had `revoke all ... from authenticated`, so calling app_private.dist_band
-- under role `authenticated` would raise "permission denied for schema app_private".
-- Reset to the default (superuser) role so the bucketing assertion exercises the function
-- itself rather than schema-level EXECUTE privilege.
reset role;

-- Assertion 2: bucketing 2.5km → 1-3 band.
select is(app_private.dist_band(2500), '1-3', 'bucketing 2.5km → 1-3');

select * from finish();
rollback;
