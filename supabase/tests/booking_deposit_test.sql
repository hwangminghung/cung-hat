-- Run with: supabase test db
-- Proves migration 20260707190000: venues.booking_deposit_minor (server-quyet tien coc).
begin;
select plan(3);
select has_column('public', 'venues', 'booking_deposit_minor', 'venues co cot booking_deposit_minor');
select ok(
  (select count(*) = 0 from public.venues where booking_deposit_minor is null),
  'moi venue deu co deposit');
select ok(
  (select bool_and(booking_deposit_minor > 0) from public.venues),
  'deposit luon duong (CHECK)');
select * from finish();
rollback;
