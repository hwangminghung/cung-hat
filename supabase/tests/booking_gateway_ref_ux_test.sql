-- Run with: supabase test db
-- Proves migration 20260707210000: gateway_ref unique (partial, non-null).
begin;
select plan(2);
select has_index('public', 'venue_bookings', 'venue_bookings_gateway_ref_ux', 'unique index gateway_ref ton tai');
insert into public.venue_bookings (venue_id, amount_minor, gateway, gateway_ref, state)
  select id, booking_deposit_minor, 'momo', 'dup-ref-1', 'initiated' from public.venues limit 1;
select throws_ok($$
  insert into public.venue_bookings (venue_id, amount_minor, gateway, gateway_ref, state)
  select id, booking_deposit_minor, 'momo', 'dup-ref-1', 'initiated' from public.venues limit 1
$$, '23505', null, 'trung gateway_ref bi chan');
select * from finish();
rollback;
