-- Run with: supabase test db
-- Proves migration 20260707190000: venues.booking_deposit_minor (server-quyet tien coc):
--   1) cot ton tai; 2) NOT NULL (introspection); 3) co default (introspection);
--   4) CHECK that su chan deposit <= 0 (negative path, SQLSTATE 23514).
begin;
select plan(4);
select has_column('public', 'venues', 'booking_deposit_minor', 'venues co cot booking_deposit_minor');
select col_not_null('public', 'venues', 'booking_deposit_minor', 'deposit khong null');
select col_has_default('public', 'venues', 'booking_deposit_minor', 'deposit co default');
select throws_ok(
  $$ update public.venues set booking_deposit_minor = 0
     where id = (select id from public.venues limit 1) $$,
  '23514', null, 'CHECK chan deposit <= 0');
select * from finish();
rollback;
