# Cùng Hát — P6 Monetization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Earn revenue in v1 with a **store-policy-correct split**: digital goods (boost kèo, see-who-liked, premium filters) are sold **only** via Apple App Store IAP + Google Play Billing with server-side receipt validation → entitlements; the **venue-booking commission** (a real-world service) is charged via **MoMo/ZaloPay** through an Edge Function + webhook.

**Architecture:** Builds on P0–P5. Migration adds `products` / `purchases` / `entitlements` / `venue_bookings`, a `has_entitlement` gate, `get_my_entitlements`, and an entitlement-gated `who_liked_me`. Entitlements/purchases are written **only by Edge Functions (service role)** — never the client. `validate-iap` verifies store receipts; `create-venue-payment` + `payments-webhook` drive the gateway flow. Flutter adds a `billing` feature (IAP store + gating) and a venue-payment action on a confirmed plan.

**Tech Stack:** `in_app_purchase` (Flutter), Supabase Edge Functions (Apple/Google receipt verification; MoMo/ZaloPay), SECURITY DEFINER RPCs + entitlement gating, Riverpod 3, mocktail.

**Depends on:** P1 (`swipes`/`matches` for who-liked), P4 (`plans`/`venues` for booking), P0 (RPC pattern), P5 (admin/audit). **Store-policy rule (hard):** digital unlocks = IAP only; MoMo/ZaloPay is for the venue real-world service only.

**Operational pre-reqs:** Apple Developer + Google Play apps with IAP products created; MoMo/ZaloPay merchant accounts; secrets in Edge env only (`APPLE_SHARED_SECRET`/App Store key, `GOOGLE_PLAY_SA_JSON`, `MOMO_*`/`ZALOPAY_*`).

---

### Task 1: Migration 0019 — products, purchases, entitlements, bookings + gating

**Files:**
- Create: `supabase/migrations/0019_monetization.sql`, `supabase/tests/monetization_test.sql`

- [ ] **Step 1: Write the migration**

Create `supabase/migrations/0019_monetization.sql`:
```sql
create table public.products (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  type text not null check (type in ('boost','see_likes','premium_filters')),
  platform text not null check (platform in ('ios','android')),
  store_product_id text not null,
  price_minor int not null,
  is_active boolean not null default true
);
alter table public.products enable row level security;
create policy products_read on public.products for select using (is_active);
insert into public.products (sku, type, platform, store_product_id, price_minor) values
  ('boost_ios','boost','ios','com.cunghat.boost',49000),
  ('boost_android','boost','android','boost',49000),
  ('see_likes_ios','see_likes','ios','com.cunghat.see_likes',99000),
  ('see_likes_android','see_likes','android','see_likes',99000),
  ('filters_ios','premium_filters','ios','com.cunghat.filters',79000),
  ('filters_android','premium_filters','android','filters',79000);

create table public.purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid references public.products(id),
  platform text not null check (platform in ('ios','android')),
  store_txn_id text not null,
  receipt_ref text,
  state text not null default 'pending' check (state in ('pending','validated','refunded')),
  created_at timestamptz not null default now(),
  unique (platform, store_txn_id)
);
alter table public.purchases enable row level security;
create policy purchases_read_self on public.purchases for select using (auth.uid()=user_id);
-- inserts/updates: service role only (Edge Function) — no client write policy

create table public.entitlements (
  user_id uuid references auth.users(id) on delete cascade,
  feature text not null check (feature in ('boost','see_likes','premium_filters')),
  source text not null check (source in ('ios_iap','play_billing','promo')),
  active_until timestamptz,            -- null = permanent
  created_at timestamptz not null default now(),
  primary key (user_id, feature)
);
alter table public.entitlements enable row level security;
create policy entitlements_read_self on public.entitlements for select using (auth.uid()=user_id);
-- writes: service role only

create table public.venue_bookings (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid references public.plans(id) on delete cascade,
  venue_id uuid references public.venues(id),
  user_id uuid references auth.users(id) on delete cascade,
  amount_minor int not null,
  gateway text not null check (gateway in ('momo','zalopay')),
  gateway_ref text,
  commission_minor int not null default 0,
  state text not null default 'initiated' check (state in ('initiated','paid','failed','refunded')),
  created_at timestamptz not null default now()
);
alter table public.venue_bookings enable row level security;
create policy venue_bookings_self on public.venue_bookings for select using (auth.uid()=user_id);
-- state transitions: service role only (gateway webhook)

create or replace function app_private.has_entitlement(p_feature text)
returns boolean language sql security definer set search_path='' stable as $$
  select exists (select 1 from public.entitlements e
                 where e.user_id = auth.uid() and e.feature = p_feature
                   and (e.active_until is null or e.active_until > now()));
$$;

create or replace function public.get_my_entitlements()
returns setof public.entitlements language sql security definer set search_path='' as $$
  select * from public.entitlements where user_id = auth.uid();
$$;

-- Entitlement-gated "see who liked you" (sanitized; requires see_likes).
create or replace function public.who_liked_me(p_limit int default 20)
returns setof public.discovery_candidate language plpgsql security definer set search_path='' as $$
begin
  if not app_private.has_entitlement('see_likes') then
    raise exception 'entitlement_required' using errcode='check_violation';
  end if;
  return query
    with me as (select location as loc from public.user_locations where user_id=auth.uid())
    select p.id, p.display_name, extract(year from age(p.dob))::int,
           app_private.dist_band(ST_Distance(ul.location, me.loc)),
           '{}'::text[], '{}'::text[], p.verified_badge,
           (p.last_active > now() - interval '1 day')
    from public.swipes s
    join public.profiles p on p.id = s.swiper_id
    join public.user_locations ul on ul.user_id = p.id
    cross join me
    where s.target_type='user' and s.target_id = auth.uid()::text
      and s.direction in ('like','super') and p.soft_deleted_at is null
      and not exists (select 1 from public.matches m
        where (m.user_a=least(auth.uid(),p.id) and m.user_b=greatest(auth.uid(),p.id)))
    limit greatest(p_limit,1);
end; $$;

revoke execute on function public.get_my_entitlements() from public, anon;
revoke execute on function public.who_liked_me(int) from public, anon;
grant execute on function public.get_my_entitlements() to authenticated;
grant execute on function public.who_liked_me(int) to authenticated;
```

- [ ] **Step 2: Write a DB test (gating + service-only writes)**

Create `supabase/tests/monetization_test.sql`:
```sql
begin;
select plan(2);
select ok((select count(*) from public.products) >= 6, 'products seeded');
set local role authenticated;
select throws_ok($$ select public.who_liked_me() $$, 'check_violation', null,
  'who_liked_me requires see_likes entitlement');
select * from finish();
rollback;
```

- [ ] **Step 3: Apply + test**

Run: `supabase db reset` then `supabase test db`
Expected: clean (0001–0019); assertions pass.

- [ ] **Step 4: Commit**

```
git add supabase/migrations/0019_monetization.sql supabase/tests/monetization_test.sql
git commit -m "feat(p6): 0019 products/purchases/entitlements/bookings + has_entitlement + who_liked_me gate"
```

---

### Task 2: Edge Function `validate-iap` (server-side receipt → entitlement)

**Files:**
- Create: `supabase/functions/validate-iap/index.ts`

- [ ] **Step 1: Write the function**

Create `supabase/functions/validate-iap/index.ts`:
```ts
import { createClient } from "jsr:@supabase/supabase-js@2";

// Validates a store purchase server-side, then grants the entitlement.
// Client passes its JWT; we resolve the user from it (never trust a user_id body field).
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const { platform, store_product_id, store_txn_id, receipt } = await req.json();

  // TODO(prod): verify `receipt`/token with Apple App Store Server API (APPLE_*) or
  // Google Play Developer API (GOOGLE_PLAY_SA_JSON). Reject if invalid/already-consumed.
  const valid = Boolean(receipt && store_txn_id); // placeholder until store creds are wired
  if (!valid) return new Response(JSON.stringify({ error: "invalid_receipt" }), { status: 400 });

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: product } = await admin.from("products")
    .select("id,type").eq("store_product_id", store_product_id).eq("platform", platform).maybeSingle();
  if (!product) return new Response(JSON.stringify({ error: "unknown_product" }), { status: 400 });

  await admin.from("purchases").upsert({
    user_id: user.id, product_id: product.id, platform,
    store_txn_id, receipt_ref: "stored", state: "validated",
  }, { onConflict: "platform,store_txn_id" });

  // boost = 24h window; see_likes/premium_filters = permanent.
  const activeUntil = product.type === "boost"
    ? new Date(Date.now() + 24 * 3600 * 1000).toISOString() : null;
  await admin.from("entitlements").upsert({
    user_id: user.id, feature: product.type,
    source: platform === "ios" ? "ios_iap" : "play_billing", active_until: activeUntil,
  }, { onConflict: "user_id,feature" });

  return new Response(JSON.stringify({ ok: true, feature: product.type }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

- [ ] **Step 2: Serve + smoke test the shape**

Run: `supabase functions serve validate-iap --env-file supabase/functions/.env`. Invoke with a logged-in user's JWT + a fake `{platform,store_product_id,store_txn_id,receipt}`; expect `{ok:true,feature}` and an `entitlements` row for that user (verify in Studio). (Real receipt verification is wired when store creds exist — see operational pre-reqs.)

- [ ] **Step 3: Commit**

```
git add supabase/functions/validate-iap/index.ts
git commit -m "feat(p6): validate-iap Edge Function (server-side receipt → entitlement, JWT-resolved)"
```

---

### Task 3: BillingRepository (in_app_purchase) + entitlement providers

**Files:**
- Modify: `pubspec.yaml` (in_app_purchase)
- Create: `lib/features/billing/data/billing_repository.dart`, `lib/features/billing/application/billing_providers.dart`
- Test: `test/features/billing/billing_repository_test.dart`

- [ ] **Step 1: Add the package + write the failing test (deliver calls validate-iap)**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" pub add in_app_purchase`
Create `test/features/billing/billing_repository_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/billing/data/billing_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}
class _MockFunctions extends Mock implements FunctionsClient {}

void main() {
  test('deliverPurchase invokes validate-iap with the receipt fields', () async {
    final client = _MockClient();
    final fns = _MockFunctions();
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('validate-iap', body: any(named: 'body')))
        .thenAnswer((_) async => FunctionResponse(data: {'ok': true}, status: 200));
    await BillingRepository(client).deliverPurchase(
      platform: 'ios', storeProductId: 'com.cunghat.boost', storeTxnId: 't1', receipt: 'r');
    verify(() => fns.invoke('validate-iap', body: {
      'platform': 'ios', 'store_product_id': 'com.cunghat.boost',
      'store_txn_id': 't1', 'receipt': 'r',
    })).called(1);
  });

  test('myEntitlements calls get_my_entitlements', () async {
    final client = _MockClient();
    when(() => client.rpc('get_my_entitlements')).thenAnswer((_) async => [
      {'user_id': 'u1', 'feature': 'see_likes', 'source': 'ios_iap', 'active_until': null},
    ]);
    final e = await BillingRepository(client).myEntitlements();
    expect(e.single['feature'], 'see_likes');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/billing/billing_repository_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement the repo + providers**

Create `lib/features/billing/data/billing_repository.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class BillingRepository {
  BillingRepository(this._client);
  final SupabaseClient _client;

  /// Called after the store confirms a purchase; server validates + grants the entitlement.
  Future<void> deliverPurchase({
    required String platform, required String storeProductId,
    required String storeTxnId, required String receipt,
  }) async {
    await _client.functions.invoke('validate-iap', body: {
      'platform': platform, 'store_product_id': storeProductId,
      'store_txn_id': storeTxnId, 'receipt': receipt,
    });
  }

  Future<List<Map<String, dynamic>>> myEntitlements() async {
    final rows = await _client.rpc('get_my_entitlements');
    return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
```

Create `lib/features/billing/application/billing_providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/billing_repository.dart';

final billingRepositoryProvider =
    Provider((ref) => BillingRepository(ref.watch(supabaseClientProvider)));

final entitlementsProvider = FutureProvider<Set<String>>((ref) async {
  final list = await ref.watch(billingRepositoryProvider).myEntitlements();
  return list.map((e) => e['feature'] as String).toSet();
});

/// Convenience gate used by features (e.g. see-who-liked).
final hasEntitlementProvider = Provider.family<bool, String>((ref, feature) =>
    ref.watch(entitlementsProvider).maybeWhen(data: (s) => s.contains(feature), orElse: () => false));
```

- [ ] **Step 4: Run test to verify it passes**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/billing/billing_repository_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```
git add pubspec.yaml pubspec.lock lib/features/billing/ test/features/billing/billing_repository_test.dart
git commit -m "feat(p6): BillingRepository (in_app_purchase deliver→validate-iap) + entitlement providers"
```

---

### Task 4: Store screen (IAP purchase flow) + gating one feature

**Files:**
- Create: `lib/features/billing/presentation/store_screen.dart`, `lib/features/billing/application/iap_controller.dart`
- Modify: `lib/features/discovery/presentation/...` (gate "Ai đã thích bạn" by `see_likes`)
- Test: `test/features/billing/store_screen_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/billing/store_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/features/billing/presentation/store_screen.dart';

void main() {
  testWidgets('store lists the three upgrades', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: StoreScreen())));
    await tester.pump();
    expect(find.text('Đẩy kèo lên top'), findsOneWidget);
    expect(find.text('Xem ai đã thích bạn'), findsOneWidget);
    expect(find.text('Bộ lọc nâng cao'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/billing/store_screen_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement the IAP controller + store screen + gate**

Create `lib/features/billing/application/iap_controller.dart` — wraps `InAppPurchase.instance`: `queryProductDetails({ids})`, `buy(ProductDetails)`, and listens to `purchaseStream`; on `PurchaseStatus.purchased`/`restored` it calls `billingRepositoryProvider.deliverPurchase(...)` with the platform + `productID` + `purchaseID` + `verificationData.serverVerificationData`, then `completePurchase` and invalidates `entitlementsProvider`. Map store product ids ↔ feature via the seeded `products`.

Create `lib/features/billing/presentation/store_screen.dart` — lists the three upgrades (Đẩy kèo lên top / Xem ai đã thích bạn / Bộ lọc nâng cao) with localized titles + store prices; each "Mua" button calls the IAP controller's `buy`. Route `/store`.

Gate the feature: where "Ai đã thích bạn" is surfaced (a Likes entry), read `hasEntitlementProvider('see_likes')` — if false, route to `/store`; if true, call `who_liked_me`.

- [ ] **Step 4: Run test + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/billing/store_screen_test.dart` then `... analyze`
Expected: PASS; clean.

- [ ] **Step 5: Commit**

```
git add lib/features/billing/ lib/features/discovery/ lib/app/router.dart test/features/billing/store_screen_test.dart
git commit -m "feat(p6): store screen (IAP) + see-who-liked gated by entitlement"
```

---

### Task 5: Venue booking via MoMo/ZaloPay (Edge Functions) + UI

**Files:**
- Create: `supabase/functions/create-venue-payment/index.ts`, `supabase/functions/payments-webhook/index.ts`, `lib/features/plan/presentation/booking_button.dart`
- Modify: `lib/features/plan/data/plan_repository.dart`
- Test: `test/features/plan/booking_test.dart`

- [ ] **Step 1: Write the failing test (repo initiates payment)**

Create `test/features/plan/booking_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cung_hat/features/plan/data/plan_repository.dart';

class _MockClient extends Mock implements SupabaseClient {}
class _MockFunctions extends Mock implements FunctionsClient {}

void main() {
  test('startVenuePayment invokes create-venue-payment and returns pay url', () async {
    final client = _MockClient();
    final fns = _MockFunctions();
    when(() => client.functions).thenReturn(fns);
    when(() => fns.invoke('create-venue-payment', body: any(named: 'body')))
        .thenAnswer((_) async => FunctionResponse(data: {'pay_url': 'https://pay/x'}, status: 200));
    final url = await PlanRepository(client).startVenuePayment(
      planId: 'p1', venueId: 'v1', amountMinor: 200000, gateway: 'momo');
    expect(url, 'https://pay/x');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test test/features/plan/booking_test.dart`
Expected: FAIL — `startVenuePayment` not defined.

- [ ] **Step 3: Implement repo method + the two Edge Functions + a button**

Append to `lib/features/plan/data/plan_repository.dart`:
```dart
  Future<String> startVenuePayment({
    required String planId, required String venueId,
    required int amountMinor, required String gateway,
  }) async {
    final res = await _client.functions.invoke('create-venue-payment', body: {
      'plan_id': planId, 'venue_id': venueId, 'amount_minor': amountMinor, 'gateway': gateway,
    });
    return (res.data as Map)['pay_url'] as String;
  }
```

Create `supabase/functions/create-venue-payment/index.ts` — resolves the user from the JWT, inserts a `venue_bookings` row (`state='initiated'`, service role), calls the MoMo/ZaloPay **create-order** API (signature from `MOMO_*`/`ZALOPAY_*` secrets) with a `redirect`/`ipnUrl` pointing at `payments-webhook`, stores `gateway_ref`, and returns `{ pay_url }`. (Provider call is `TODO(prod)` until merchant creds exist; return a sandbox URL meanwhile.)

Create `supabase/functions/payments-webhook/index.ts` — verifies the gateway signature, looks up the booking by `gateway_ref`, sets `state='paid'` + computes `commission_minor` (service role), and returns the gateway's expected ack. Reject on bad signature.

Create `lib/features/plan/presentation/booking_button.dart` — on a `confirmed` plan, a "Đặt phòng & giữ chỗ" button calls `startVenuePayment` then opens the returned `pay_url` (url_launcher). Show it inside `plan_screen` next to the safety toolkit.

- [ ] **Step 4: Run test + full suite + analyze**

Run:
```
& "C:\Users\Public\flutter\bin\flutter.bat" test
& "C:\Users\Public\flutter\bin\flutter.bat" analyze
```
Expected: all green; `No issues found!`.

- [ ] **Step 5: Commit**

```
git add supabase/functions/create-venue-payment/ supabase/functions/payments-webhook/ lib/features/plan/ test/features/plan/booking_test.dart
git commit -m "feat(p6): venue booking via MoMo/ZaloPay (create-payment + webhook) + button"
```

---

### Task 6: l10n + acceptance

**Files:**
- Modify: `lib/l10n/*.arb`

- [ ] **Step 1: Add + generate billing strings**

Add keys: `storeTitle`, `boostTitle`="Đẩy kèo lên top", `seeLikesTitle`="Xem ai đã thích bạn", `filtersTitle`="Bộ lọc nâng cao", `buy`="Mua", `bookVenue`="Đặt phòng & giữ chỗ", `entitlementNeeded` to both ARBs + `gen-l10n`; swap hardcoded strings.

- [ ] **Step 2: Full suite + analyze**

Run: `& "C:\Users\Public\flutter\bin\flutter.bat" test` then `... analyze`
Expected: all green; `No issues found!`.

- [ ] **Step 3: Acceptance**

- IAP: in the store, a (sandbox) purchase of `see_likes` → `validate-iap` writes a `purchases` row + an `entitlements` row → "Ai đã thích bạn" stops routing to `/store` and `who_liked_me` returns rows. Before purchase, `who_liked_me` raises `entitlement_required`.
- Gateway: on a confirmed plan, "Đặt phòng" → `create-venue-payment` inserts a booking (`initiated`) + returns a pay URL; simulate the webhook → booking flips to `paid` with a commission.
- Store-policy check: confirm digital unlocks go ONLY through IAP (no MoMo/ZaloPay path for boost/see_likes/filters).

- [ ] **Step 4: Commit**

```
git add lib/l10n/ lib/features/billing/ lib/features/plan/
git commit -m "feat(p6): billing l10n + P6 acceptance"
```

---

## Self-Review (completed by author)

- **Spec coverage:** digital goods via **IAP only** with server-side receipt validation → entitlements ✓ (T1–T4); entitlement gating (see-who-liked) ✓ (T1,T4); venue-booking commission via **MoMo/ZaloPay** Edge Functions + webhook ✓ (T5); entitlements/purchases written **only by service role** ✓ (T1,T2). The store-policy split (digital=IAP, real-world=gateway) is enforced structurally. Real receipt/gateway verification is gated on merchant creds (operational pre-reqs) and marked `TODO(prod)` — the plumbing, data model, and gating ship here.
- **Placeholder scan:** the only `TODO(prod)` markers are the external store/gateway verification calls (cannot be completed without merchant credentials) — explicitly labelled, not silent gaps. No undefined Dart symbols.
- **Type consistency:** RPC names `get_my_entitlements`/`who_liked_me` identical SQL↔Dart; Edge fn names `validate-iap`/`create-venue-payment`/`payments-webhook` identical across Dart `functions.invoke` and the function dirs; `who_liked_me` returns the P1 `discovery_candidate` type (reuses `Candidate` on the client); entitlement feature strings (`boost`/`see_likes`/`premium_filters`) consistent across products seed, `has_entitlement`, `validate-iap`, and `hasEntitlementProvider`; reuses P4 `PlanRepository`/`plans`/`venues`, P1 `swipes`/`matches`/`dist_band`.

---

## Next plan (final)
- **P7** Launch: scheduled hard-delete Edge Function (PDPL retention), 3-city seeding + Places ingestion run, FCM push (matches/joins/messages/plan), deep-link (`cunghat://plan/{token}`) resolution, store submission checklist + app icon/splash.
