-- Run with: supabase test db
-- Proves migration 20260706100000_discovery_prefs: discovery_prefs table (self-only RLS,
-- writes only via RPC) + get/set_discovery_auto_expand RPCs.
-- Seed pattern copied from photos_test.sql / doi_swipe_upgrade_test.sql.
begin;
select plan(5);

set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000e1'),  -- caller A
  ('00000000-0000-0000-0000-0000000000e2')   -- other user B
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, age_verified) values
  ('00000000-0000-0000-0000-0000000000e1','A','1995-01-01', true),
  ('00000000-0000-0000-0000-0000000000e2','B','1995-01-01', true)
  on conflict (id) do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1","role":"authenticated"}';
set local role authenticated;

select is(public.get_discovery_auto_expand(), false, 'mac dinh false khi chua co dong prefs');
select lives_ok($$select public.set_discovery_auto_expand(true)$$, 'set on chay duoc');
select is(public.get_discovery_auto_expand(), true, 'doc lai ra true');

-- self-only: B khong thay dong cua A
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e2","role":"authenticated"}';
set local role authenticated;
select is(
  (select count(*)::int from public.discovery_prefs),
  0, 'RLS: B khong select duoc prefs cua A');
select is(public.get_discovery_auto_expand(), false, 'B van mac dinh false');

select * from finish();
rollback;
