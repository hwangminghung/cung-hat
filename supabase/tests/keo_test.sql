-- Run with: supabase test db
-- Covers migration 0012_keo.sql:
--   1) keo_card composite type carries NO coordinates (clients only see distance_band).
--   2) create_keo RPC exists.
begin;
select plan(2);
select hasnt_column('public','keo_card'::regtype::text,'area_geo','keo_card has no coords');
select ok(exists(select 1 from pg_proc where proname='create_keo'), 'create_keo exists');
select * from finish();
rollback;
