-- Run with: supabase test db
-- Proves migration 20260706110000_candidate_bio: discovery_candidate gains a
-- bio attribute, and get_discovery_candidates surfaces the candidate's bio.
-- Seed pattern copied from boost_test.sql: update_my_location RPC (direct
-- insert into user_locations is RLS-blocked), same coords for co-location.
begin;
select plan(2);

set local role postgres;

insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000c1'), -- caller A
  ('00000000-0000-0000-0000-0000000000c2')  -- other user B (has bio)
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, age_verified, bio) values
  ('00000000-0000-0000-0000-0000000000c1','A','1995-01-01', true, null),
  ('00000000-0000-0000-0000-0000000000c2','B','1995-01-01', true, 'Hat ballad ve dem')
  on conflict (id) do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000c1","role":"authenticated"}';
set local role authenticated;
select public.update_my_location(21.028, 105.854, 'HN'); -- caller A
set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000c2","role":"authenticated"}';
set local role authenticated;
select public.update_my_location(21.028, 105.854, 'HN'); -- candidate B, same coords

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000c1","role":"authenticated"}';
set local role authenticated;

select is(
  (select bio from public.get_discovery_candidates(20, 50)
     where id = '00000000-0000-0000-0000-0000000000c2'),
  'Hat ballad ve dem',
  'get_discovery_candidates tra ve dung bio cua candidate B');

select is(
  (select count(*)::int
     from pg_attribute a
     join pg_class c on c.oid = a.attrelid
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'discovery_candidate'
      and a.attnum > 0 and not a.attisdropped
      and a.attname = 'bio'),
  1,
  'discovery_candidate co attribute bio');

select * from finish();
rollback;
