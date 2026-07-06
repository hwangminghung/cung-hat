# Verify multi-account (2 emulator) — Đôi: ảnh hồ sơ + carousel + boost + match + block

**Ngày:** 2026-07-04
**Branch:** `feat/pro-keo-gating`
**Phạm vi:** kiểm thử 2 chiều (two-sided) end-to-end trên 2 emulator thật, mỗi bên 1 tài khoản.
Đây là bản bổ sung cho verify 1-tài-khoản `docs/verify-doi-photos-boost-2026-07-04.md` — lần này chứng minh
đường đi signed-URL **từ một upload thật trong app** hiển thị được ở **thiết bị người khác**, và các
hành vi 2 chiều (match, boost ranking, block) trên deck live.

## Mapping tài khoản / emulator

| Vai | Emulator | Phone | UUID | Trạng thái đầu |
|-----|----------|-------|------|----------------|
| **A** | `emulator-5554` | `84900000001` (nhập `900000001`) | `0462e321-daad-4a01-b460-a95647634617` (Minh) | Đã onboard SG, deck rỗng |
| **B** | `emulator-5556` | `84900000002` (nhập `900000002`) | **`ce33ee2b-41cb-48ba-8a97-bd59d47ce184`** (Test B) | Mới → onboard trong test |

> Lưu ý đăng nhập: field số điện thoại đã prefix sẵn `+84` và `_normalize` tự thêm `+84`. Muốn khớp
> phone lưu trong `auth.users` (`84900000001`) thì phải nhập phần sau country-code, tức `900000001` →
> `+84900000001` → Supabase strip `+` → `84900000001`. Nhập nguyên `84900000001` sẽ ra `+8484900000001` (sai).

## Discovery filter (đọc từ `get_discovery_candidates`)
Không có khái niệm **gender/seeking-preference** trong schema. Filter deck = `id<>me` ∧ `soft_deleted_at is null`
∧ `ST_DWithin(radius=50km)` ∧ **không bị block (2 chiều)** ∧ **chưa swipe target**. Ranking:
`music·shared_genres + nearness + activity − report_risk + super(+5) + boost(+3.0)`.
→ Để A/B thấy nhau chỉ cần: cùng bán kính 50km (đều SG) + chưa swipe nhau + không block. Không có gate giới tính.

## Điều chỉnh discovery-setup đã thực hiện (ghi rõ)
1. **B thiếu `user_locations`** — emulator GPS `emu geo fix 106.7 10.776` **không** tới được app
   (`FlutterGeolocator` attach nhưng `getCurrentPosition` không có fix; `captureAndPush` trả false). Đây là
   **giới hạn môi trường emulator**, không phải lỗi app. → Seed thẳng vị trí B tại SG
   `POINT(106.7 10.776)` bằng SQL để đồng vị trí với A. (Đường GPS→user_locations trong app **không** được
   chứng minh; phần còn lại của matrix vẫn chạy.)
2. **Step 5 (boost):** sau khi A–B match ở Step 4, A không còn trong deck B (đã swipe) và deck A rỗng nên
   **nút boost (nằm trong header "Đôi hát") không hiển thị**. Đã: (a) xoá swipe `A→SG(a2)` để có 1 candidate
   trong deck A → header + nút boost xuất hiện; (b) xoá swipe `B→A` + match `A↔B` để A quay lại deck B cho
   phần quan sát thứ hạng boost. Các thao tác này chỉ phục vụ quan sát ranking.

## BUG phát hiện (quan trọng)

### BUG-1: signed URL ảnh trỏ host `kong` không resolve được từ client
- **Hiện tượng:** Upload ảnh trong app thành công (ghi `photo_paths` + object trong bucket), nhưng **thumbnail
  hiển thị lỗi** với: `SocketException: Failed host lookup: 'kong' (OS Error: No address associated with hostname, errno = 7)`.
- **Root cause:** edge function `sign-photo` gọi `admin.storage.from(...).createSignedUrls(...)`. Supabase JS
  client prepend `SUPABASE_URL` vào signed path. Edge runtime local nướng cứng `SUPABASE_URL=http://kong:8000`
  (Kong gateway nội bộ Docker) → URL trả về `http://kong:8000/storage/v1/object/sign/...`, emulator không
  resolve được `kong`. Đã xác nhận: `docker exec supabase_edge_runtime_cung-hat env | grep SUPABASE_URL` →
  `http://kong:8000`; gọi `sign-photo` trực tiếp trả host `kong`.
- **Phạm vi:** Đây là **giới hạn cấu hình môi trường local** (production `SUPABASE_URL` là public URL nên
  không bị). Nhưng trên setup này **mọi client** (kể cả B) nhận host `kong` → không xem được ảnh.
- **Workaround dùng khi verify (đã revert):** đúng như verify 1-account trước, tạm thêm `.map(u => u.replace(
  "http://kong:8000","http://10.0.2.2:54321"))` trong `sign-photo/index.ts` + restart edge. Token signed là
  host-independent nên rewrite host an toàn. **Đã revert sau khi verify** (`git diff` trống) + restart edge.
- **Ghi chú fix lâu dài:** cân nhắc set `SUPABASE_URL` cho edge về host client-reachable trong config local,
  hoặc rewrite host ở client, để dev-on-emulator xem được ảnh mà không phải patch tay.

## Kết quả P0 + Step 1–6

| Bước | Kết quả quan sát | Screenshot | Verdict |
|------|------------------|-----------|---------|
| **P0 onboard B + mutual visibility** | B đăng nhập OTP `900000002`/`123456` → onboarding 4 bước (ngày sinh 1/1/2000; consent location+matching+cross_border; tên "Test B"; genres Ballad+V-Pop, artist Mỹ Tâm, bài tủ Lạc Trôi) → vào deck. Seed vị trí B tại SG (xem điều chỉnh #1). RPC 2 chiều: deck B có "Minh" `<1km` `{ballad,vpop}`; deck A có "Test B" `<1km`. Live: **deck A hiện card "Test B, 26"**. | `B-onboarding-complete.png`, `P0-A-sees-B-card.png` | **PASS** |
| **Step 1 — A upload ảnh qua app** | Consent `photos` của A đã granted từ trước → **không hiện gate**. Mở "Ảnh hồ sơ" → picker Android thấy `A - Anh 1`/`A - Anh 2` → chọn 2 ô. Server: `photo_paths` = 2 path dưới UID A; `storage.objects` = 2 object `0462e321/...`. **Thumbnail trong sheet lỗi host `kong`** (BUG-1). | `A-photos-uploaded.png` (2 ô lỗi kong), `A-photos-uploaded-BUG-kong-host.png` | **PASS (upload)** / **BUG-1 (display)** |
| **Step 2 — B thấy ảnh thật của A** | Sau workaround BUG-1, restart B: **deck B card "Minh, 26" hiển thị ẢNH thật "A - Anh 1"** (không phải monogram) + 2 dots. Chứng minh trọn vẹn upload-thật → storage → `sign-photo` → render ở thiết bị B. | `B-sees-A-photos.png` | **PASS** (với workaround BUG-1) |
| **Step 3 — B vuốt carousel** | Tap card A → detail sheet 280px carousel (ảnh 1 "A - Anh 1", dot 1). Vuốt trái → **ảnh 2 "A - Anh 2"**, dot 2 active. | `B-carousel-photo2.png` | **PASS** |
| **Step 4 — match 2 chiều có ảnh** | B "Thích" A (swipe `B→A` ghi nhận). A refresh deck → card "Test B" → "Thích" B → **MatchCelebration "Hợp cạ rồi! Bạn và Test B đã thích nhau" (M ♥ T)**. `matches` row `c8a2f01d` active. | `match-celebration.png` | **PASS** |
| **Step 5 — Boost ranking (Pro)** | Cấp A entitlement `pro/promo` + restart. Nút bolt trong header → tap → **SnackBar "Đang boost 30 phút — hồ sơ của bạn được ưu tiên quanh đây."**, bolt chuyển màu primary; `boosts` row A `expires_at` +30'. Deck B (sau khi khôi phục A vào deck — điều chỉnh #2): **A ("Minh") đứng ĐẦU** trên seed SG. RPC xác nhận thứ tự Minh > SG. | `A-boost-snackbar.png`, `B-deck-boosted-A-first.png` | **PASS** |
| **Step 6 — block ẩn A** | Trên B mở "…" card A → sheet có 4 mục Báo cáo + "Chặn người này" → tap → **SnackBar "Đã chặn."**, A **rời deck ngay**. `blocks` row `B→A`. Refresh deck B → **A KHÔNG xuất hiện** dù đang boost (block override ranking). RPC xác nhận deck B chỉ còn SG. | `B-blocked-A-gone.png` | **PASS** |

**Tổng: P0 + 6/6 bước PASS.** Điểm cần lưu: Step 1 hiển thị thumbnail và Step 2/3 render ảnh chỉ chạy được
sau **workaround BUG-1** (rewrite host `kong`→`10.0.2.2`), đã revert. Đường **upload** ở Step 1 là thật, không
workaround. Đường **GPS→user_locations** của B không chứng minh được (seed SQL — giới hạn emulator).

## Không kiểm chứng được / vì sao
- **GPS→`user_locations` tự động của B:** `emu geo fix` không tới `getCurrentPosition` trên emulator này →
  seed vị trí bằng SQL. Logic app (`LocationService.captureAndPush` chạy trong `initState` của deck) không
  đổi; chỉ là fix không tới. Nên coi đây là ENV, không phải bug app.
- **Hiển thị ảnh không-workaround:** với cấu hình local (`SUPABASE_URL=kong`) thì client không xem được ảnh.
  Đây là BUG-1 (env/config), không phải lỗi UI carousel/deck (UI render đúng khi URL reachable).

## Dọn dẹp đã làm
- Revert `supabase/functions/sign-photo/index.ts` về bản commit (`git diff` trống) + restart edge runtime.
- Xoá entitlement `pro/promo` của A; xoá `boosts` row của A. (2 bảng nay trống.)
- **GIỮ LẠI:** 2 tài khoản A/B; **2 ảnh thật của A** (`photo_paths` + 2 storage object); block `B→A`;
  seed vị trí B (SG); match cũ Minh↔SG (`eeceb08f`).
- **Đã xoá trong quá trình test (không khôi phục):** swipe `B→A`, match `A↔B` (`c8a2f01d`), swipe `A→SG(a2)`
  — đều là điều chỉnh phục vụ quan sát boost/visibility (xem điều chỉnh #2). Block `B→A` hiện đã override
  cặp A–B nên việc match A↔B không còn cũng hợp lý.
- KHÔNG chạy `supabase db reset`; KHÔNG đụng `supabase/tests/chat_media_test.sql.pending`.

## Screenshot
Tất cả ở `docs/verify-screenshots-multi/`:
`B-onboarding-complete.png`, `P0-A-sees-B-card.png`, `A-photos-uploaded.png`,
`A-photos-uploaded-BUG-kong-host.png`, `B-sees-A-photos.png`, `B-carousel-photo2.png`,
`match-celebration.png`, `A-boost-snackbar.png`, `B-deck-boosted-A-first.png`, `B-blocked-A-gone.png`.
