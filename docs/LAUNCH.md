# Cùng Hát — Launch Runbook

Operator checklist to bring the **HN · HCM · TN** launch boards live. Everything here
is operator-driven: the seed is a template you refine with real venues/hosts, and the
Places ingestion + push/payments creds require real accounts and billing.

---

## 1. Required env / secrets

Edge Function secrets live in the function environment (locally: `supabase/functions/.env`,
copied from `.env.example`; in production: `supabase secrets set ...`). Keep all of these
out of the app and out of git.

### Places venue ingestion (this phase)
| Secret | Used by | Notes |
| --- | --- | --- |
| `GOOGLE_PLACES_API_KEY` | `ingest-places-venues` | Places API (New) enabled **with billing**. |
| `PLACES_INGEST_SECRET`  | `ingest-places-venues` | Ops-only gate; matches `x-ingest-secret` header sent by the runner. |
| `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` | `ingest-places-venues` | Service-role upsert into `public.venues`. |

### Referenced by other phases (must be set before/around launch)
| Secret | Used by | Purpose |
| --- | --- | --- |
| `PUSH_FANOUT_SECRET`, `GOOGLE_FCM_SA_JSON` | `push-fanout` | FCM push fan-out (Firebase service account). |
| `APPLE_SHARED_SECRET`, `GOOGLE_PLAY_SA_JSON` | `validate-iap` | IAP receipt validation (App Store / Play). |
| `MOMO_PARTNER_CODE`, `MOMO_ACCESS_KEY`, `MOMO_SECRET_KEY` | `create-venue-payment`, `payments-webhook` | MoMo venue payments. |
| `ZALOPAY_APP_ID`, `ZALOPAY_KEY1`, `ZALOPAY_KEY2` | `create-venue-payment`, `payments-webhook` | ZaloPay venue payments. |

Phone OTP (Supabase Auth SMS) and the SMS gateway used by `send-sms` must also be
provisioned per the auth phase before public launch.

---

## 2. Apply the launch seed — `scripts/seed_launch.sql`

Idempotent seed that puts a few curated K-style venues + founding open kèo into each
launch city so day-one boards are not empty.

> **OPERATOR:** before launch, replace the placeholder venue names/addresses and the
> founding host content in the script with real curated data. The seed is safe to
> re-run (every insert is guarded with `where not exists`).

Apply against the **target project** (production or staging):

```bash
# psql against the deployed DB
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/seed_launch.sql
```

Local stack:

```powershell
Get-Content -Raw scripts/seed_launch.sql | docker exec -i supabase_db_cung-hat psql -U postgres -d postgres -v ON_ERROR_STOP=1
```

Or paste the file contents into the **Supabase Studio → SQL editor** and run.

What it inserts (one founding host user per city, with matching profile + city-centre
location): **2–3 venues per city** and **1–2 open kèo per city** (each with the host's
`keo_members` row, `role='host'`, `join_status='approved'`, `confirmed=true`).

---

## 3. Pull real venues — `scripts/run_places_ingest.sh`

Calls the `ingest-places-venues` Edge Function once per city centre. **Requires Google
Maps billing enabled** on the `GOOGLE_PLACES_API_KEY` project.

```bash
export FUNCTIONS_URL="https://<project-ref>.supabase.co/functions/v1"  # or http://127.0.0.1:54321/functions/v1 locally
export INGEST_SECRET="<value of PLACES_INGEST_SECRET>"
./scripts/run_places_ingest.sh
```

Each call returns `{"found":N,"upserted":M}`. Venues land in `public.venues` with
`source='places'` and are de-duplicated on `places_id` (re-running upserts, never
duplicates). Review the ingested rows and toggle `is_active` for any you don't want
surfaced.

---

## 4. Verification

After seeding (and optionally Places ingestion), confirm each city's board is alive.
The discovery RPCs are `security definer` and use the **caller's** location, so verify
either through the app signed in as a user in each city, or in SQL by impersonating one
of the founding host users.

- **Open kèo per city** — `public.list_open_keos(...)` should return at least a few kèo
  for a user located in that city (the seed adds 1–2 per city; the founder's location is
  at the city centre).

  Quick raw check (bypasses the per-user RPC, just confirms the seeded rows exist):
  ```sql
  select status, count(*) from public.keo where status='open' group by status;
  ```

- **Venues near a kèo** — `public.nearest_venues_for_keo(<keo_id>)` should return venues
  (seed venues + any Places-ingested ones) ordered by distance band.

  ```sql
  select city, count(*) from public.venues where is_active group by city order by city;
  ```

Both should be non-empty for HN, HCM and TN before opening signups in a city.

---

## 5. Notes / caveats

- The seed content (venue names/addresses, founding kèo) is a **template**. Real,
  verified, curated venues and genuine founding events require operator curation before
  public launch — placeholder data must not ship.
- **Places ingestion is gated on operator credentials**: a Google Cloud project with
  Places API + billing, and the `PLACES_INGEST_SECRET` shared with the runner. Without
  billing the function returns no venues.
- Push, IAP and venue-payment flows depend on Firebase / App Store / Play / MoMo /
  ZaloPay accounts that must be provisioned separately (see the secret table above).
