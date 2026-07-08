-- Webhook doi chieu booking theo gateway_ref (.maybeSingle) — unique index lam
-- dieu do thanh hop dong DB, chong race/duplicate ref.
create unique index if not exists venue_bookings_gateway_ref_ux
  on public.venue_bookings (gateway_ref)
  where gateway_ref is not null;
