-- Run with: supabase test db
-- Covers migration 0015_venues.sql:
--   1) venue_suggestion composite type carries NO raw coordinates (clients only see distance_band).
--   2) venue seed present (>= 6 rows).
begin;
select plan(2);
select hasnt_column('public','venue_suggestion'::regtype::text,'location','venue_suggestion has no raw coords');
select ok((select count(*) from public.venues) >= 6, 'venue seed present');
select * from finish();
rollback;
