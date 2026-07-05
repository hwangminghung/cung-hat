# Design: Đợt Tinder-parity cho tab Đôi (+ P1 hồ sơ/khám phá)

> Nguồn: backlog `2026-07-06-tinder-parity-backlog.md` + 6 quyết định user chốt ngày 2026-07-06.
> Nhánh `feat/tinder-parity` (từ `feat/pro-keo-gating` @ 0d605939), làm trong worktree
> `C:\Users\Hwang Ming Hung\cung-hat-photos-wt` — KHÔNG đụng checkout gốc (master, Codex agents).

## Quyết định user đã chốt (2026-07-06)

| # | Câu hỏi | Quyết định |
|---|---------|-----------|
| 1 | Mục 13 interleave card Kèo vào deck Đôi | **LÀM đầy đủ** (không hoãn) |
| 2 | Swipe-semantics card Kèo | **Vuốt phải = mở KeoDetailScreen, vuốt trái = bỏ qua**; không quota, không rewind |
| 3 | Giá trong paywall ngữ cảnh | **Không hiện số giá trong sheet** — CTA sang `/store` (né conflict nhánh `codex/pro-pricing-keo-boost` đang xây pricing catalog) |
| 4 | Mở rộng bán kính | **Toggle lưu server** (kiểu Tinder) + nút one-shot ở màn hết deck |
| 5 | Scope P1 | **Lấy CẢ 4 mục: 4, 5, 6, 7** (user chọn hết dù được cảnh báo đợt nặng) |
| 6 | Kèm mục 12 (OTP tràn 10px) | Có |

## Scope & thứ tự task (9 task, giá trị cao + nền tảng ra trước)

| Task | Mục backlog | Tên | Cỡ |
|------|-------------|-----|----|
| T1 | 1 (P0) | Paywall theo ngữ cảnh (variants, không giá) | M |
| T2 | 2 (P0) | Mở rộng bán kính khi hết deck (server toggle + clamp) | M |
| T3 | 3 (P0) | Card UX pack: tap-đổi-ảnh + action bar sync + chip xoay | M-L |
| T4 | 13 | Interleave card Kèo vào deck Đôi | L |
| T5 | 12 (P2) | Fix ô OTP thứ 6 tràn 10px màn hẹp | S |
| T6 | 4 (P1) | Thẻ hỏi-đáp karaoke (prompts) | M-L |
| T7 | 5 (P1) | Thanh hoàn thiện hồ sơ + thưởng định lượng (cần T6) | S-M |
| T8 | 7 (P1) | Pill "Đến lượt bạn" trong inbox | M |
| T9 | 6 (P1) | Deck chủ đề nhạc (mini-Khám Phá) | L |

## Thiết kế từng task

### T1 — Paywall theo ngữ cảnh
- `ProUpsellSheet` nhận `ProUpsellVariant` enum: `boost / rewind / seeLikes / keoCreate / keoJoinLimit / likeQuota / superQuota`. Mỗi variant = icon + headline đúng tính năng + 3 bullet lợi ích + CTA "Nâng cấp Pro" → `/store`.
- **KHÔNG số giá, không đọc bảng `products`, không đụng StoreScreen/validate-iap** — vùng đó thuộc nhánh Codex pricing.
- Migrate mọi call site hiện tại (doi_deck_screen: boost/rewind/quota; keo_board_screen: tạo kèo; keo_detail: dialog `free_join_limit` → hợp nhất về sheet variant `keoJoinLimit`).
- Test: widget test per variant (headline đúng, KHÔNG chứa chuỗi "đ"/giá, CTA push /store).

### T2 — Mở rộng bán kính khi hết deck
- Migration (timestamp mới): bảng `discovery_prefs(user_id pk → profiles, auto_expand bool not null default false, updated_at)`; RPC `set_discovery_auto_expand(bool)` + `get_discovery_prefs()` (SECURITY DEFINER, self-only — theo pattern repo). `get_discovery_candidates` recreate: **clamp `p_radius_km ≤ 100`** (server không tin client).
- Client: `discoveryRadiusProvider` (mặc định 50). Màn hết deck (EmptyState hiện tại) thêm: nút **"Mở rộng tìm quanh 100 km"** (one-shot: radius=100 + refetch) + Switch **"Tự mở rộng khi hết người"** (ghi server). Khi auto_expand=true và fetch 50 km rỗng → tự refetch 100 km, hiện chip "Đang tìm trong 100 km" trên deck.
- Test: pgTAP (prefs self-only, clamp), widget test empty-state + auto-expand flow.

### T3 — Card UX pack (3 việc, 1 task)
- (a) **Tap nửa trái/phải card = ảnh trước/sau** (card-mode PhotoCarousel thêm controller/tap zones, giữ dots). Mở detail dời từ `onTap` card (doi_deck_screen:167) sang **nút ⓘ riêng** trên card.
- (b) **Action bar sync tiến độ kéo**: `cardBuilder` đã chạy mỗi frame và có `hProgress/vProgress` (-1..1, đang cấp cho `SwipeOverlays`) → đẩy thêm vào `ValueNotifier<(double,double)>`; `DeckActionBar` bọc `ValueListenableBuilder`, nút tương ứng scale ~1.15 + đổi màu đậm dần theo |progress|. Giữ kỷ luật perf như SwipeOverlays (static content, RepaintBoundary).
- (c) **Chip info xoay theo ảnh**: composite `discovery_candidate` thêm `bio` (recreate type + `get_discovery_candidates`). Quy tắc: ảnh 1 = distance_band + "cùng N bài tủ"; ảnh 2 = shared_genres; ảnh 3+ = bio (1-2 dòng). Hồ sơ <2 ảnh → chip gộp như hiện tại.
- Test: widget tests tap zones/chip rotation; pgTAP field bio.

### T4 — Interleave card Kèo vào deck Đôi
- Deck model hoá: `sealed class DeckItem` = `CandidateItem` | `KeoPromoItem`. Inject **1 card Kèo sau mỗi 5 candidate, tối đa 2/batch**, chỉ khi có kèo hợp lệ.
- Nguồn: `list_open_keos` — extend composite `keo_card` thêm **`is_mine boolean`** (host HOẶC member requested/approved) để loại kèo của mình; board hiện tại không đổi hành vi.
- `KeoPromoCard`: title, "x/y chỗ", khung giờ, distance band, #genres, badge join_mode — theo visual KeoCard nhưng khổ deck-card.
- Gesture: vuốt phải → `context.push('/keo/:id')`, card consumed; vuốt trái → dismiss. **Không tính quota, không `record_swipe`, không vào undo-stack** (rewind chỉ khôi phục candidate thật). Overlay nhãn `XEM KÈO`/`BỎ QUA`; vuốt dọc (siêu thích) bị vô hiệu trên promo card (khoá direction per-card nếu CardSwiper 7.2 cho phép, không thì xử như dismiss + không hiện stamp SIÊU THÍCH — pin khi viết plan sau khi đọc API).
- Test: pgTAP is_mine; widget/unit tests injection cadence, gesture semantics, rewind bỏ qua promo.

### T5 — Fix OTP tràn 10px
- `OtpInput` 6 ô: bỏ width cố định → `Flexible`/`LayoutBuilder` co theo màn. Widget test surface hẹp (~360dp) assert không overflow.

### T6 — Thẻ hỏi-đáp karaoke
- Catalog 6 câu VI cố định client-side (`karaoke_prompts.dart`, id ổn định `p1..p6`; vd "Bài mình luôn giành mic là…", "Thể loại hát khi buồn…", "Đi hát mình là kiểu người…").
- Migration: `profile_prompts(user_id, prompt_id text, answer text check char_length ≤120, position int, pk(user_id, prompt_id))` + RPC `set_my_prompts(jsonb)` (replace-all, max 3) + extend `my_profile` composite/`get_my_profile` + `discovery_candidate` thêm `prompts jsonb` (recreate — KẾ THỪA bản T3 đã thêm bio).
- UI: Hồ sơ tab thêm tile "Thẻ hỏi-đáp" → sheet chọn câu + nhập trả lời; `CandidateDetailSheet` render prompt cards sau phần chips. **Onboarding KHÔNG đụng** (giảm rủi ro, thêm sau).
- Test: pgTAP (≤3, ≤120 ký tự, replace-all); widget tests editor + detail render.

### T7 — Thanh hoàn thiện hồ sơ (sau T6)
- Thuần client: util `profileCompletion(MyProfile)` → (percent, next-rewards). Trọng số: ảnh ≥1 = 20, ảnh ≥3 = +10, bio = 15, genres ≥3 = 15, artists ≥1 = 10, bài tủ ≥3 = 15, prompts ≥2 = 15 (tổng 100).
- Hồ sơ tab: progress bar % + tối đa 2 dòng thưởng kế tiếp copy tĩnh ("Thêm 2 ảnh → x2 lượt được thấy", "Thêm 3 bài tủ → dễ vào kèo hơn").
- Test: unit table-driven cho công thức; widget test hiển thị.

### T8 — Pill "Đến lượt bạn" (inbox)
- Migration: `match_summary` composite + `get_my_matches` thêm `last_sender_id uuid` (null nếu chưa có tin) — recreate theo pattern.
- Inbox: pill amber "Đến lượt bạn" khi tin cuối từ đối phương; "Nhắn trước đi" khi match chưa có tin nào.
- **Phần Kèo-chờ-confirm: DEFER** — kèo status `full` không còn trên board (`list_open_keos` chỉ open) nên cần surface "Kèo của tôi" mới = scope riêng đợt sau. Ghi nhận gap này vào backlog khi xong đợt.
- Test: pgTAP last_sender_id; widget test 3 trạng thái pill.

### T9 — Deck chủ đề nhạc (mini-Khám Phá)
- Mapping tĩnh client theme→genre_id (verify id thật trong seed `music_genres`): Đêm Ballad→ballad, Hội Rap→rap, Bolero chill→bolero, K-Pop→kpop.
- Server: `get_discovery_candidates` thêm `p_genre text default null` (filter candidate có genre đó — recreate KẾ THỪA bản T6) + RPC mới `get_theme_deck_counts(p_genres text[])` → (genre_id, live_count) đếm user `active_today` trong bán kính có genre.
- UI: nút "Khám phá" trên header tab Đôi → `ThemeDeckBoardScreen` (grid card chủ đề + "N người đang hát") → tap → deck screen với genre filter (providers family-hoá theo genre). Quota/swipe/record_swipe y nguyên deck thường.
- Test: pgTAP filter + counts; widget tests board + deck có filter.

## ⚠️ Chuỗi recreate `get_discovery_candidates` (điều phối bắt buộc)

4 task đụng cùng function theo thứ tự: **T2 (clamp) → T3 (bio) → T6 (prompts) → T9 (p_genre)**. Mỗi migration sau PHẢI chép từ bản mới nhất trong repo tại thời điểm viết (không chép từ 20260704110000_boost.sql gốc). Task order trong plan cố định để tránh xung đột. `keo_card` chỉ T4 đụng.

## Ràng buộc thực thi

- Worktree `cung-hat-photos-wt`, nhánh `feat/tinder-parity`. TUYỆT ĐỐI không đổi branch/sửa file ở `C:\Users\Hwang Ming Hung\cung-hat` (master — Codex agents chạy song song).
- Không đụng: StoreScreen/validate-iap/products/pricing (nhánh Codex), `supabase/tests/chat_media_test.sql.pending` (giữ nguyên tên), onboarding flow (trừ T5 OtpInput là màn auth).
- Gotchas môi trường: theo memory `project-cung-hat` + "Ghi chú thực thi" trong backlog (AF_UNIX flag đã trong gradle.properties; psql qua `docker exec supabase_db_cung-hat`; SQL tiếng Việt qua `docker cp` + `psql -f`; `supabase migration up` KHÔNG `db reset`; OTP test 84900000001-007/123456; device thật qua `adb reverse tcp:54321 tcp:54321` + `env/dev.device.json`; emulator `env/dev.emulator.json`).
- Gates mỗi task: `flutter test` + `flutter analyze` (+ `supabase test db` khi đụng DB) xanh; commit theo task.
- Cuối đợt: final holistic review → verify emulator + điện thoại thật → log `docs/verify-tinder-parity-<date>.md` → DỪNG báo user quyết merge/PR (phối hợp PR #3 đang mở).

## Rủi ro chấp nhận

1. **Đợt nặng (9 task)** — user chọn full scope có chủ đích; thứ tự đã xếp để P0 xong trước nếu phải cắt.
2. Chuỗi 4 recreate cùng function — kiểm soát bằng thứ tự cố định + quy tắc "chép bản mới nhất".
3. CardSwiper 7.2 có thể không khoá direction per-card (T4) — đã có fallback trong design.
4. Khi PR #3 và nhánh Codex pricing merge vào master, `feat/tinder-parity` rebase sau — T1 đã thiết kế để vùng giao nhau ≈ 0.
