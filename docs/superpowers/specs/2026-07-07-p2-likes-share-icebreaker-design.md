# Design: Đợt P2 — Teaser likes (blur), Share kèo, Icebreaker sau match, Trần ảnh 6

> Nguồn: backlog `2026-07-06-tinder-parity-backlog.md` mục 8/9/10/11 + 3 quyết định user 2026-07-07.
> Nhánh `feat/p2-likes-share-icebreaker` (từ master @ 3d5909f6), worktree `cung-hat-photos-wt`.
> Checkout gốc `C:\Users\Hwang Ming Hung\cung-hat` vẫn TUYỆT ĐỐI không đụng.

## Quyết định user đã chốt

| # | Câu hỏi | Quyết định |
|---|---------|-----------|
| 1 | Mục 8 icebreaker khi nào | **SAU match** — quote ảnh/bài tủ trong chat (không đổi mô hình chat-chỉ-sau-match) |
| 2 | Mục 9 teaser lộ mức nào | **Ảnh thật blur SERVER-SIDE** (edge function pixelate; ảnh gốc KHÔNG BAO GIỜ xuống client free) |
| 3 | Mục 10 phạm vi share | **Chỉ kèo** (nhân bản hạ tầng share_plans; không share profile — né surface PDPL mới) |
| 4 | Mục 11 | Trần 6 ảnh (đã chốt từ backlog) |

## Thứ tự task (nhỏ → lớn, độc lập)

| Task | Mục | Tên | Cỡ |
|------|-----|-----|----|
| T1 | 11 | Trần ảnh 3→6 | S |
| T2 | 10 | Share kèo (token + resolve + màn shared) | M |
| T3 | 8 | Icebreaker quote trong chat | M |
| T4 | 9 | Teaser "Ai thích bạn" blur server-side | L |
| T5 | — | Final review + verify emulator (2 account cho T3/T4) | — |

## T1 — Trần ảnh 3→6

- KHÔNG có table CHECK — giới hạn nằm trong RPC `set_my_photo_paths` (`> 3` → raise `photo_limit`, 20260704100000_photos.sql:30). Migration mới: recreate RPC với `> 6` (copy verbatim + đổi 1 số + comment). Kiểm tra edge `sign-photo` có cap số path không (nếu có → nới cùng).
- Flutter `PhotoManagerSheet`: 3 ô → grid 6 ô (2 hàng × 3, GridView hoặc Wrap theo layout hiện tại), copy 'Thêm tối đa 6 ảnh vào hồ sơ' (cả tile home_shell). `PhotoCarousel`/chip xoay: KHÔNG đổi (chip rotation đã fallback index ≥2 = bio, dots tự theo N).
- Completion bar: giữ nguyên công thức (ảnh ≥3 vẫn là mốc thưởng — không đổi, YAGNI).
- Test: pgTAP 7 ảnh raise / 6 ảnh sống; widget 6 slots render + thêm ảnh thứ 4-6.

## T2 — Share kèo

- Migration: bảng `share_keos(share_token text pk (32-hex), keo_id uuid fk → keo on delete cascade, created_by uuid, created_at, expires_at timestamptz default now()+interval '7 days')`, RLS: không policy client (đọc qua RPC). RPC `create_keo_share_link(p_keo uuid) returns text` — gate: **host HOẶC thành viên `join_status='approved'`** (KHÔNG dùng `app_private.in_keo` — helper đó đòi status planning+ trong khi ca share chính là kèo đang OPEN tuyển người); token `encode(gen_random_bytes(16),'hex')` (mirror `create_share_link` 0016). RPC `resolve_share_keo(p_token text) returns shared_keo_view` — SECURITY DEFINER, grant **anon**+authenticated (mirror 0023): composite `shared_keo_view(keo_id uuid, title text, area_label text, time_window_start timestamptz, size_target int, slots_filled int, genres text[], host_name text, join_mode text, status text, expired boolean)` — KHÔNG toạ độ. `keo_id` được phép lộ (uuid, mọi đọc/ghi thật đều RPC-gated) để user đã đăng nhập điều hướng vào detail.
- Flutter: nút share (icon `ios_share`/`share_rounded`) trên AppBar `KeoDetailScreen` (chỉ hiện khi mình là member/host — dùng data roster sẵn có) → `createKeoShareLink` → `SharePlus.share` text: `'Kèo "<title>" đang tuyển giọng ca 🎤 <giờ> — vào Cùng Hát xin một chỗ: cunghat://keo/shared/<token>'`. Route `/keo/shared/:token` → `SharedKeoScreen`: resolve → hiện title/giờ/khu vực/x-y chỗ/#genres/host + trạng thái (hết hạn → 'Link đã hết hạn'); nếu ĐÃ đăng nhập → nút 'Xem kèo & xin vào' push `/keo/<keo_id>`; chưa đăng nhập → nút 'Đăng nhập để xin vào' push `/auth`. `authRedirect` exempt `/keo/shared` (mirror `/plan/shared` trong router).
- Test: pgTAP (member tạo được token, non-member raise, resolve đúng + expired + bogus null); widget SharedKeoScreen 3 trạng thái; repo tests.

## T3 — Icebreaker quote trong chat (sau match)

- Vấn đề nền: sau match KHÔNG có màn xem hồ sơ đối phương (chỉ chat). Thêm: RPC `get_match_profile(p_match uuid) returns discovery_candidate` — SECURITY DEFINER, gate `app_private.in_match`, project đúng shape `discovery_candidate` hiện tại (10 cột gồm bio + prompts; shared_genres/shared_baitu tính giữa 2 người trong match; distance_band từ vị trí 2 bên, null nếu thiếu; KHÔNG raise khi target xoá mềm → trả hàng với display_name 'Người dùng đã rời'? — KHÔNG: nếu soft-deleted trả NULL row, client hiện SnackBar 'Hồ sơ không còn').
- `ChatScreen`: AppBar thêm IconButton 'Hồ sơ' (`Key('chat_profile_btn')`) → mở `CandidateDetailSheet` với candidate từ `get_match_profile` + **chế độ icebreaker**: `CandidateDetailSheet` nhận thêm `onQuote: ValueChanged<String>?` (null = ẩn, giữ nguyên hành vi deck). Khi `onQuote != null`: mỗi bài tủ chung + mỗi prompt card + mỗi trang ảnh có nút nhỏ 'Trả lời' (`Key('quote_baitu_<i>')`/`quote_prompt_<id>`/`quote_photo_<i>`) → gọi `onQuote('Về bài "<tên>" của bạn: ')` / `'Về câu "<question>" — <answer>: '` / `'Ảnh thứ <n> xịn quá! '` → đóng sheet → ChatScreen prefill text vào composer (không tự gửi — user chỉnh rồi gửi).
- Onboarding không đụng; deck không đổi hành vi (onQuote null).
- Test: pgTAP get_match_profile (member ok đủ cột, non-member raise 23514, soft-deleted null); widget: nút Hồ sơ mở sheet, tap quote bài tủ → composer chứa text, deck-mode không có nút quote.

## T4 — Teaser "Ai thích bạn" blur server-side

- **Nguyên tắc an toàn:** client free KHÔNG BAO GIỜ nhận URL ảnh gốc của liker. Blur = **pixelate server-side**: edge function tải photo0 của liker (service role) → ImageScript (Deno) resize width 16px giữ tỉ lệ → encode JPEG q60 → upload `profile-photos/<liker_uid>/teaser.jpg` (đè nếu có) → signed URL 600s. 16px phóng to = mosaic không nhận diện được. Cache: nếu `teaser.jpg` đã tồn tại và mới hơn photo0 (so metadata updated_at) thì bỏ qua bước generate.
- Edge function mới `likes-teaser` (mirror gating `sign-photo`): xác thực JWT → service client query likers của caller (logic như `who_liked_me` NHƯNG không gate entitlement, limit 6, loại soft-deleted + đã match): trả JSON list `{teaser_url|null, age, verified, shared_genre|null, liked_at}` — KHÔNG id/tên/prompt. `shared_genre` = 1 genre chung đầu tiên với caller. Không ảnh → `teaser_url null` (client hiện silhouette monogram '?').
- Flutter: `LikesTeaserScreen` (`/likes-teaser`): grid 2 cột card mờ (ảnh mosaic cover + overlay gradient + chip tuổi/tick/#genre), header 'N người đã thích bạn', CTA lớn 'Mở khoá với Pro' → `ProUpsellSheet(seeLikes)`. Hồ sơ tile 'Ai đã thích bạn': entitled → `/likes` (như cũ); KHÔNG entitled → `/likes-teaser` (thay vì mở sheet thẳng — sheet giờ là CTA bên trong màn teaser). Nếu 0 liker → EmptyState 'Chưa có ai — hoàn thiện hồ sơ để được thấy nhiều hơn' + link completion.
- Repository: `getLikesTeaser()` gọi edge qua `functions.invoke('likes-teaser')` (pattern client gọi sign-photo hiện có — đọc PhotoRepository để mirror, gồm cả `rebaseOrigin` fix host kong:8000 local).
- Test: widget teaser screen (mock repo: 2 teaser + 1 null-photo → 3 card, CTA mở sheet); repo test; edge function KHÔNG test tự động được local-headless → verify T5 bằng emulator 2 account (QA Linh đã like Minh; cần upload 1 ảnh cho QA Linh qua service-role script — pattern session photos cũ — để teaser có mosaic thật).
- pgTAP: không RPC mới (logic nằm trong edge) → không thêm; NHƯNG nếu implementer thấy cần RPC helper (vd `likers_of(uid)` app_private) thì kèm pgTAP cho nó.

## T5 — Final review + verify

- Final holistic review (chuỗi: KHÔNG đụng `get_discovery_candidates` đợt này — T3 chỉ THÊM RPC mới cùng shape; nếu composite `discovery_candidate` bị đổi ở đâu đó thì báo động).
- Gates đủ 3 + verify emulator: T1 (6 ảnh upload), T2 (share link → mở màn shared 2 trạng thái auth), T3 (2 account: match sẵn Minh↔? → tạo match với QA Linh như multiacc trước → quote bài tủ → composer prefill → gửi), T4 (QA Linh có ảnh → Minh free thấy mosaic + chip, không thấy ảnh gốc trong network log). Log `docs/verify-p2-*.md` + cleanup data test như quy trình multiacc (xoá swipes/match/messages sau VERIFY_START, giữ ảnh QA Linh).
- DỪNG báo user quyết merge.

## Ràng buộc & gotchas kế thừa

- Mọi quy tắc môi trường như đợt trước (worktree, flutter.bat, migration up không reset, pgTAP 119 baseline phải giữ xanh, adb -s, screenshot qua Bash, OTP test 84900000001 + 002 chỉ còn trong runtime).
- Edge function local base URL = kong:8000 → client đã có `rebaseOrigin` (PhotoRepository) — teaser dùng chung helper.
- KHÔNG đụng: billing/store/validate-iap; `get_discovery_candidates`; onboarding.
- Copy tiếng Việt mới phải qua l10n-hay-literal theo pattern màn tương ứng (các màn mới gần đây dùng literal VI — theo đó).

## Rủi ro

1. ImageScript trên edge runtime local (Deno) — nếu import thất bại, fallback: canvas API của Deno hoặc resize bằng `deno_image`; nếu mọi lib ảnh fail trên runtime local → hạ phương án T4 xuống "silhouette + chip" (phương án 1 cũ) và BÁO USER trước khi làm tiếp (đừng tự im lặng đổi).
2. Teaser dễ bị lạm dụng đoán người like theo tuổi+genre — chấp nhận (Tinder lộ tương đương), không trả tên/prompt.
3. `/keo/shared` cần authRedirect exempt — sai một ly là anon bị đá về /auth (test widget + route test bắt buộc).
