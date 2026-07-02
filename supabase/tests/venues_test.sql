-- Run with: supabase test db
-- Covers migration 0015_venues.sql:
--   1) venue_suggestion exposes venue coordinates for map markers.
--   2) venue_suggestion still does not expose raw geography columns.
--   3) venue seed present (>= 6 rows).
begin;
select plan(4);
select has_column('public','venue_suggestion'::regtype::text,'lat','venue_suggestion exposes venue latitude');
select has_column('public','venue_suggestion'::regtype::text,'lng','venue_suggestion exposes venue longitude');
select hasnt_column('public','venue_suggestion'::regtype::text,'location','venue_suggestion does not expose raw geography');
select ok((select count(*) from public.venues) >= 6, 'venue seed present');
select * from finish();
rollback;
