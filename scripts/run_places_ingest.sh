#!/usr/bin/env bash
# Run the P4 `ingest-places-venues` Edge Function once per launch-city centre, to
# pull real karaoke venues from Google Places into public.venues (source='places').
#
# Requires (no secrets are hardcoded):
#   FUNCTIONS_URL  — Edge Functions base, e.g. http://127.0.0.1:54321/functions/v1
#                    or the deployed project URL https://<ref>.supabase.co/functions/v1
#   INGEST_SECRET  — must match PLACES_INGEST_SECRET in the function's env
#
# The function itself needs GOOGLE_PLACES_API_KEY (with Places API + billing enabled)
# configured in its own environment — see docs/LAUNCH.md.
#
# Usage:
#   FUNCTIONS_URL=https://<ref>.supabase.co/functions/v1 INGEST_SECRET=... ./scripts/run_places_ingest.sh
set -euo pipefail

: "${FUNCTIONS_URL:?set FUNCTIONS_URL}"
: "${INGEST_SECRET:?set INGEST_SECRET}"

post() {
  curl -fsS -X POST "$FUNCTIONS_URL/ingest-places-venues" \
    -H "x-ingest-secret: $INGEST_SECRET" \
    -H "Content-Type: application/json" \
    -d "$1"
  echo
}

# City centres: HCM 106.700,10.776 · HN 105.795,21.030 · TN 105.842,21.594
post '{"city":"HCM","lat":10.776,"lng":106.700,"radius_m":6000}'
post '{"city":"HN","lat":21.030,"lng":105.795,"radius_m":6000}'
post '{"city":"TN","lat":21.594,"lng":105.842,"radius_m":6000}'
