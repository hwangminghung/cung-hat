-- Partial unique index so the Places ingester can upsert on places_id.
create unique index if not exists venues_places_id_ux
  on public.venues (places_id) where places_id is not null;
