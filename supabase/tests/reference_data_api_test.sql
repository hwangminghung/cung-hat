-- Run with: supabase test db
-- Public reference catalogs are read directly by the mobile client through the
-- Supabase Data API. RLS policies decide row visibility, but the API roles also
-- need explicit SELECT privileges on the tables.
begin;
select plan(8);

select ok(has_table_privilege('anon', 'public.music_genres', 'SELECT'), 'anon can read music_genres');
select ok(has_table_privilege('authenticated', 'public.music_genres', 'SELECT'), 'authenticated can read music_genres');
select ok(has_table_privilege('anon', 'public.music_artists', 'SELECT'), 'anon can read music_artists');
select ok(has_table_privilege('authenticated', 'public.music_artists', 'SELECT'), 'authenticated can read music_artists');
select ok(has_table_privilege('anon', 'public.songs', 'SELECT'), 'anon can read songs');
select ok(has_table_privilege('authenticated', 'public.songs', 'SELECT'), 'authenticated can read songs');
select ok(has_table_privilege('anon', 'public.venues', 'SELECT'), 'anon can read active venues');
select ok(has_table_privilege('authenticated', 'public.venues', 'SELECT'), 'authenticated can read active venues');

select * from finish();
rollback;
