-- Run with: supabase test db
-- Proves migration 20260707220000: get_store_products catalog RPC.
begin;
select plan(3);
select ok(exists(select 1 from pg_proc where proname='get_store_products'), 'get_store_products exists');
set local role authenticated;
select ok(
  (select count(*) >= 4 from public.get_store_products('android')),
  'android co >= 4 product qua RLS products_read (authenticated)');
set local role postgres;
select ok(
  (select count(*) = 0 from public.get_store_products('windows')),
  'platform la -> rong');
select * from finish();
rollback;
