# Cung Hat - Pro Pricing and Keo Boost Design

Date: 2026-07-01
Status: approved for spec review

## Goal

Turn the current Pro and Boost placeholders into a launch-ready pricing model:

- Pro should feel affordable enough for early Vietnam users, while still supporting recurring revenue.
- A one-time Pro Lifetime offer is allowed during launch, then removed when the paid user base is large enough.
- "Day keo len top" should be a consumable boost attached to one open keo, not an unlimited Pro privilege.

## Decisions

Use the launch-balanced pricing approach:

| Product | Price | Notes |
| --- | ---: | --- |
| Pro Monthly | 79,000 VND | Recurring subscription |
| Pro Yearly | 599,000 VND | Recurring subscription, positioned as better value |
| Pro Lifetime Launch | 249,000 VND | Sold only before the first paid-user threshold |
| Pro Lifetime Last Call | 299,000 VND | Sold only between the first and final paid-user thresholds |
| Keo Boost 24h | 29,000 VND | One boost credit, applies to one keo for 24 hours |
| Keo Boost 3-pack | 79,000 VND | Three boost credits |

Lifetime Pro is controlled only by paid Pro user count:

- Below 500 paid Pro users: show Lifetime Launch at 249,000 VND.
- From 500 to 1,499 paid Pro users: show Lifetime Last Call at 299,000 VND with "sap ket thuc" copy.
- At 1,500 paid Pro users and above: hide lifetime products from Store.
- Users who already bought lifetime keep Pro forever.
- Paid Pro users means distinct users with at least one validated Pro purchase: monthly, yearly, or lifetime. Boost-only buyers do not count.

## Non-Goals

- Do not implement full Apple/Google subscription lifecycle webhooks in this slice.
- Do not make Pro give unlimited top placement.
- Do not add dynamic/peak pricing by city or weekend.
- Do not change existing Pro creation/join gates beyond product catalog and entitlement duration.
- Do not refactor unrelated keo, chat media, plan, OTP, map, or generated files.

## Product Catalog

Keep `public.products` as the store-facing catalog, but expand it so the app does not hardcode product IDs.

Recommended product rows:

| sku | type | platform | store_product_id | price_minor |
| --- | --- | --- | --- | ---: |
| pro_monthly_ios | pro | ios | com.cunghat.pro.monthly | 79000 |
| pro_monthly_android | pro | android | pro_monthly | 79000 |
| pro_yearly_ios | pro | ios | com.cunghat.pro.yearly | 599000 |
| pro_yearly_android | pro | android | pro_yearly | 599000 |
| pro_lifetime_launch_ios | pro | ios | com.cunghat.pro.lifetime.launch | 249000 |
| pro_lifetime_launch_android | pro | android | pro_lifetime_launch | 249000 |
| pro_lifetime_final_ios | pro | ios | com.cunghat.pro.lifetime.final | 299000 |
| pro_lifetime_final_android | pro | android | pro_lifetime_final | 299000 |
| keo_boost_24h_ios | boost | ios | com.cunghat.keo.boost.24h | 29000 |
| keo_boost_24h_android | boost | android | keo_boost_24h | 29000 |
| keo_boost_3_ios | boost | ios | com.cunghat.keo.boost.3 | 79000 |
| keo_boost_3_android | boost | android | keo_boost_3 | 79000 |

Add metadata columns rather than inferring behavior from SKU strings:

- `billing_period text` with values `monthly`, `yearly`, `lifetime`, `consumable`.
- `entitlement_days int null`: 31 for monthly placeholder validation, 366 for yearly placeholder validation, null for lifetime and boost.
- `boost_credits int not null default 0`: 1 for boost 24h, 3 for boost 3-pack.
- `sort_order int not null default 0`.
- `badge text null`: optional Store chip such as `launch`, `best_value`, `ending_soon`.

Existing `pro_ios` / `pro_android` rows should not be used for new UI. The migration can leave them inactive to avoid breaking historical purchase rows.

## Store Product RPC

Add:

```sql
public.get_store_products(p_platform text)
returns setof public.store_product
```

This RPC is the only Store catalog read path in Flutter. It returns active products for the requested platform and applies lifetime visibility:

- It calls `app_private.paid_pro_user_count()`.
- It returns one lifetime product at most.
- It hides both lifetime products at 1,500 paid Pro users.
- It still returns monthly, yearly, boost 24h, and boost 3-pack.

The app can still read `products` in tests, but production UI should use the RPC so threshold logic stays server-side.

Because new public tables/functions must be explicitly exposed in newer Supabase projects, migrations must include RLS plus explicit `GRANT` statements for `authenticated` where the Data API or RPC is used.

## Purchase Delivery

Update `supabase/functions/validate-iap`:

- Continue resolving the caller from the JWT; never accept a user id from the request body.
- Look up the product by `platform` and `store_product_id`.
- Upsert the validated purchase as today.
- For Pro products:
  - Monthly/yearly create or extend `entitlements.feature = 'pro'` with `active_until`.
  - Lifetime creates `entitlements.feature = 'pro'` with `active_until = null`.
- For Boost products:
  - Do not grant `entitlements.feature = 'boost'`.
  - Insert boost credit rows based on `products.boost_credits`.

This intentionally separates Pro entitlement from keo visibility boosts. The previous entitlement-style boost can remain as legacy data, but new "day keo len top" logic must use boost credits.

## Boost Credits and Keo Boosts

Add a credit ledger:

```sql
public.keo_boost_credits (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  purchase_id uuid references public.purchases(id),
  source text not null check (source in ('purchase','pro_monthly_bonus','promo')),
  status text not null check (status in ('available','used','expired')),
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  used_at timestamptz,
  used_on_keo_id uuid references public.keo(id)
)
```

Add active boost rows:

```sql
public.keo_boosts (
  id uuid primary key,
  keo_id uuid not null references public.keo(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  credit_id uuid not null references public.keo_boost_credits(id),
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  status text not null check (status in ('active','expired','cancelled')),
  created_at timestamptz not null default now()
)
```

Rules:

- Only the keo host can apply a boost.
- Only `open` keo can be boosted.
- Full, expired, cancelled, or soft-deleted keo cannot be boosted.
- One active boost per keo at a time.
- A boost lasts 24 hours from application.
- Pro users receive one monthly bonus boost credit, but no unlimited top placement.

The monthly Pro bonus is issued lazily by `apply_keo_boost`: if the host is Pro and has not used a `pro_monthly_bonus` credit in the current Vietnam-local month, the RPC creates and immediately spends one bonus credit. This avoids a cron requirement in the first implementation.

## Keo Boost RPCs

Add:

```sql
public.get_my_boost_credits()
returns table (available_count int, next_expiring_at timestamptz)
```

Add:

```sql
public.apply_keo_boost(p_keo uuid)
returns table (boost_id uuid, ends_at timestamptz)
```

`apply_keo_boost` must:

- Lock the keo row or use an advisory transaction lock.
- Verify the caller is host.
- Verify the keo is boostable.
- Spend one available credit or the current Pro monthly bonus.
- Insert `keo_boosts` with `ends_at = now() + interval '24 hours'`.
- Mark the credit as used atomically.

Error codes:

- `not_keo_host`
- `keo_not_boostable`
- `boost_already_active`
- `no_boost_credit`

All should use `errcode='check_violation'` so Flutter can map them consistently.

## Keo Board Ranking

Extend `public.keo_card` and `public.list_open_keos`:

- Add `is_boosted boolean`.
- Add `boost_ends_at timestamptz`.

Ranking:

1. Active boosted keo first.
2. Among boosted keo, most recently boosted first.
3. Non-boosted keo keep the existing `time_window_start asc` order.

Only active boosts count:

- `keo_boosts.status = 'active'`
- `starts_at <= now()`
- `ends_at > now()`
- keo is still `open`
- keo is not full or expired

The UI should show a small "Noi bat" / "Dang day" chip, not a misleading organic match label.

## Flutter Changes

Billing:

- Replace `_storeProductIds` in `IapController` with products from `get_store_products(platform)`.
- Model a store product with SKU, type, price, period, credit count, badge, and store product id.
- Use consumable purchase flow for boost products and non-consumable/subscription flow for Pro products according to store product metadata.
- Invalidate entitlements and boost credit providers after delivery.

Store screen:

- Show Pro Monthly, Pro Yearly, and the currently available Lifetime product if returned by the RPC.
- Show Boost 24h and Boost 3-pack separately from Pro.
- Explain Pro benefits compactly: create keo, join more than one active keo, premium filters, see likes, one monthly boost credit.
- Lifetime copy must say it is a launch offer and can disappear once enough paid Pro users join.

Keo detail:

- Host sees "Day keo" when the keo is open and boostable.
- If credits are available, confirm and call `apply_keo_boost`.
- If no credits are available, open the boost purchase options.
- If a boost is active, show the remaining time and disable applying another boost.

Keo board/card:

- Show boosted badge.
- Keep existing join-mode and distance/time UI.

## Security and Privacy

- Do not trust client-provided price, duration, credit count, or entitlement feature.
- Use product metadata from the database after validating the store product id.
- Boost ordering can expose that a keo is boosted, but should not expose purchase id, credit id, host revenue, or ranking scores.
- RLS:
  - Users can read their own purchases, entitlements, and boost credits.
  - Users can read boost status through sanitized keo cards.
  - Users cannot insert/update boost credits directly.
  - Applying boosts happens through RPC.
- New public tables/functions must have explicit grants and RLS.

## Testing

SQL tests:

- `get_store_products` returns lifetime launch below 500 paid Pro users.
- It returns lifetime final from 500 to 1,499 paid Pro users.
- It hides lifetime at 1,500 paid Pro users.
- Paid Pro user count includes distinct validated Pro purchasers only.
- Boost purchases create the correct number of available credits.
- Pro purchases create/extend Pro entitlement; lifetime has `active_until is null`.
- Applying boost rejects non-host, closed keo, full keo, expired keo, and already boosted keo.
- Applying boost spends one credit atomically and creates a 24h active boost.
- Pro monthly bonus can be used once per Vietnam-local month.
- `list_open_keos` orders active boosted keo before non-boosted keo and exposes `is_boosted`.

Flutter tests:

- Store product provider renders the correct product set and hides lifetime when the RPC omits it.
- IAP controller buys using server-provided store product ids.
- Store screen separates Pro and Boost products.
- Keo detail shows boost CTA only for host-owned open keo.
- No-credit boost path opens purchase options.
- Successful boost invalidates keo board/detail providers.
- Error codes map to Vietnamese UI copy.

Verification after implementation:

```powershell
flutter analyze
flutter test test/features/billing test/features/keo
supabase test db
flutter build apk --debug --dart-define-from-file=env/dev.json
```

## Rollout

1. Ship catalog RPC, product metadata, and Store UI first.
2. Ship boost credits and apply-boost flow behind the same Store release.
3. Keep legacy `pro_ios` / `pro_android` inactive, not deleted.
4. Configure all Apple/Google products before enabling the UI in production.
5. Monitor paid Pro user count. Lifetime visibility changes automatically through the RPC thresholds.

## Risks

- Existing code treats `pro` as a superset that includes `boost`; implementation must not let that become unlimited top placement.
- App Store / Play Console product IDs are permanent enough to deserve careful naming before release.
- Subscription expiry is only as good as store validation. The placeholder validator can support dev, but production needs real Apple/Google verification before paid launch.
- Boost ranking can make the board feel pay-to-win if too many boosts are active. The one-active-boost-per-keo rule and 24h duration are the first guardrails.
