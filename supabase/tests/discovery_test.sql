-- Run with: supabase test db
-- Privacy boundary check for migration 0008: the discovery_candidate composite type
-- must NOT expose any location/coordinate column (clients only ever see a distance_band),
-- and the get_discovery_candidates RPC must exist.
begin;
select plan(2);

-- 1) The return type must NOT contain any location/coord column. A composite type has a
-- pg_class entry (relkind 'c'); assert no attribute named location/lat/lng/coords/loc.
select is(
  (select count(*)::int
     from pg_attribute a
     join pg_class c on c.oid = a.attrelid
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'discovery_candidate'
      and a.attnum > 0 and not a.attisdropped
      and a.attname in ('location','lat','lng','coords','loc')),
  0,
  'no location/coord column in discovery_candidate type');

-- 2) The RPC exists.
select ok(exists(select 1 from pg_proc where proname='get_discovery_candidates'), 'RPC exists');

select * from finish();
rollback;
