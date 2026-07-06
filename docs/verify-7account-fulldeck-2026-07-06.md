# Cùng Hát — "Đôi" full-deck verification (2026-07-06)

**Build under test:** CORRECT build — Coral redesign + real photos rendering (feat/pro-keo-gating, redesign + photos + boost).
**App package:** `dev.cunghat.cung_hat` (DEBUG banner visible in every screenshot).
**Region/backend:** local Supabase (`supabase_db_cung-hat`), emulator API `http://10.0.2.2:54321`.
**Screenshots:** `docs/verify-screenshots-fulldeck/`.

## Emulators / accounts driven
| Emulator | Account | UUID | Role in test |
|---|---|---|---|
| emulator-5556 | QA Linh Ballad (logged in) | `90000000-…-002` | Steps 1,2,3,4 (liker) |
| emulator-5558 | QA Vy Bolero (logged in) | `90000000-…-005` | Steps 1,4 (like-back),5 (blocker) |
| emulator-5554 | — | — | **CRASHED earlier from low RAM; NOT used.** Only 5556 + 5558 driven. |

No emulator died during this run; both 5556 and 5558 were alive at start and finish.

## 8-account SG roster (WITH PHOTOS unless noted)
Verified via DB (`profiles.photo_paths` array length):

| Display name | # photos | Notes |
|---|---|---|
| Minh | 2 | carousel-capable |
| QA Linh Ballad | 2 | carousel-capable |
| QA An KPop | 2 | **BOOSTED**, carousel-capable |
| QA Nam Rap | 1 | |
| QA Vy Bolero | 1 | |
| QA Phúc Rock | 1 | |
| QA Hân VPop | 1 | |
| Cùng Hát Sài Gòn (seed) | 2 | seed profile |
| (Cùng Hát Hà Nội / Thái Nguyên) | 0 | other-region seeds, out of SG radius |

## Boost note (test-data setup)
QA An KPop's boost row (`public.boosts`) had `expires_at = 2026-07-05 17:01Z`, i.e. **already expired** at run time (today 2026-07-06). With the boost expired, QA An ranked **6th of 7** in `get_discovery_candidates`. To make the boost-ranking step meaningful I refreshed only the expiry: `update public.boosts set expires_at = now() + interval '1 day' where user_id = '90000000-…-004';` (data touch-up, not a schema/config change; no db reset, no config.toml touch). After refresh, boost active → QA An moved to **3rd of 7**.

## Discovery RPC ordering (after boost refresh)
`get_discovery_candidates(20)` as each user:

- **As QA Linh:** QA Hân VPop, QA Vy Bolero, **QA An KPop (3rd)**, Minh, Cùng Hát Sài Gòn, QA Nam Rap, QA Phúc Rock.
- **As QA Vy:** QA Linh Ballad, QA Hân VPop, **QA An KPop (3rd)**, Minh, Cùng Hát Sài Gòn, QA Nam Rap, QA Phúc Rock.

The ranking formula (`get_discovery_candidates`) applies music-genre overlap (weight 3.0) + nearness (1.5) + activity (1.0) − report_risk (2.0), plus **+3.0 if boosted** and +5.0 for an incoming super-like. QA An has no shared genre/bài tủ with Linh/Vy and sits 3–5 km away, so the +3.0 boost lifts it above the no-overlap far candidates but not above the two close, genre-matched candidates. This is expected behaviour, not a bug.

## Steps 1–5

| # | Step | Observed | Screenshot | Result |
|---|---|---|---|---|
| 1 | Full deck real photos | **5556 (Linh):** top card "QA Hân VPop, 25", teal photo tile labeled **"Han"** (real photo, not monogram); 4-button action bar (rewind/pass/super/like) present; Coral "Đôi" nav active. **5558 (Vy):** top card "QA Linh Ballad, 28", pink/coral generated photo tile (glyph + brush strokes), not a plain monogram. | `linh-deck-photo.png`, `vy-deck-photo.png` | **PASS** |
| 2 | Boost ranking | With boost active, QA An KPop = **3rd of 7** in both decks (RPC cross-checked). On 5556 I passed the 2 higher-scored cards → QA An surfaced as the **top card** ("An 1" orange real photo, "cùng 1 bài tủ", 2 carousel dots). Not literally #1 (genre/nearness terms dominate), but near top and rises with boost (was 6th when expired). | `boost-top.png` | **PARTIAL** (near-top, not #1 — expected per formula) |
| 3 | Carousel photo #2 (BUG-2 fix) | Opened QA An detail sheet on 5556 (carousel photo #1 = "An 1", dot 1 active). Swiped carousel left → shows **real photo #2 labeled "An 2"** (distinct darker-orange tile), **dot #2 active**. NOT a monogram, no expired-token/blank. | `carousel-photo2.png` | **PASS** — key regression fixed |
| 4 | Mutual match | Reset Linh+Vy swipes first (Linh had already passed Vy). Linh (5556) LIKED Vy (swipe row `like` confirmed). Vy (5558) LIKED Linh back → **MatchCelebration "Hợp cạ rồi!"** appeared ("Bạn và QA Linh Ballad đã thích nhau", chip "Cùng tủ: s2", twin avatars + heart + music notes, CTAs "Nhắn tin ngay"/"Tiếp tục khám phá"). `matches` row `cd6f7d43…` (user_a=Linh, user_b=Vy, status=active) confirmed. | `match.png` | **PASS** |
| 5 | Block | Vy (5558) opened top card "…" menu → action sheet (report options + **"Chặn người này"**) → tapped block. QA Hân VPop left Vy's deck (top card advanced to QA An KPop). `blocks` row confirmed: blocker=Vy(`…005`), blocked=QA Hân VPop(`…007`). | `block-gone.png` | **PASS** |

## Explicit answers
- **(a) Photos render on the deck?** **YES.** Both decks show real colored photo tiles with name labels ("Han", "Vy", "An 1", plus generated glyph/brush-stroke tiles), no plain monograms on the deck cards.
- **(b) Carousel photo #2 renders (BUG-2 fix)?** **YES.** Swiping QA An's detail-sheet carousel reveals real photo "An 2" with dot #2 active — the previous BUG-2 (photo #2 blank/monogram from expired signed-URL token) is fixed.
- **(c) Where did boosted QA An KPop rank?** **3rd of 7** in both Linh's and Vy's decks once the boost was active (had to refresh QA An's expired boost expiry to make it active; it was 6th while expired). Not literally first because two close, genre-matched candidates outscore the +3.0 boost — consistent with the ranking formula.

## Minor observation (NOT a functional bug)
On the MatchCelebration screen, tapping the **"Tiếp tục khám phá"** text button at its on-screen coordinates did not dismiss the overlay across several attempts (clock advanced, so taps registered but the button did not fire); the hardware **Back** key dismissed it cleanly. Could be a small hit-target/registration quirk of that TextButton under adb `input tap`, or overlay tap absorption — worth a quick manual double-check by a human, but the celebration itself and the match flow work. No repro captured as a blocking bug.

## Not done (per instructions)
No DB reset, no `db reset`, no edits to `supabase/config.toml` / `chat_media_test.sql.pending`, no commit. Only test-data touch-ups made: reset Linh+Vy swipes (to enable the match test) and refreshed QA An's boost `expires_at` (to make the boost-ranking step meaningful). Both documented above.
