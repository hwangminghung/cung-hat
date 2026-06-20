# Cùng Hát — Design Spec (v1 MVP)

> Status: **DRAFT for review** · Date: 2026-06-20 · Working name: **Cùng Hát** (confirm before launch)
> Approach: **C "Cùng Hát"** — two co-equal tabs (Đôi = 1-1 swipe, Kèo = group outing board) sharing one core.
> This spec is the source of truth for the build. It is a **fresh greenfield** project (new frontend AND backend); it reuses the *wisdom* of a mature predecessor app, not its code.

---

## 0. Tóm tắt điều hành (Vietnamese)

App mobile (Flutter, iOS + Android) cho thị trường **Việt Nam** giúp người lạ **ghép theo gu nhạc** để **gặp offline đi hát** ở karaoke / music box. Hai chế độ ngang hàng ngay từ v1:

- **Tab Đôi**: vuốt thẻ 1-1 kiểu Tinder → match → chat → rủ đi hát.
- **Tab Kèo**: bảng các "kèo đi hát" (2-5 người); tạo kèo hoặc **"Xin vào kèo" → host duyệt → cả nhóm xác nhận** → group chat → chốt quán.

Nguyên tắc cốt lõi: **riêng tư geo** (toạ độ thật chỉ ở server, client chỉ thấy *dải khoảng cách*), **an toàn khi gặp người lạ** (duyệt + xác nhận, check-in, chia sẻ kế hoạch, block/report), **tuân thủ luật VN** (NĐ147 mạng xã hội, NĐ13/PDPL bảo vệ dữ liệu). **Monetization bật ngay v1**. Ra mắt **3 thành phố cùng lúc**: Hà Nội, TP.HCM, Thái Nguyên.

---

## 1. Product concept, goals & non-goals

**Concept.** A music-meetup app: strangers in the same city are matched by music taste (genres + artists + "bài tủ" / signature songs) to go sing together offline — either 1-1 or in a small group ("kèo", 2-5 people). "Tinder-like" refers to the **swipe UI/UX style** of the Đôi tab, not the dating product model. Positioned as **kết bạn qua âm nhạc / đi hát**, explicitly NOT dating, NOT online karaoke/livestream/voice-scoring.

**Goals (v1).**
1. Two co-equal discovery surfaces (Đôi swipe, Kèo board) on one identity/taste/matching/chat/safety core.
2. Get strangers safely from "match/join" → "confirmed plan at a venue" → "they actually meet and sing".
3. Privacy- and safety-first by construction; VN-compliant from the schema up.
4. Monetization live in v1 (store-compliant for digital goods; local gateways for real-world services).

**Non-goals (v1).**
- Online/remote karaoke, livestream, WebRTC, voice/pitch scoring.
- Group-on-group swipe matching and "recruit individuals into my group" swipe decks (fast-follow).
- Selfie/liveness biometric verification (fast-follow).
- Apple/Google social sign-in (phone + email only in v1).

---

## 2. Locked decisions (do not re-litigate)

| # | Decision |
|---|---|
| L1 | Fresh greenfield build — new frontend **and** new backend. |
| L2 | Stack: **Flutter** (iOS + Android; web for dev only) + **Supabase** (Postgres + PostGIS + Auth + Realtime + Storage + Edge Functions). Riverpod 3 DI/state, go_router, freezed, Material 3. |
| L3 | **Both** 1-1 swipe (Đôi) **and** group Kèo present from v1, as co-equal tabs. |
| L4 | Kèo joining uses **request → host-approve → all-members-confirm** (board model). Group-on-group swipe deferred. |
| L5 | Music taste captured **manually**: genres + artists + **bài tủ from a curated song list**. No streaming integration. |
| L6 | Profile photos **optional** in v1. |
| L7 | Safety defaults: **all-members-confirm before group chat opens**; verification = **phone OTP only** (biometric deferred). |
| L8 | Data region: **Supabase Singapore** (ap-southeast-1); declared as a PDPL cross-border transfer. |
| L9 | **Monetization ON in v1** (see §11). Digital goods via store IAP; real-world services via MoMo/ZaloPay. |
| L10 | Launch **Hà Nội + TP.HCM + Thái Nguyên simultaneously**; each city must be seeded with kèo + venues. |
| L11 | Market = Vietnam; localized **VI (default) + EN**. |

---

## 3. Target users & launch

- **Who:** 18+ adults in HN / HCM / Thái Nguyên who like singing karaoke and want company (new friends or a 1-1 buddy) sharing their music taste. Strong student/young-professional skew (esp. Thái Nguyên university population).
- **Launch model:** 3 cities at once (per L10). **Cold-start is the #1 risk** (see §14). Mitigation is structural: the Kèo tab leads with a **board that can be pre-seeded** with curated/host-created outings so HOME feels alive even when the swipe deck is thin; seed a concentrated set of venues + initial kèo per city; recruit a small founding cohort per city before public push.
- **Operational pre-req:** a person/partner able to seed real kèo + venues in **each** of the 3 cities at launch.

---

## 4. Architecture

### 4.1 Client (Flutter)
- Material 3, clean "Korean-style-box" visual identity (apply taste principles: anti-slop typography/spacing, restrained palette, motivated motion). EN/VI via Flutter l10n (ARB).
- **Riverpod 3** for DI/state (no get_it); **go_router**; **freezed** for all models — required because Riverpod 3 filters stream events by `==`, so models must be value-equal.
- Layering (feature-first): `Supabase client → Repository → AsyncNotifier/StreamNotifier providers → UI`. Folders: `lib/{app, core/{config,providers,analytics,push}, l10n, features/*}`; each feature `domain/ data/ application/ presentation/`.
- Realtime channels live in **keepAlive** notifiers with explicit subscribe/unsubscribe + presence `track`/`untrack` in `dispose` (Riverpod 3 auto-pauses unlistened StreamProviders, so off-screen chat/presence must be managed deliberately).
- Swipe deck: `flutter_card_swiper` (logic only) wrapped in custom M3 card widgets.
- Config via `--dart-define-from-file` (never `flutter_dotenv`); secrets never in client.

### 4.2 Backend (Supabase)
- Postgres + **PostGIS** (`geography(POINT,4326)` + GIST index).
- Auth: **phone OTP (+84)** via a custom **Send-SMS Auth Hook** abstraction (so a cheap local VN SMS provider can replace the default); email secondary; hard 18+ gate.
- Realtime: **Broadcast-from-Database** (NOT Postgres Changes) for chat fan-out.
- Storage: **private** per-user photo bucket `{uid}/`.
- Edge Functions: hold all secrets (service_role, SMS, FCM, payment, Places), do rate limiting, push, signed-URL minting, payment receipt validation, moderation actions.

### 4.3 Data-flow contracts (non-negotiable)
1. **All cross-user reads go through hardened `SECURITY DEFINER` RPCs**: `set search_path=''`, fully-qualified names, defined in a **private non-API schema**, `REVOKE EXECUTE FROM anon, public` + `GRANT EXECUTE TO authenticated`, and a **narrow sanitized return type** that *is* the privacy boundary — never `SELECT *` of base tables, never lat/long, never raw `ST_Distance` floats.
2. **Chat fan-out via Broadcast-from-Database**: `AFTER INSERT` `SECURITY DEFINER` trigger on `messages` calls `realtime.broadcast_changes` on a **private** topic `match:{id}` / `keo:{id}`. Clients subscribe to **private channels only**, gated by RLS on `realtime.messages` that joins the topic id back to membership tables (`matches`, `keo_members`). Topic naming is a **security artifact**, written and tested in the same migration as the membership tables.
3. **Secrets live ONLY in Edge Function env.** Edge Functions mint short-lived signed URLs for others' photos, enforce atomic-counter rate limits (swipes/messages/reports/OTP), send FCM, validate IAP receipts, and run the 24h/48h takedown actions.
4. **RLS on every table.** Base tables are self-or-participant scoped; everything cross-user flows through the RPC layer above.

---

## 5. Information architecture & screens

**Bottom-nav (4 co-equal tabs):** `Đôi` (1-1 swipe) · `Kèo` (group board) · `Chat` · `Hồ sơ`. Hard IA separation prevents mode/intent confusion (Bumble-BFF lesson).

| Screen | Purpose |
|---|---|
| Onboarding stepper | +84 phone OTP → 18+ DOB gate → granular PDPL consent (location/photos/matching/marketing/cross-border) → location prime; VI default / EN toggle; progress indicator |
| Music-taste picker | Gamified <90s: genre chips → curated VN/K-pop/US-UK artist grid → 1-3 **bài tủ** from curated list; doubles as profile content + matching signal |
| Đôi swipe deck (HERO 1-1) | Person card deck: right "Muốn hát cùng", up "Siêu kèo", left pass; thumb buttons mirror gestures; card shows bucketed distance band, shared genres/bài tủ icebreaker, verified badge, active-today; **no-photo profiles render a monogram + taste** so optional photos never break the card |
| Kèo board (HERO group) | List+map of open outings near you; filters area/time/genre; FAB "Tạo kèo"; seeded outings fight cold-start |
| Create Kèo sheet | Area (bucketed, never exact home), time window, vibe/intent tag, size 2-5, genres/bài tủ |
| Kèo detail / roster | Members + per-member verified status + overlapping bài tủ + bucketed distance + slots-left; "Xin vào kèo" request / host approve-decline; inline leave + report |
| Match celebration | Shared 1-1/group component: overlapping bài tủ + music-note/mic confetti; CTA "Rủ đi hát" |
| Chat hub + thread | Unified 1-1 + group threads (Realtime), unread badges, duet-song icebreaker chip, inline block/report + outbound message-safety; "Lập kèo" promotion from a 1-1 thread |
| Plan-a-venue | Server-computed midpoint K-style venue suggestions; all-members RSVP/confirm gate; opens plan/group chat only when all confirm |
| Safety center / share-plan | Share-plan-with-friend link (venue+time+photo), "Tôi đã tới" per-member check-in, block/report, hidden-words filter |
| Profile + edit | Real name, optional photos (private bucket signed URLs), bài tủ/taste as social proof, verified badge, intent label |
| Store / upgrade | Monetization surface: boost kèo, see-who-liked, premium filters — via store IAP (§11) |
| Settings + consent | View/withdraw consent, data export, account+data hard-delete (PDPL), photo-moderation toggle, language, Privacy/ToS |
| Moderation console (internal web) | Reports queue, 24h/48h hide/soft-delete/remove, tombstone handling, audit log (NĐ147) |

---

## 6. Data model (Supabase / Postgres)

Tables grouped by domain. Every table has RLS; cross-user exposure is via the RPC layer (§4.3).

**Identity & taste**
- `profiles` — id (=auth.uid PK), display_name, full_name, dob, age_verified, phone_verified, verified_badge, bio, intent enum[music,friends,either], language, trust_score, no_show_count, report_risk, last_active, soft_deleted_at, tombstone. *RLS: self r/w; others via sanitized RPC only.*
- `user_locations` — user_id PK, location `geography(POINT,4326)` (GIST, **server-only**), geohash_grid (~100m snap), area_label, updated_at. *RLS: NO client SELECT of raw coords ever.*
- `music_genres`, `music_artists`, `songs` — seeded reference taxonomy (VN/K-pop/US-UK) + curated karaoke song list. *RLS: public read.*
- `user_genres`, `user_artists`, `user_baitu` — user taste graph; `user_baitu` references `songs.id` (curated). *RLS: self r/w; others' taste via RPC overlap summary.*
- `consents` — user_id, purpose enum[location,photos,matching,marketing,cross_border], granted, granted_at, withdrawn_at, policy_version. *RLS: self r/w.*

**1-1 matching**
- `swipes` — swiper_id, target_type enum[user,keo], target_id, direction enum[like,pass,super,save], created_at, UNIQUE(swiper,target). *RLS: insert via rate-limited `record_swipe` RPC only.*
- `matches` — id, user_a, user_b, status enum[pending,active,unmatched], converted_keo_id (nullable FK), created_at, unmatched_at. *RLS: the two participants only.*
- `match_confirmations` — match_id, user_id, rsvp, confirmed_at. *RLS: participants only.*

**Group Kèo**
- `keo` — id, host_id, title, area_label, area_geo `geography(POINT)` (bucketed, server-only), time_window_start/end, group_size_target (2-5), intent_tag, vibe, status enum[open,full,planning,confirmed,done,cancelled], genres[], created_at, soft_deleted_at, tombstone. *RLS: board cards via sanitized RPC (bucketed distance only); host writes own.*
- `keo_members` — keo_id, user_id, role enum[host,member], join_status enum[requested,approved,declined,left], confirmed_plan bool, arrived_at, joined_at. *RLS: members read own roster; host manages approvals; drives `realtime.messages` topic policy.*
- `keo_plan_confirmations` — keo_id/plan_id, user_id, rsvp, confirmed_at. *RLS: participants only.*

**Chat**
- `messages` — id, thread_type enum[match,keo], thread_id, sender_id, body, created_at, hidden, soft_deleted_at, tombstone. *RLS: participants r/insert; AFTER INSERT SECURITY DEFINER trigger → `realtime.broadcast_changes` on private topic.*
- `message_reads` — thread_type, thread_id, user_id, last_read_at. *RLS: self only.*

**Meet-up**
- `venues` — id, name, address, location `geography(POINT)` (public business, exposable), style_tag enum[k_style,family,bar_karaoke], photos[], source enum[seed,places], places_id, is_active, city. *RLS: public read.*
- `plans` — id, keo_id|match_id, venue_id (midpoint result), midpoint_geo (server-computed), scheduled_at, status, all_confirmed. *RLS: participants only.*
- `checkins` — plan_id, user_id, arrived_at. *RLS: participants only.*
- `share_plans` — id, plan_id, user_id, share_token, expires_at. *RLS: owner creates; token resolved server-side.*

**Safety & moderation**
- `blocks` — blocker_id, blocked_id, created_at. *RLS: self r/w; enforced inside matching RPCs.*
- `reports` — id, reporter_id, target_type enum[profile,keo,message,photo], target_id, reason, status enum[open,actioned,dismissed], created_at. *RLS: reporter writes; moderation role reads.*
- `moderation_audit` — id, actor, action enum[hide,remove,restore], target_type, target_id, reason, created_at. *RLS: moderation role only.*

**Monetization (§11)**
- `products` — id, sku, type enum[boost,see_likes,premium_filters,verified_priority], platform enum[ios,android], store_product_id, price_minor, is_active. *RLS: public read.*
- `purchases` — id, user_id, product_id, platform enum[ios,android], store_txn_id, receipt_ref, state enum[pending,validated,refunded], created_at. *RLS: self read; write only by Edge Function (service role) after receipt validation.*
- `entitlements` — user_id, feature, source enum[ios_iap,play_billing,promo], active_until, created_at. *RLS: self read; write by Edge Function only.*
- `venue_bookings` — id, plan_id, venue_id, user_id, amount_minor, gateway enum[momo,zalopay], gateway_ref, commission_minor, state enum[initiated,paid,failed,refunded], created_at. *RLS: participants read; state transitions by Edge Function (gateway webhook) only.*

**Infra**
- `device_tokens` — user_id, fcm_token, platform. *RLS: self write; read only by service role in Edge Functions.*
- `ranking_weights` — key, weight, updated_at. *RLS: no client access; read inside scoring RPCs.*
- `rate_limits` — keyed counters for swipes/messages/reports/OTP (atomic). *RLS: no client access.*

---

## 7. Core flows

### 7.1 Đôi — 1-1 swipe → sing
1. Open Đôi → server runs PostGIS `ST_DWithin` prefilter + in-SQL weighted scoring (music overlap + nearness-bucket + intent/activity freshness − trust/report-risk), returns **sanitized** person cards via hardened RPC (no coords/weights).
2. Swipe right "Muốn hát cùng" (or up "Siêu kèo") → write via rate-limited `record_swipe` RPC; blocked/already-swiped/soft-deleted excluded.
3. Mutual right → `matches` row created **race-safely** → full-screen "Chung gu!" celebration showing overlapping bài tủ.
4. Enter 1-1 Realtime chat (Broadcast-from-DB private topic `match:{id}`); inbound+outbound hidden-words filter; block/report inline.
5. Optional "Lập kèo / Rủ thêm người" converts the 1-1 into a forming Kèo (`converted_keo_id`).
6. Propose midpoint K-style venue from seeded cache → both confirm → safety wrap (share-plan link + "Tôi đã tới" check-in) → meet & sing.

### 7.2 Kèo — board-first group outing
1. Open Kèo → board/map of open outings via sanitized board RPC (bucketed distance only); seeded/host outings keep it populated.
2. Either **create** a Kèo (area-bucketed, time window, vibe/intent, size 2-5, genres/bài tủ) → live on board; or open a Kèo card → roster (avatars + per-member verified status + overlapping bài tủ + slots-left).
3. "Xin vào kèo" request → host sees requester's sanitized card + verification + trust → approve/decline.
4. **All current members confirm** → group chat opens (private topic `keo:{id}`, gated by RLS on `realtime.messages` joined to `keo_members`).
5. Host proposes venue = server-computed midpoint of members → seeded K-style venue → all RSVP/confirm → plan locks.
6. Each member: share-plan-with-friend link + per-member "Tôi đã tới" check-in → group meets & sings; report/leave available inside the Kèo.

---

## 8. Matching algorithm

Two-stage, fully server-side, exposed only via hardened `SECURITY DEFINER` RPC.
- **Stage 1 (PostGIS prefilter):** `ST_DWithin(location, caller_point, radius)` on GIST index + KNN `<->` ordering; exclude banned/blocked/already-swiped/soft-deleted.
- **Stage 2 (in-SQL weighted sum, no ML):** `score = w1·music_overlap (genre∩ + artist∩ + bài tủ∩) + w2·nearness (from the BUCKETED band, not raw meters) + w3·activity/intent freshness − w4·trust/report-risk`. Weights from `ranking_weights`.
- **Return per card:** display_name, first photo *path* (signed URL minted separately), bucketed distance band (`<1 / 1-3 / 3-5 / 5+ km`), shared genres + overlapping bài tủ, verified badge, active-today.
- **Person vs Kèo share the engine:** a Kèo card aggregates its member set (UNION of genres/bài tủ for overlap; member centroid for the prefilter + bucketed distance; slots-left + per-member verified in the payload).

---

## 9. Realtime & chat

- **Broadcast-from-Database on PRIVATE channels only.** Never Postgres Changes (re-runs RLS per subscriber; permissive `realtime.messages` policies leak topics).
- Topic naming `match:{id}` / `keo:{id}` is gated by RLS on `realtime.messages` joined to membership tables.
- Typing indicator via ephemeral Broadcast; presence for online-only display.
- Off-screen channels managed deliberately (keepAlive notifiers; unsubscribe + untrack on dispose).

---

## 10. Safety & privacy

- **Geo privacy:** exact coords server-only in PostGIS; snapped to ~100m grid at write (k-anonymity); clients receive only bucketed bands. RPC return types reviewed as the privacy boundary.
- **Stranger-meeting safety:** request→host-approve join + all-members-confirm before chat/plan; per-member verified badge visible before confirm; share-plan-with-friend; per-member "I've arrived" check-in; block/report on every surface; inbound+outbound hidden-words filter.
- **Photos:** optional; stored as path in private `{uid}/` bucket; others' photos only via short-lived server-minted signed URLs; image-transform thumbnails for decks.
- **Moderation:** reports queue with 24h (authority) / 48h (user-complaint) takedown SLA; soft-delete + tombstone on all UGC; audit log.
- **Account:** data export + hard-delete (PDPL); granular revocable consent.

---

## 11. Monetization (v1)

Monetization is **on in v1** (per L9). **Critical store-policy constraint:**

| Revenue stream | What | Channel (MANDATORY) |
|---|---|---|
| **Digital goods** | Boost kèo to top of board, "see who liked you", premium filters, verified-priority | **Apple App Store IAP + Google Play Billing** — required by store policy for in-app digital unlocks; ~15-30% fee. **MoMo/ZaloPay are NOT allowed** for these on mobile. |
| **Real-world service** | Venue booking + commission | **MoMo / ZaloPay** (real-world service, outside store IAP rules) via Edge Function + gateway webhook |

- Entitlements granted **only** after server-side receipt validation (Edge Function) → `purchases` + `entitlements`.
- Core matching + kèo-joining + chat stay **free**; paid features are accelerators/extras only.
- Compliance add-ons (because money is involved from day one): e-invoice (VAT), refund policy, consumer-protection notices, e-commerce decree obligations. Tracked in §15.

---

## 12. Compliance (Vietnam)

- **Decree 147/2024 (social network):** registration/licensing for a social-networking service; real-name (full_name + DOB) + 18+ gate; content moderation duties + 24h/48h takedown SLA + tombstone/audit. Start the VN entity + license paperwork early; run a **capped closed beta** to stay under thresholds until licensed.
- **Decree 13/2023 (PDPL):** granular timestamped revocable consent; data subject rights (export/delete); **cross-border transfer** — Supabase Singapore must be named by country in the VI privacy notice, backed by a **Transfer Impact Assessment** dossier; observe data-residency expectations.
- **Payments:** use **licensed gateways** (MoMo/ZaloPay) for real-world services; e-invoice/VAT; consumer-protection + refund terms.
- **Content:** Privacy Policy + ToS surfaced at signup and in settings (VI primary).

---

## 13. MVP scope

**Included (v1):** onboarding (OTP + 18+ + consent), gamified taste picker (curated bài tủ), Đôi swipe deck, Kèo board + create + request-to-join + host approve + all-confirm, match celebration, 1-1 + group Realtime chat, plan-a-venue (geometric-median midpoint music-box picker — seeded cache **+ Google Places (New) ingestion**), in-flow safety toolkit, geo privacy-by-bucketing, optional private photos, two-stage matching RPCs, moderation console + soft-delete/tombstone/audit, consent + export + delete, server-side rate limits, FCM push, **monetization (IAP digital goods + MoMo/ZaloPay venue commission)**, 3-city seeding.

**Deferred (fast-follow):** group-on-group swipe match deck + recruit-into-group deck; selfie/liveness biometric; Apple/Google sign-in; full no-show reputation/rating UI (scaffold `trust_score`/`no_show_count` only); availability scheduling beyond kèo time-window; events calendar.

---

## 14. Risks & mitigations

| Risk | Mitigation |
|---|---|
| **Cold-start ×3 cities** (both surfaces in 3 cities must feel alive) | Board pre-seeded with curated/host kèo; concentrated seeded venues per city; founding cohort per city; board (not deck) leads Kèo so HOME isn't empty. **Highest residual risk given 3-city simultaneous launch.** |
| Mode/intent confusion | Hard IA tab separation; Kèo uses request-to-join (not swipe) in v1; ruthless VI/EN intent labels. |
| Offline-stranger safety incident | Request→approve + all-confirm before chat/plan; verified badge before confirm; share-plan + check-in; block/report; no coord exposure. |
| SECURITY DEFINER footgun (silent full-table leak) | `search_path=''`, private schema, REVOKE from anon/public, narrow sanitized return; bucketing in RPC not client; reviewed as privacy boundary. |
| Coordinate/trilateration leak | Exact geo server-only; ~100m snap; RPCs return bands only, never lat/long or raw distance floats. |
| Chat scale/leak | Broadcast-from-DB on private channels; topic RLS joined to membership; written+tested with membership migration. |
| VN licensing + PDPL cross-border gates | Compliance schema from v1; capped beta; entity/license + TIA started early; region disclosed. |
| SMS OTP cost + SMS-pumping | Phone auth behind Send-SMS Auth Hook (swap cheap VN provider); OTP rate-limit in Edge Function. |
| Store-policy violation on payments | Digital goods via IAP only; MoMo/ZaloPay strictly for real-world venue service (§11). |
| Riverpod 3 lifecycle (auto-pause, == filtering) | freezed/Equatable models; keepAlive chat/presence notifiers; explicit subscribe/track lifecycle; avoid experimental offline-persistence in v1. |
| Karaoke-ôm brand/trust association | Brand around đi hát / kết bạn qua âm nhạc; curate venues to K-style/family; foreground verified + safety; explicitly not-dating. |

---

## 15. Operational / open items (non-code, tracked)

- VN legal entity + Social Network License (Decree 147) — start now; define capped-beta size.
- PDPL cross-border Transfer Impact Assessment dossier; VI Privacy Policy + ToS.
- Pick local VN SMS provider behind the Send-SMS Auth Hook (account + budget).
- Apple Developer + Google Play accounts; IAP product setup; MoMo/ZaloPay merchant onboarding; e-invoice/VAT.
- **Google Maps Platform billing + Places API (New) key** (Edge env `GOOGLE_PLACES_API_KEY`) for venue ingestion in the 3 cities (now in v1, P4 Task 6).
- Per-city seeding plan (kèo + venues + founding cohort) for HN / HCM / Thái Nguyên.
- Confirm final app name/brand (working name "Cùng Hát").

---

## 16. Testing strategy

- Unit/widget tests per feature (Riverpod providers, repositories with mocked Supabase client pinning RPC names + param keys vs migrations).
- Backend smoke: live-RPC checks over seeded accounts (deny-checks that client roles cannot call system/privileged RPCs; bucketing never returns coords).
- Realtime: topic-RLS tests that a non-member cannot subscribe to `match:{id}`/`keo:{id}`.
- Privacy assertions: RPC return shapes contain no lat/long; distance only as bands.
- Payments: IAP receipt-validation Edge Function tests; gateway webhook state-machine tests.

---

## 17. Milestones (suggested phasing within v1)

1. **P0 Foundation:** Flutter scaffold, Supabase project (Singapore), auth (OTP + 18+ + consent), profiles, taste picker (seeded genres/artists/songs), RLS + RPC scaffolding, CI/tests.
2. **P1 Đôi:** PostGIS + matching RPCs, swipe deck, race-safe match, celebration, blocks/reports.
3. **P2 Chat:** Broadcast-from-DB 1-1 chat, unread, message-safety, presence.
4. **P3 Kèo:** board + create + request/approve + all-confirm + group chat.
5. **P4 Meet-up:** venues seed, midpoint plan, confirm, safety toolkit (share-plan, check-in).
6. **P5 Compliance + Moderation:** consent mgmt, export/delete, moderation console, audit/tombstone.
7. **P6 Monetization:** IAP digital goods, MoMo/ZaloPay venue commission, entitlements.
8. **P7 Launch prep:** per-city seeding, FCM push, analytics, store submission.

---

*End of spec. Pending: user review (then writing-plans for the implementation plan).*
